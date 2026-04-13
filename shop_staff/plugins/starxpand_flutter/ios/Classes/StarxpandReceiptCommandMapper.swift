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
      let rendered = render(columns: node.columns, paperWidthMm: paperWidthMm)
      _ = child.actionPrintText(ensureTrailingNewline(rendered))
      _ = builder.add(child)

    case .divider:
      let child = makeStyledBuilder(for: node)
      let divider = String(repeating: "-", count: printableColumns(for: paperWidthMm))
      _ = child.actionPrintText("\(divider)\n")
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
    _ = builder.styleBold(node.bold)

    let widthScale = max(1, min(node.widthScale, 6))
    let heightScale = max(1, min(node.heightScale, 6))
    if widthScale > 1 || heightScale > 1 {
      _ = builder.styleMagnification(
        StarXpandCommand.MagnificationParameter(width: widthScale, height: heightScale)
      )
    }

    return builder
  }

  private func applyLocaleDefaults(
    to builder: StarXpandCommand.PrinterBuilder,
    locale: String?
  ) {
    let normalized = (locale ?? "").lowercased()
    _ = builder.styleCharacterSpace(0)

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

  private func render(columns: [ReceiptPrintPlanColumn], paperWidthMm: Int) -> String {
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

    return zip(columns, widths).map { column, width in
      format(text: column.text, width: width, align: column.align)
    }.joined()
  }

  private func format(
    text: String,
    width: Int,
    align: ReceiptPrintPlanNode.Align
  ) -> String {
    let normalized = text.replacingOccurrences(of: "\n", with: " ")
    let truncated = normalized.count > width ? String(normalized.prefix(width)) : normalized
    let padding = max(0, width - truncated.count)

    switch align {
    case .left:
      return truncated + String(repeating: " ", count: padding)
    case .center:
      let leading = padding / 2
      let trailing = padding - leading
      return String(repeating: " ", count: leading) + truncated + String(repeating: " ", count: trailing)
    case .right:
      return String(repeating: " ", count: padding) + truncated
    }
  }

  private func printableColumns(for paperWidthMm: Int) -> Int {
    max(24, Int(round(Double(paperWidthMm) / 1.5)))
  }

  private func pixelWidth(for paperWidthMm: Int) -> Int {
    let dots = Int(round(Double(paperWidthMm) / 25.4 * 203.0))
    return max(200, min(dots, 832))
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

  private func ensureTrailingNewline(_ text: String) -> String {
    text.hasSuffix("\n") ? text : "\(text)\n"
  }
}
