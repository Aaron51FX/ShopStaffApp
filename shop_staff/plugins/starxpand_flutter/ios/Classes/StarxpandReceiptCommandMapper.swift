import Flutter
import Foundation
import StarIO10
import UIKit

final class StarxpandReceiptCommandMapper {
  typealias AssetLookupKeyResolver = (String) -> String

  private let assetLookupKeyResolver: AssetLookupKeyResolver?

  init(assetLookupKeyResolver: AssetLookupKeyResolver?) {
    self.assetLookupKeyResolver = assetLookupKeyResolver
  }

  func buildCommand(
    from plan: ReceiptPrintPlanDocument,
    locale: String?
  ) throws -> String {
    let rootBuilder = StarXpandCommand.StarXpandCommandBuilder()
    let documentBuilder = StarXpandCommand.DocumentBuilder()
    let printerBuilder = StarXpandCommand.PrinterBuilder()

    applyLocaleDefaults(to: printerBuilder, locale: locale)

    for node in plan.nodes {
      try append(node: node, to: printerBuilder, paperWidthMm: plan.paperWidthMm)
    }

    _ = documentBuilder.addPrinter(printerBuilder)
    _ = rootBuilder.addDocument(documentBuilder)
    return rootBuilder.getCommands()
  }

  private func append(
    node: ReceiptPrintPlanNode,
    to builder: StarXpandCommand.PrinterBuilder,
    paperWidthMm: Int
  ) throws {
    switch node.type {
    case .text:
      guard let text = node.text, !text.isEmpty else { return }
      let child = makeStyledBuilder(for: node)
      _ = child.actionPrintText(ensureTrailingNewline(text))
      _ = builder.add(child)

    case .row:
      guard !node.columns.isEmpty else { return }
      let child = makeStyledBuilder(for: node)
      appendRow(columns: node.columns, to: child, paperWidthMm: paperWidthMm)
      _ = builder.add(child)

    case .divider:
      let child = makeStyledBuilder(for: node)
      _ = child.actionPrintRuledLine(
        StarXpandCommand.Printer.RuledLineParameter(width: Double(paperWidthMm))
          .setLineStyle(.single)
          .setThickness(0.2)
      )
      _ = child.actionFeedLine(1)
      _ = builder.add(child)

    case .spacer:
      let child = makeStyledBuilder(for: node)
      _ = child.actionFeedLine(max(1, node.spacerLines ?? 1))
      _ = builder.add(child)

    case .cut:
      let child = makeStyledBuilder(for: node)
      _ = child.actionCut(node.partialCut ? .partial : .full)
      _ = builder.add(child)

    case .qrCode:
      guard let qrData = node.qrData, !qrData.isEmpty else { return }
      let child = makeStyledBuilder(for: node)
      let parameter = StarXpandCommand.Printer.QRCodeParameter(content: qrData)
        .setLevel(.m)
        .setCellSize(8)
      _ = child.actionPrintQRCode(parameter)
      _ = builder.add(child)

    case .image:
      let image = try resolveImage(node: node)
      let width = pixelWidth(for: paperWidthMm)
      let child = makeStyledBuilder(for: node)
      let parameter = StarXpandCommand.Printer.ImageParameter(image: image, width: width)
      _ = child.actionPrintImage(parameter)
      _ = builder.add(child)
    }
  }

  private func makeStyledBuilder(for node: ReceiptPrintPlanNode) -> StarXpandCommand.PrinterBuilder {
    let builder = StarXpandCommand.PrinterBuilder()
    _ = builder.styleAlignment(mapAlignment(node.align))
    _ = builder.styleFont(.a)
    _ = builder.styleBold(node.bold)

    let widthScale = max(1, min(node.widthScale, 6))
    let heightScale = max(1, min(node.heightScale, 6))
    _ = builder.styleMagnification(
      StarXpandCommand.MagnificationParameter(width: widthScale, height: heightScale)
    )

    return builder
  }

  private func applyLocaleDefaults(
    to builder: StarXpandCommand.PrinterBuilder,
    locale: String?
  ) {
    let normalized = (locale ?? "").lowercased()
    _ = builder.styleCharacterSpace(0)
    _ = builder.styleFont(.a)
    _ = builder.styleMagnification(
      StarXpandCommand.MagnificationParameter(width: 1, height: 1)
    )

    switch normalized {
    case let value where value.hasPrefix("ja"):
      _ = builder.styleCJKCharacterPriority([.japanese])
      _ = builder.styleInternationalCharacter(.japan)
    case let value where value.hasPrefix("zh-cn") || value.hasPrefix("zh_hans") || value == "zh":
      _ = builder.styleCJKCharacterPriority([.simplifiedChinese, .japanese])
      _ = builder.styleSecondPriorityCharacterEncoding(.simplifiedChinese)
      _ = builder.styleInternationalCharacter(.usa)
    case let value where value.hasPrefix("zh"):
      _ = builder.styleCJKCharacterPriority([.traditionalChinese, .japanese])
      _ = builder.styleSecondPriorityCharacterEncoding(.traditionalChinese)
      _ = builder.styleInternationalCharacter(.usa)
    default:
      _ = builder.styleInternationalCharacter(.usa)
    }
  }

  private func resolveImage(node: ReceiptPrintPlanNode) throws -> UIImage {
    if let base64 = node.imageBase64,
       let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
       let image = UIImage(data: data) {
      return image
    }

    if let assetKey = node.imageAssetKey,
       let image = loadImageFromFlutterAsset(assetKey: assetKey) {
      return image
    }

    if let assetKey = node.imageAssetKey {
      throw StarxpandPluginError.missingAsset("Unable to load image asset: \(assetKey)")
    }

    throw StarxpandPluginError.invalidPlan("Image node is missing image data.")
  }

