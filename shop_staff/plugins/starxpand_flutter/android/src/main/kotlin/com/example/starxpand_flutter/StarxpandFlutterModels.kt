package com.example.starxpand_flutter

import android.util.Log
import com.starmicronics.stario10.InterfaceType
import com.starmicronics.stario10.StarConnectionSettings

internal class StarxpandPluginException(
    val errorCode: String,
    override val message: String,
) : IllegalArgumentException(message)

internal data class StarxpandPrinterTarget(
    val transport: Transport,
    val identifier: String?,
    val host: String?,
    val port: Int?,
    val modelName: String?,
    val autoSwitchInterface: Boolean,
) {
    enum class Transport(val wireValue: String) {
        Network("network"),
        BluetoothClassic("bluetooth_classic"),
        BluetoothLe("bluetooth_le"),
        Usb("usb"),
        UsbC("usb_c"),
        LightningUsb("lightning_usb"),
        ;

        companion object {
            fun fromWireValue(raw: String?): Transport? {
                return entries.firstOrNull { it.wireValue == raw }
            }
        }
    }

    val interfaceType: InterfaceType
        get() = when (transport) {
            Transport.Network -> InterfaceType.Lan
            Transport.BluetoothClassic -> InterfaceType.Bluetooth
            Transport.BluetoothLe -> InterfaceType.BluetoothLE
            Transport.Usb,
            Transport.UsbC,
            -> InterfaceType.Usb
            Transport.LightningUsb -> throw StarxpandPluginException(
                errorCode = "unsupported_transport",
                message = "lightning_usb is only supported on iOS.",
            )
        }

    val resolvedIdentifier: String
        get() = when (transport) {
            Transport.Network -> host ?: identifier ?: ""
            Transport.BluetoothClassic,
            Transport.BluetoothLe,
            Transport.Usb,
            Transport.UsbC,
            Transport.LightningUsb,
            -> identifier ?: host ?: ""
        }

    fun makeConnectionSettings(): StarConnectionSettings {
        val resolved = resolvedIdentifier
        if (resolved.isBlank()) {
            throw StarxpandPluginException(
                errorCode = "invalid_printer",
                message = "Printer identifier is required for ${transport.wireValue}.",
            )
        }

        if (transport == Transport.Network && port != null && port != 9100) {
            Log.d(
                "starxpand_flutter",
                "Ignoring unsupported custom LAN port $port for StarIO10 printer connection.",
            )
        }

        return StarConnectionSettings(interfaceType, resolved, autoSwitchInterface)
    }

    fun requiresBluetoothPermission(): Boolean {
        return transport == Transport.BluetoothClassic || transport == Transport.BluetoothLe
    }

    companion object {
        fun discoveryTransports(json: Map<*, *>): List<Transport> {
            val rawValues = json["transports"] as? List<*> ?: emptyList<Any?>()
            if (rawValues.isEmpty()) {
                return listOf(
                    Transport.Network,
                    Transport.BluetoothClassic,
                    Transport.BluetoothLe,
                    Transport.Usb,
                )
            }

            return rawValues.mapNotNull { raw ->
                Transport.fromWireValue(raw as? String)
            }
        }

        fun fromJson(json: Map<*, *>): StarxpandPrinterTarget {
            val transport = Transport.fromWireValue(json["transport"] as? String)
                ?: throw StarxpandPluginException(
                    errorCode = "invalid_printer",
                    message = "Missing or invalid printer transport.",
                )

            return StarxpandPrinterTarget(
                transport = transport,
                identifier = (json["identifier"] as? String)?.nilIfBlank(),
                host = (json["host"] as? String)?.nilIfBlank(),
                port = intValue(json["port"]),
                modelName = (json["modelName"] as? String)?.nilIfBlank(),
                autoSwitchInterface = boolValue(json["autoSwitchInterface"]) ?: false,
            )
        }
    }
}

internal data class StarxpandDiscoveredPrinter(
    val transport: StarxpandPrinterTarget.Transport,
    val identifier: String,
    val host: String?,
    val modelName: String?,
    val displayName: String?,
    val connectionInfo: String?,
) {
    fun toMap(): Map<String, Any> {
        return buildMap {
            put("transport", transport.wireValue)
            put("identifier", identifier)
            host?.takeIf { it.isNotBlank() }?.let { put("host", it) }
            modelName?.takeIf { it.isNotBlank() }?.let { put("modelName", it) }
            displayName?.takeIf { it.isNotBlank() }?.let { put("displayName", it) }
            connectionInfo?.takeIf { it.isNotBlank() }?.let { put("connectionInfo", it) }
        }
    }
}

