package com.example.starxpand_flutter

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.starmicronics.stario10.InterfaceType
import com.starmicronics.stario10.StarPrinter
import com.starmicronics.stario10.StarDeviceDiscoveryManager
import com.starmicronics.stario10.StarDeviceDiscoveryManagerFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class StarxpandFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private var flutterAssets: FlutterPlugin.FlutterAssets? = null
    private var scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        flutterAssets = binding.flutterAssets
        channel = MethodChannel(binding.binaryMessenger, "starxpand_flutter/methods")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "discoverPrinters" -> {
                val arguments = call.arguments as? Map<*, *>
                if (arguments == null) {
                    result.error(
                        "invalid_arguments",
                        "discoverPrinters expects a map argument.",
                        null,
                    )
                    return
                }

                scope.launch {
                    try {
                        val printers = discoverPrinters(arguments)
                        withContext(Dispatchers.Main) {
                            result.success(printers)
                        }
                    } catch (error: StarxpandPluginException) {
                        withContext(Dispatchers.Main) {
                            result.error(error.errorCode, error.message, null)
                        }
                    } catch (error: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error(
                                "printer_error",
                                error.message ?: error.toString(),
                                null,
                            )
                        }
                    }
                }
            }

            "printReceipt" -> {
                val arguments = call.arguments as? Map<*, *>
                if (arguments == null) {
                    result.error(
                        "invalid_arguments",
                        "printReceipt expects a map argument.",
                        null,
                    )
                    return
                }

                scope.launch {
                    try {
                        printReceipt(arguments)
                        withContext(Dispatchers.Main) {
                            result.success(null)
                        }
                    } catch (error: StarxpandPluginException) {
                        withContext(Dispatchers.Main) {
                            result.error(error.errorCode, error.message, null)
                        }
                    } catch (error: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error(
                                "printer_error",
                                error.message ?: error.toString(),
                                null,
                            )
                        }
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        flutterAssets = null
        scope.cancel()
        scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    }

    private suspend fun discoverPrinters(arguments: Map<*, *>): List<Map<String, Any>> {
        val transports = StarxpandPrinterTarget.discoveryTransports(arguments)
        if (transports.isEmpty()) {
            throw StarxpandPluginException(
                errorCode = "invalid_arguments",
                message = "At least one discovery transport is required.",
            )
        }

        ensurePermissions(transports)

        val interfaceTypes = transports
            .map(::interfaceTypeForDiscovery)
            .distinct()

        if (interfaceTypes.isEmpty()) {
            throw StarxpandPluginException(
                errorCode = "invalid_arguments",
                message = "No supported discovery transports were provided.",
            )
        }

        val manager = StarDeviceDiscoveryManagerFactory.Companion.create(
            interfaceTypes,
            applicationContext,
        )

        return discoverWithManager(
            manager = manager,
            timeoutMs = intValue(arguments["timeoutMs"]) ?: 10_000,
            transports = transports,
        )
    }

    private suspend fun printReceipt(arguments: Map<*, *>) {
        val printerJson = arguments["printer"] as? Map<*, *>
            ?: throw StarxpandPluginException(
                errorCode = "invalid_arguments",
                message = "Missing printer payload.",
            )
        val planJson = arguments["printPlan"] as? Map<*, *>
            ?: throw StarxpandPluginException(
                errorCode = "invalid_arguments",
                message = "Missing printPlan payload.",
            )

        val target = StarxpandPrinterTarget.fromJson(printerJson)
        ensurePermissions(target)

        val plan = ReceiptPrintPlanDocument.fromJson(planJson)
        val context = ReceiptDocumentContext.fromJson(
            arguments["receiptDocument"] as? Map<*, *> ?: emptyMap<String, Any?>(),
        )

        val mapper = StarxpandReceiptCommandMapper(applicationContext, flutterAssets)
        val command = mapper.buildCommand(plan, context.locale)
        val printer = StarPrinter(target.makeConnectionSettings(), applicationContext)

        try {
            printer.openAsync().await()
            printer.printAsync(command).await()
        } finally {
            try {
                printer.closeAsync().await()
            } catch (_: Exception) {
                // Keep the original printing failure if close also fails.
            }
        }
    }

    private suspend fun discoverWithManager(
        manager: StarDeviceDiscoveryManager,
        timeoutMs: Int,
        transports: List<StarxpandPrinterTarget.Transport>,
    ): List<Map<String, Any>> = suspendCancellableCoroutine { continuation ->
        val results = linkedMapOf<String, StarxpandDiscoveredPrinter>()

        manager.stopDiscovery()
        manager.discoveryTime = timeoutMs.coerceAtLeast(1_000)
        manager.callback = object : StarDeviceDiscoveryManager.Callback {
            override fun onPrinterFound(printer: StarPrinter) {
                val payload = mapDiscoveredPrinter(printer, transports)
                val key = "${payload.transport.wireValue}|${payload.identifier}"
                synchronized(results) {
                    results[key] = payload
                }
            }

            override fun onDiscoveryFinished() {
                manager.stopDiscovery()
                manager.callback = null
                val payload = synchronized(results) {
                    results.values
                        .sortedBy { it.displayName ?: it.modelName ?: it.identifier }
                        .map(StarxpandDiscoveredPrinter::toMap)
                }
                continuation.resume(payload)
            }
        }

        continuation.invokeOnCancellation {
            manager.stopDiscovery()
            manager.callback = null
        }

        try {
            manager.startDiscovery()
        } catch (error: Exception) {
            manager.stopDiscovery()
            manager.callback = null
            continuation.resumeWithException(error)
        }
    }

    private fun mapDiscoveredPrinter(
        printer: StarPrinter,
        transports: List<StarxpandPrinterTarget.Transport>,
    ): StarxpandDiscoveredPrinter {
        val transport = transportForInterfaceType(
            printer.connectionSettings.interfaceType,
            transports,
        )
        val identifier = printer.connectionSettings.identifier
        val info = printer.information
        val detail = info?.detail
        val modelName = info?.model?.toString()?.takeIf { it.isNotBlank() }

        return when (transport) {
            StarxpandPrinterTarget.Transport.Network -> {
                val host = detail?.lan?.ipAddress?.takeIf { it.isNotBlank() } ?: identifier
                StarxpandDiscoveredPrinter(
                    transport = transport,
                    identifier = identifier,
                    host = host,
                    modelName = modelName,
                    displayName = modelName ?: host,
                    connectionInfo = detail?.lan?.macAddress?.takeIf { it.isNotBlank() },
                )
            }

            StarxpandPrinterTarget.Transport.BluetoothClassic,
            StarxpandPrinterTarget.Transport.BluetoothLe,
            -> {
                val connectionInfo = detail?.bluetooth?.address?.takeIf { it.isNotBlank() }
                    ?: detail?.bluetooth?.deviceName?.takeIf { it.isNotBlank() }
                StarxpandDiscoveredPrinter(
                    transport = transport,
                    identifier = identifier,
                    host = null,
                    modelName = modelName,
                    displayName = modelName ?: connectionInfo ?: identifier,
                    connectionInfo = connectionInfo,
                )
            }

            StarxpandPrinterTarget.Transport.Usb,
            StarxpandPrinterTarget.Transport.UsbC,
            -> {
                val connectionInfo = detail?.usb?.usbSerialNumber?.takeIf { it.isNotBlank() }
                    ?: detail?.usb?.portName?.takeIf { it.isNotBlank() }
                StarxpandDiscoveredPrinter(
                    transport = transport,
                    identifier = identifier,
                    host = null,
                    modelName = modelName,
                    displayName = modelName ?: detail?.usb?.portName ?: identifier,
                    connectionInfo = connectionInfo,
                )
            }

            StarxpandPrinterTarget.Transport.LightningUsb -> {
                throw StarxpandPluginException(
                    errorCode = "unsupported_transport",
                    message = "lightning_usb is only supported on iOS.",
                )
            }
        }
    }

    private fun interfaceTypeForDiscovery(
        transport: StarxpandPrinterTarget.Transport,
    ): InterfaceType {
        return when (transport) {
            StarxpandPrinterTarget.Transport.Network -> InterfaceType.Lan
            StarxpandPrinterTarget.Transport.BluetoothClassic -> InterfaceType.Bluetooth
            StarxpandPrinterTarget.Transport.BluetoothLe -> InterfaceType.BluetoothLE
            StarxpandPrinterTarget.Transport.Usb,
            StarxpandPrinterTarget.Transport.UsbC,
            -> InterfaceType.Usb
            StarxpandPrinterTarget.Transport.LightningUsb -> throw StarxpandPluginException(
                errorCode = "unsupported_transport",
                message = "lightning_usb is only supported on iOS.",
            )
        }
    }

    private fun transportForInterfaceType(
        interfaceType: InterfaceType,
        transports: List<StarxpandPrinterTarget.Transport>,
    ): StarxpandPrinterTarget.Transport {
        return when (interfaceType) {
            InterfaceType.Lan -> StarxpandPrinterTarget.Transport.Network
            InterfaceType.Bluetooth -> StarxpandPrinterTarget.Transport.BluetoothClassic
            InterfaceType.BluetoothLE -> StarxpandPrinterTarget.Transport.BluetoothLe
            InterfaceType.Usb -> when {
                transports.contains(StarxpandPrinterTarget.Transport.UsbC) ->
                    StarxpandPrinterTarget.Transport.UsbC
                transports.contains(StarxpandPrinterTarget.Transport.Usb) ->
                    StarxpandPrinterTarget.Transport.Usb
                else -> StarxpandPrinterTarget.Transport.UsbC
            }
            InterfaceType.Unknown -> StarxpandPrinterTarget.Transport.Network
        }
    }

    private fun ensurePermissions(target: StarxpandPrinterTarget) {
        ensurePermissions(listOf(target.transport))
    }

    private fun ensurePermissions(transports: List<StarxpandPrinterTarget.Transport>) {
        if (!transports.any {
                it == StarxpandPrinterTarget.Transport.BluetoothClassic ||
                    it == StarxpandPrinterTarget.Transport.BluetoothLe
            }
        ) {
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return
        }

        val granted = ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.BLUETOOTH_CONNECT,
        ) == PackageManager.PERMISSION_GRANTED

        if (!granted) {
            throw StarxpandPluginException(
                errorCode = "missing_permission",
                message = "BLUETOOTH_CONNECT permission is required for StarXpand Bluetooth printing on Android 12+.",
            )
        }
    }
}