  private func loadImageFromFlutterAsset(assetKey: String) -> UIImage? {
    let resolvedKey = assetLookupKeyResolver?(assetKey) ?? assetKey
    let candidatePaths = [
      resolvedKey,
      "Frameworks/App.framework/flutter_assets/\(assetKey)",
      "flutter_assets/\(assetKey)",
      assetKey
    ]

    for candidate in candidatePaths {
      if let image = UIImage(named: candidate, in: Bundle.main, compatibleWith: nil) {
        return image
      }

      if let path = Bundle.main.path(forResource: candidate, ofType: nil),
         let image = UIImage(contentsOfFile: path) {
        return image
      }
    }

    if let flutterAssetsURL = Bundle.main.privateFrameworksURL?
      .appendingPathComponent("App.framework")
      .appendingPathComponent("flutter_assets")
      .appendingPathComponent(assetKey),
       let image = UIImage(contentsOfFile: flutterAssetsURL.path) {
      return image
    }

    return nil
  }

  private func appendRow(
    columns: [ReceiptPrintPlanColumn],
    to builder: StarXpandCommand.PrinterBuilder,
    paperWidthMm: Int
  ) {
    let widths = rowColumnWidths(columns: columns, paperWidthMm: paperWidthMm)
    let wrappedColumns = zip(columns, widths).map { column, width in
      wrapColumnText(column.text.replacingOccurrences(of: "\n", with: " "), width: width)
    }
    let lineCount = wrappedColumns.map(\.count).max() ?? 1

    for lineIndex in 0..<lineCount {
      for (columnIndex, pair) in zip(columns, widths).enumerated() {
        let (column, width) = pair
        let text = lineIndex < wrappedColumns[columnIndex].count ? wrappedColumns[columnIndex][lineIndex] : ""
        _ = builder.styleBold(column.bold)
        _ = builder.actionPrintText(
          text,
          textParameter(width: width, align: column.align)
        )
      }
      _ = builder.actionPrintText("\n")
    }
    _ = builder.styleBold(false)
  }

  private func rowColumnWidths(columns: [ReceiptPrintPlanColumn], paperWidthMm: Int) -> [Int] {
    let totalFlex = max(1, columns.reduce(0) { $0 + max(1, $1.flex) })
    let totalColumns = printableColumns(for: paperWidthMm)
    var widths: [Int] = []
    var allocated = 0

    for index in columns.indices {
      if index == columns.indices.last {
        widths.append(max(1, totalColumns - allocated))
      } else {
        let width = max(1, Int(round(Double(totalColumns * columns[index].flex) / Double(totalFlex))))
        widths.append(width)
        allocated += width
      }
    }

    return widths
  }

  private func textParameter(
    width: Int,
    align: ReceiptPrintPlanNode.Align
  ) -> StarXpandCommand.Printer.TextParameter {
    let widthParameter = StarXpandCommand.Printer.TextWidthParameter()
      .setWidthType(.half)
      .setAlignment(mapTextAlignment(align))
      .setEllipsizeType(.none)
      .setPrintType(.always)
    return StarXpandCommand.Printer.TextParameter().setWidth(width, widthParameter)
  }

  private func wrapColumnText(_ text: String, width: Int) -> [String] {
    let safeWidth = max(1, width)
    guard !text.isEmpty else {
      return [""]
    }

    var lines: [String] = []
    var current = ""
    var currentWidth = 0

    for character in text {
      let characterWidth = printColumnWidth(character)
      if !current.isEmpty && currentWidth + characterWidth > safeWidth {
        lines.append(current)
        current = ""
        currentWidth = 0
      }
      current.append(character)
      currentWidth += characterWidth
    }

    if !current.isEmpty {
      lines.append(current)
    }
    return lines.isEmpty ? [""] : lines
  }

  private func printColumnWidth(_ character: Character) -> Int {
    if character.unicodeScalars.allSatisfy({ $0.properties.generalCategory == .nonspacingMark }) {
      return 0
    }
    if character.unicodeScalars.contains(where: { isDoubleWidth($0.value) }) {
      return 2
    }
    return 1
  }

  private func isDoubleWidth(_ scalar: UInt32) -> Bool {
    switch scalar {
    case 0x1100...0x11FF,
         0x2E80...0xA4CF,
         0xAC00...0xD7AF,
         0xF900...0xFAFF,
         0xFE10...0xFE6F,
         0xFF00...0xFF60,
         0x1F300...0x1FAFF:
      return true
    default:
      return false
    }
  }

  private func printableColumns(for paperWidthMm: Int) -> Int {
    switch paperWidthMm {
    case 58:
      return 32
    case 80:
      return 48
    default:
      return 48
    }
  }

  private func pixelWidth(for paperWidthMm: Int) -> Int {
    switch paperWidthMm {
    case 58:
      return 320
    case 80:
      return 480
    default:
      return 480
    }
  }

  private func mapAlignment(_ align: ReceiptPrintPlanNode.Align) -> StarXpandCommand.Printer.Alignment {
    switch align {
    case .left:
      return .left
    case .center:
      return .center
    case .right:
      return .right
    }
  }

  private func mapTextAlignment(_ align: ReceiptPrintPlanNode.Align) -> StarXpandCommand.Printer.TextAlignment {
    switch align {
    case .left:
      return .left
    case .center:
      return .center
    case .right:
      return .right
    }
  }

  private func ensureTrailingNewline(_ text: String) -> String {
    text.hasSuffix("\n") ? text : "\(text)\n"
  }
}