internal data class ReceiptPrintPlanDocument(
    val paperWidthMm: Int,
    val nodes: List<ReceiptPrintPlanNode>,
) {
    companion object {
        fun fromJson(json: Map<*, *>): ReceiptPrintPlanDocument {
            val rawNodes = json["nodes"] as? List<*> ?: emptyList<Any?>()
            val nodes = rawNodes.mapNotNull { raw ->
                (raw as? Map<*, *>)?.let(ReceiptPrintPlanNode::fromJson)
            }

            return ReceiptPrintPlanDocument(
                paperWidthMm = intValue(json["paperWidthMm"]) ?: 72,
                nodes = nodes,
            )
        }
    }
}

internal data class ReceiptPrintPlanNode(
    val type: NodeType,
    val text: String?,
    val columns: List<ReceiptPrintPlanColumn>,
    val align: Align,
    val bold: Boolean,
    val widthScale: Int,
    val heightScale: Int,
    val imageAssetKey: String?,
    val imageBase64: String?,
    val qrData: String?,
    val spacerLines: Int?,
    val partialCut: Boolean,
) {
    enum class NodeType(val wireValue: String) {
        Image("image"),
        Text("text"),
        Row("row"),
        Divider("divider"),
        Spacer("spacer"),
        Cut("cut"),
        QrCode("qr_code"),
        ;

        companion object {
            fun fromWireValue(raw: String?): NodeType? {
                return entries.firstOrNull { it.wireValue == raw }
            }
        }
    }

    enum class Align(val wireValue: String) {
        Left("left"),
        Center("center"),
        Right("right"),
        ;

        companion object {
            fun fromWireValue(raw: String?): Align {
                return entries.firstOrNull { it.wireValue == raw } ?: Left
            }
        }
    }

    companion object {
        fun fromJson(json: Map<*, *>): ReceiptPrintPlanNode {
            val type = NodeType.fromWireValue(json["type"] as? String)
                ?: throw StarxpandPluginException(
                    errorCode = "invalid_plan",
                    message = "Unknown plan node type.",
                )

            val rawColumns = json["columns"] as? List<*> ?: emptyList<Any?>()
            val columns = rawColumns.mapNotNull { raw ->
                (raw as? Map<*, *>)?.let(ReceiptPrintPlanColumn::fromJson)
            }

            return ReceiptPrintPlanNode(
                type = type,
                text = (json["text"] as? String)?.nilIfBlank(),
                columns = columns,
                align = Align.fromWireValue(json["align"] as? String),
                bold = boolValue(json["bold"]) ?: false,
                widthScale = intValue(json["widthScale"]) ?: 1,
                heightScale = intValue(json["heightScale"]) ?: 1,
                imageAssetKey = (json["imageAssetKey"] as? String)?.nilIfBlank(),
                imageBase64 = (json["imageBase64"] as? String)?.nilIfBlank(),
                qrData = (json["qrData"] as? String)?.nilIfBlank(),
                spacerLines = intValue(json["spacerLines"]),
                partialCut = boolValue(json["partialCut"]) ?: true,
            )
        }
    }
}

internal data class ReceiptPrintPlanColumn(
    val text: String,
    val align: ReceiptPrintPlanNode.Align,
    val flex: Int,
    val bold: Boolean,
) {
    companion object {
        fun fromJson(json: Map<*, *>): ReceiptPrintPlanColumn {
            return ReceiptPrintPlanColumn(
                text = (json["text"] as? String) ?: "",
                align = ReceiptPrintPlanNode.Align.fromWireValue(json["align"] as? String),
                flex = (intValue(json["flex"]) ?: 1).coerceAtLeast(1),
                bold = boolValue(json["bold"]) ?: false,
            )
        }
    }
}

internal data class ReceiptDocumentContext(
    val locale: String?,
) {
    companion object {
        fun fromJson(json: Map<*, *>): ReceiptDocumentContext {
            val transaction = json["transaction"] as? Map<*, *>
            return ReceiptDocumentContext(
                locale = (transaction?.get("locale") as? String)?.nilIfBlank(),
            )
        }
    }
}

internal fun intValue(value: Any?): Int? {
    return when (value) {
        is Int -> value
        is Long -> value.toInt()
        is Double -> value.toInt()
        is Float -> value.toInt()
        is Number -> value.toInt()
        is String -> value.trim().toIntOrNull()
        else -> null
    }
}

internal fun boolValue(value: Any?): Boolean? {
    return when (value) {
        is Boolean -> value
        is String -> when (value.trim().lowercase()) {
            "true" -> true
            "false" -> false
            else -> null
        }
        else -> null
    }
}

private fun String.nilIfBlank(): String? {
    return if (isBlank()) null else this
}
