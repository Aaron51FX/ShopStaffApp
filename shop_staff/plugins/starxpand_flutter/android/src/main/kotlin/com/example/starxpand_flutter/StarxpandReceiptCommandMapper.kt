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
import com.starmicronics.stario10.starxpandcommand.printer.FontType
import com.starmicronics.stario10.starxpandcommand.printer.ImageParameter
import com.starmicronics.stario10.starxpandcommand.printer.InternationalCharacterType
import com.starmicronics.stario10.starxpandcommand.printer.LineStyle
import com.starmicronics.stario10.starxpandcommand.printer.QRCodeLevel
import com.starmicronics.stario10.starxpandcommand.printer.QRCodeParameter
import com.starmicronics.stario10.starxpandcommand.printer.RuledLineParameter
import com.starmicronics.stario10.starxpandcommand.printer.TextAlignment
import com.starmicronics.stario10.starxpandcommand.printer.TextEllipsizeType
import com.starmicronics.stario10.starxpandcommand.printer.TextParameter
import com.starmicronics.stario10.starxpandcommand.printer.TextPrintType
import com.starmicronics.stario10.starxpandcommand.printer.TextWidthParameter
import com.starmicronics.stario10.starxpandcommand.printer.TextWidthType
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
                appendRow(node.columns, child, paperWidthMm)
                builder.add(child)
            }

            ReceiptPrintPlanNode.NodeType.Divider -> {
                val child = makeStyledBuilder(node)
                child.actionPrintRuledLine(
                    RuledLineParameter(paperWidthMm.toDouble())
                        .setLineStyle(LineStyle.Single)
                        .setThickness(0.2),
                )
                child.actionFeedLine(1)
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
        builder.styleFont(FontType.A)
        builder.styleBold(node.bold)

        val widthScale = node.widthScale.coerceIn(1, 6)
        val heightScale = node.heightScale.coerceIn(1, 6)
        builder.styleMagnification(MagnificationParameter(widthScale, heightScale))

        return builder
    }

    private fun applyLocaleDefaults(
        builder: PrinterBuilder,
        locale: String?,
    ) {
        val normalized = locale.orEmpty().lowercase()
        builder.styleCharacterSpace(0.0)
        builder.styleFont(FontType.A)
        builder.styleMagnification(MagnificationParameter(1, 1))

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

    private fun appendRow(
        columns: List<ReceiptPrintPlanColumn>,
        builder: PrinterBuilder,
        paperWidthMm: Int,
    ) {
        val widths = rowColumnWidths(columns, paperWidthMm)
        val wrappedColumns = columns.zip(widths).map { (column, width) ->
            wrapColumnText(column.text.replace("\n", " "), width)
        }
        val lineCount = wrappedColumns.maxOfOrNull { it.size } ?: 1

        repeat(lineCount) { lineIndex ->
            columns.zip(widths).forEachIndexed { columnIndex, (column, width) ->
                builder.styleBold(column.bold)
                builder.actionPrintText(
                    wrappedColumns[columnIndex].getOrElse(lineIndex) { "" },
                    textParameter(width, column.align),
                )
            }
            builder.actionPrintText("\n")
        }
        builder.styleBold(false)
    }

    private fun rowColumnWidths(
        columns: List<ReceiptPrintPlanColumn>,
        paperWidthMm: Int,
    ): List<Int> {
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

        return widths
    }

    private fun textParameter(
        width: Int,
        align: ReceiptPrintPlanNode.Align,
    ): TextParameter {
        val widthParameter = TextWidthParameter()
            .setWidthType(TextWidthType.Half)
            .setAlignment(mapTextAlignment(align))
            .setEllipsizeType(TextEllipsizeType.None)
            .setPrintType(TextPrintType.Always)
        return TextParameter().setWidth(width, widthParameter)
    }

    private fun wrapColumnText(text: String, width: Int): List<String> {
        val safeWidth = width.coerceAtLeast(1)
        if (text.isEmpty()) return listOf("")

        val lines = mutableListOf<String>()
        val current = StringBuilder()
        var currentWidth = 0
        var index = 0

        while (index < text.length) {
            val codePoint = text.codePointAt(index)
            val charWidth = printColumnWidth(codePoint)
            if (current.isNotEmpty() && currentWidth + charWidth > safeWidth) {
                lines += current.toString()
                current.clear()
                currentWidth = 0
            }
            current.appendCodePoint(codePoint)
            currentWidth += charWidth
            index += Character.charCount(codePoint)
        }

        if (current.isNotEmpty()) {
            lines += current.toString()
        }
        return if (lines.isEmpty()) listOf("") else lines
    }

    private fun printColumnWidth(codePoint: Int): Int {
        if (Character.getType(codePoint) == Character.NON_SPACING_MARK.toInt()) return 0
        return when {
            codePoint <= 0x007F -> 1
            codePoint in 0xFF61..0xFF9F -> 1
            codePoint in 0x1100..0x11FF -> 2
            codePoint in 0x2E80..0xA4CF -> 2
            codePoint in 0xAC00..0xD7AF -> 2
            codePoint in 0xF900..0xFAFF -> 2
            codePoint in 0xFE10..0xFE6F -> 2
            codePoint in 0xFF00..0xFF60 -> 2
            codePoint in 0x1F300..0x1FAFF -> 2
            else -> 1
        }
    }

    private fun printableColumns(paperWidthMm: Int): Int {
        return when (paperWidthMm) {
            58 -> 32
            80 -> 48
            else -> 48
        }
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

    private fun mapTextAlignment(align: ReceiptPrintPlanNode.Align): TextAlignment {
        return when (align) {
            ReceiptPrintPlanNode.Align.Left -> TextAlignment.Left
            ReceiptPrintPlanNode.Align.Center -> TextAlignment.Center
            ReceiptPrintPlanNode.Align.Right -> TextAlignment.Right
        }
    }

    private fun ensureTrailingNewline(text: String): String {
        return if (text.endsWith('\n')) text else "$text\n"
    }
}
