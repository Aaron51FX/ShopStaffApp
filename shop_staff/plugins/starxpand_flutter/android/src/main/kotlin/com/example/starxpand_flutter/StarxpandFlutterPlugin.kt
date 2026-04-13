package com.example.starxpand_flutter

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.starmicronics.stario10.StarPrinter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

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

    private fun ensurePermissions(target: StarxpandPrinterTarget) {
        if (!target.requiresBluetoothPermission()) {
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
