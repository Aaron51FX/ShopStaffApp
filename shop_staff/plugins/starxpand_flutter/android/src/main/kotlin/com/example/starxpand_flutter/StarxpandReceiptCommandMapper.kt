package com.example.starxpand_flutter

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import com.starmicronics.stario10.starxpandcommand.DocumentBuilder
import com.starmicronics.stario10.starxpandcommand.MagnificationParameter
import com.starmicronics.stario10.starxpandcommand.PrinterBuilder
import com.starmicronics.stario10.starxpandcommand.StarXpandCommandBuilder
import com.starmicronics.stario10.starxpandcommand.printer.Alignment
import com.starmicronics.stario10.starxpandcommand.printer.CharacterEncodingType
import com.starmicronics.stario10.starxpandcommand.printer.CjkCharacterType
import com.starmicronics.stario10.starxpandcommand.printer.CutType
import com.starmicronics.stario10.starxpandcommand.printer.ImageParameter
import com.starmicronics.stario10.starxpandcommand.printer.InternationalCharacterType
import com.starmicronics.stario10.starxpandcommand.printer.QRCodeLevel
import com.starmicronics.stario10.starxpandcommand.printer.QRCodeParameter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.IOException
import kotlin.math.roundToInt

internal class StarxpandReceiptCommandMapper(
    private val context: Context,
    private val flutterAssets: FlutterPlugin.FlutterAssets?,
) {
    fun buildCommand(plan: ReceiptPrintPlanDocument, locale: String?): String {
        val rootBuilder = StarXpandCommandBuilder()
        val documentBuilder = DocumentBuilder()
        val printerBuilder = PrinterBuilder()

        applyLocaleDefaults(printerBuilder, locale)

        plan.nodes.forEach { node ->
            append(node, printerBuilder, plan.paperWidthMm)
        }

        documentBuilder.addPrinter(printerBuilder)
        rootBuilder.addDocument(documentBuilder)
        return rootBuilder.getCommands()
    }

    private fun append(
        node: ReceiptPrintPlanNode,
        builder: PrinterBuilder,
        paperWidthMm: Int,
    ) {
        when (node.type) {
            ReceiptPrintPlanNode.NodeType.Text -> {
                val text = node.text ?: return
                if (text.isEmpty()) return
                val child = makeStyledBuilder(node)
                child.actionPrintText(ensureTrailingNewline(text))
                builder.add(child)
            }

            ReceiptPrintPlanNode.NodeType.Row -> {
                if (node.columns.isEmpty()) return
                val child = makeStyledBuilder(node)
                val rendered = render(node.columns, paperWidthMm)
                child.actionPrintText(ensureTrailingNewline(rendered))
                builder.add(child)
            }

            ReceiptPrintPlanNode.NodeType.Divider -> {
                val child = makeStyledBuilder(node)
                val divider = "-".repeat(printableColumns(paperWidthMm))
                child.actionPrintText("$divider\n")
                builder.add(child)
            }

            ReceiptPrintPlanNode.NodeType.Spacer -> {
                val child = makeStyledBuilder(node)
                child.actionFeedLine((node.spacerLines ?: 1).coerceAtLeast(1))
                builder.add(child)
            }

            ReceiptPrintPlanNode.NodeType.Cut -> {
                val child = makeStyledBuilder(node)
                child.actionCut(if (node.partialCut) CutType.Partial else CutType.Full)
                builder.add(child)
            }

            ReceiptPrintPlanNode.NodeType.QrCode -> {
                val qrData = node.qrData ?: return
                if (qrData.isEmpty()) return
                val child = makeStyledBuilder(node)
                val parameter = QRCodeParameter(qrData)
                    .setLevel(QRCodeLevel.M)
                    .setCellSize(8)
                child.actionPrintQRCode(parameter)
                builder.add(child)
            }

            ReceiptPrintPlanNode.NodeType.Image -> {
                val bitmap = resolveBitmap(node)
                val child = makeStyledBuilder(node)
                child.actionPrintImage(ImageParameter(bitmap, pixelWidth(paperWidthMm)))
                builder.add(child)
            }
        }
    }

    private fun makeStyledBuilder(node: ReceiptPrintPlanNode): PrinterBuilder {
        val builder = PrinterBuilder()
        builder.styleAlignment(mapAlignment(node.align))
        builder.styleBold(node.bold)

        val widthScale = node.widthScale.coerceIn(1, 6)
        val heightScale = node.heightScale.coerceIn(1, 6)
        if (widthScale > 1 || heightScale > 1) {
            builder.styleMagnification(MagnificationParameter(widthScale, heightScale))
        }

        return builder
    }

    private fun applyLocaleDefaults(
        builder: PrinterBuilder,
        locale: String?,
    ) {
        val normalized = locale.orEmpty().lowercase()
        builder.styleCharacterSpace(0.0)

        when {
            normalized.startsWith("ja") -> {
                builder.styleCjkCharacterPriority(listOf(CjkCharacterType.Japanese))
                builder.styleInternationalCharacter(InternationalCharacterType.Japan)
            }

            normalized.startsWith("zh-cn") || normalized.startsWith("zh_hans") || normalized == "zh" -> {
                builder.styleCjkCharacterPriority(
                    listOf(
                        CjkCharacterType.SimplifiedChinese,
                        CjkCharacterType.Japanese,
                    ),
                )
                builder.styleSecondPriorityCharacterEncoding(CharacterEncodingType.SimplifiedChinese)
                builder.styleInternationalCharacter(InternationalCharacterType.Usa)
            }

            normalized.startsWith("zh") -> {
                builder.styleCjkCharacterPriority(
                    listOf(
                        CjkCharacterType.TraditionalChinese,
                        CjkCharacterType.Japanese,
                    ),
                )
                builder.styleSecondPriorityCharacterEncoding(CharacterEncodingType.TraditionalChinese)
                builder.styleInternationalCharacter(InternationalCharacterType.Usa)
            }

            else -> {
                builder.styleInternationalCharacter(InternationalCharacterType.Usa)
            }
        }
    }

    private fun resolveBitmap(node: ReceiptPrintPlanNode): Bitmap {
        node.imageBase64?.let { base64 ->
            val image = decodeBase64Bitmap(base64)
            if (image != null) {
                return image
            }
        }

        node.imageAssetKey?.let { assetKey ->
            loadBitmapFromFlutterAsset(assetKey)?.let { return it }
            throw StarxpandPluginException(
                errorCode = "missing_asset",
                message = "Unable to load image asset: $assetKey",
            )
        }

        throw StarxpandPluginException(
            errorCode = "invalid_plan",
            message = "Image node is missing image data.",
        )
    }

    private fun decodeBase64Bitmap(base64: String): Bitmap? {
        return try {
            val data = Base64.decode(base64, Base64.DEFAULT)
            BitmapFactory.decodeByteArray(data, 0, data.size)
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private fun loadBitmapFromFlutterAsset(assetKey: String): Bitmap? {
        val candidates = linkedSetOf<String>()
        flutterAssets?.getAssetFilePathByName(assetKey)?.let(candidates::add)
        candidates.add("flutter_assets/$assetKey")
        candidates.add(assetKey)

        for (candidate in candidates) {
            try {
                context.assets.open(candidate).use { stream ->
                    BitmapFactory.decodeStream(stream)?.let { return it }
                }
            } catch (_: IOException) {
                // Try the next candidate path.
            }
        }

        return null
    }

    private fun render(
        columns: List<ReceiptPrintPlanColumn>,
        paperWidthMm: Int,
    ): String {
        val totalFlex = columns.sumOf { it.flex.coerceAtLeast(1) }.coerceAtLeast(1)
        val totalColumns = printableColumns(paperWidthMm)
        val widths = mutableListOf<Int>()
        var allocated = 0

        columns.forEachIndexed { index, column ->
            if (index == columns.lastIndex) {
                widths += (totalColumns - allocated).coerceAtLeast(1)
            } else {
                val width = ((totalColumns * column.flex.coerceAtLeast(1)).toDouble() / totalFlex)
                    .roundToInt()
                    .coerceAtLeast(1)
                widths += width
                allocated += width
            }
        }

        return columns.zip(widths).joinToString(separator = "") { (column, width) ->
            format(column.text, width, column.align)
        }
    }

    private fun format(
        text: String,
        width: Int,
        align: ReceiptPrintPlanNode.Align,
    ): String {
        val normalized = text.replace("\n", " ")
        val truncated = if (normalized.length > width) {
            normalized.take(width)
        } else {
            normalized
        }
        val padding = (width - truncated.length).coerceAtLeast(0)

        return when (align) {
            ReceiptPrintPlanNode.Align.Left -> truncated + " ".repeat(padding)
            ReceiptPrintPlanNode.Align.Center -> {
                val leading = padding / 2
                val trailing = padding - leading
                " ".repeat(leading) + truncated + " ".repeat(trailing)
            }
            ReceiptPrintPlanNode.Align.Right -> " ".repeat(padding) + truncated
        }
    }

    private fun printableColumns(paperWidthMm: Int): Int {
        return (paperWidthMm.toDouble() / 1.5).roundToInt().coerceAtLeast(24)
    }

    private fun pixelWidth(paperWidthMm: Int): Int {
        val dots = (paperWidthMm / 25.4 * 203.0).roundToInt()
        return dots.coerceIn(200, 832)
    }

    private fun mapAlignment(align: ReceiptPrintPlanNode.Align): Alignment {
        return when (align) {
            ReceiptPrintPlanNode.Align.Left -> Alignment.Left
            ReceiptPrintPlanNode.Align.Center -> Alignment.Center
            ReceiptPrintPlanNode.Align.Right -> Alignment.Right
        }
    }

    private fun ensureTrailingNewline(text: String): String {
        return if (text.endsWith('\n')) text else "$text\n"
    }
}
