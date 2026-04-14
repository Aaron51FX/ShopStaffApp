import Foundation
import StarIO10

enum StarxpandPluginError: LocalizedError {
  case invalidArguments(String)
  case invalidPrinter(String)
  case invalidPlan(String)
  case missingAsset(String)
  case unsupportedTransport(String)
  case missingPermission(String)
  case printerError(String)

  var errorDescription: String? {
    switch self {
    case .invalidArguments(let message),
        .invalidPrinter(let message),
        .invalidPlan(let message),
        .missingAsset(let message),
        .unsupportedTransport(let message),
        .missingPermission(let message),
        .printerError(let message):
      return message
    }
  }

  var code: String {
    switch self {
    case .invalidArguments:
      return "invalid_arguments"
    case .invalidPrinter:
      return "invalid_printer"
    case .invalidPlan:
      return "invalid_plan"
    case .missingAsset:
      return "missing_asset"
    case .unsupportedTransport:
      return "unsupported_transport"
    case .missingPermission:
      return "missing_permission"
    case .printerError:
      return "printer_error"
    }
  }
}

struct StarxpandPrinterTarget {
  enum Transport: String {
    case network = "network"
    case bluetoothClassic = "bluetooth_classic"
    case bluetoothLe = "bluetooth_le"
    case usb = "usb"
    case usbC = "usb_c"
    case lightningUsb = "lightning_usb"
  }

  static func discoveryTransports(json: [String: Any]) -> [Transport] {
    let rawValues = json["transports"] as? [String] ?? []
    if rawValues.isEmpty {
      return [
        .network,
        .bluetoothClassic,
        .bluetoothLe,
        .lightningUsb
      ]
    }

    return rawValues.compactMap(Transport.init(rawValue:))
  }

  let transport: Transport
  let identifier: String?
  let host: String?
  let port: Int?
  let modelName: String?
  let autoSwitchInterface: Bool

  init(json: [String: Any]) throws {
    guard let rawTransport = json["transport"] as? String,
          let transport = Transport(rawValue: rawTransport)
    else {
      throw StarxpandPluginError.invalidPrinter("Missing or invalid printer transport.")
    }

    self.transport = transport
    self.identifier = (json["identifier"] as? String)?.nilIfEmpty
    self.host = (json["host"] as? String)?.nilIfEmpty
    self.port = json["port"] as? Int
    self.modelName = (json["modelName"] as? String)?.nilIfEmpty
    self.autoSwitchInterface = (json["autoSwitchInterface"] as? Bool) ?? false
  }

  var interfaceType: InterfaceType {
    switch transport {
    case .network:
      return .lan
    case .bluetoothClassic:
      return .bluetooth
    case .bluetoothLe:
      return .bluetoothLE
    case .usb, .usbC, .lightningUsb:
      return .usb
    }
  }

  var resolvedIdentifier: String {
    switch transport {
    case .network:
      return host ?? identifier ?? ""
    case .bluetoothClassic, .bluetoothLe, .usb, .usbC, .lightningUsb:
      return identifier ?? host ?? ""
    }
  }

  func makeConnectionSettings() throws -> StarConnectionSettings {
    let resolved = resolvedIdentifier
    if resolved.isEmpty {
      throw StarxpandPluginError.invalidPrinter(
        "Printer identifier is required for \(transport.rawValue)."
      )
    }

    if transport == .network, let port, port != 9100 {
      // StarIO10 LAN uses the printer identifier only. Keep the host and ignore
      // custom ports for now rather than fabricating an unsupported identifier.
      NSLog("starxpand_flutter: ignoring unsupported custom LAN port \(port)")
    }

    return StarConnectionSettings(
      interfaceType: interfaceType,
      identifier: resolved,
      autoSwitchInterface: autoSwitchInterface
    )
  }
}

struct StarxpandDiscoveredPrinter {
  let transport: StarxpandPrinterTarget.Transport
  let identifier: String
  let host: String?
  let modelName: String?
  let displayName: String?
  let connectionInfo: String?

  var dictionary: [String: Any] {
    var payload: [String: Any] = [
      "transport": transport.rawValue,
      "identifier": identifier
    ]
    if let host, !host.isEmpty {
      payload["host"] = host
    }
    if let modelName, !modelName.isEmpty {
      payload["modelName"] = modelName
    }
    if let displayName, !displayName.isEmpty {
      payload["displayName"] = displayName
    }
    if let connectionInfo, !connectionInfo.isEmpty {
      payload["connectionInfo"] = connectionInfo
    }
    return payload
  }
}

struct StarxpandDrawerStatusPayload {
  let hasError: Bool
  let coverOpen: Bool
  let drawerOpenCloseSignal: Bool
  let paperEmpty: Bool
  let paperNearEmpty: Bool

  init(status: StarPrinterStatus) {
    self.hasError = status.hasError
    self.coverOpen = status.coverOpen
    self.drawerOpenCloseSignal = status.drawerOpenCloseSignal
    self.paperEmpty = status.paperEmpty
    self.paperNearEmpty = status.paperNearEmpty
  }

  var dictionary: [String: Any] {
    [
      "hasError": hasError,
      "coverOpen": coverOpen,
      "drawerOpenCloseSignal": drawerOpenCloseSignal,
      "paperEmpty": paperEmpty,
      "paperNearEmpty": paperNearEmpty
    ]
  }
}

struct StarxpandDrawerOpenRequest {
  enum Channel: String {
    case no1
    case no2

    var starChannel: StarXpandCommand.Drawer.Channel {
      switch self {
      case .no1:
        return .no1
      case .no2:
        return .no2
      }
    }
  }

  let channel: Channel
  let onTimeMs: Int

  init(json: [String: Any]) {
    self.channel = Channel(rawValue: (json["channel"] as? String) ?? "no1") ?? .no1
    self.onTimeMs = max(50, json["onTimeMs"] as? Int ?? 200)
  }
}

struct ReceiptPrintPlanDocument {
  let paperWidthMm: Int
  let nodes: [ReceiptPrintPlanNode]

  init(json: [String: Any]) throws {
    self.paperWidthMm = json["paperWidthMm"] as? Int ?? 72

    let rawNodes = json["nodes"] as? [[String: Any]] ?? []
    self.nodes = try rawNodes.map(ReceiptPrintPlanNode.init(json:))
  }
}

struct ReceiptPrintPlanNode {
  enum NodeType: String {
    case image
    case text
    case row
    case divider
    case spacer
    case cut
    case qrCode = "qr_code"
  }

  enum Align: String {
    case left
    case center
    case right
  }

  let type: NodeType
  let text: String?
  let columns: [ReceiptPrintPlanColumn]
  let align: Align
  let bold: Bool
  let widthScale: Int
  let heightScale: Int
  let imageAssetKey: String?
  let imageBase64: String?
  let qrData: String?
  let spacerLines: Int?
  let partialCut: Bool

  init(json: [String: Any]) throws {
    guard let rawType = json["type"] as? String,
          let type = NodeType(rawValue: rawType)
    else {
      throw StarxpandPluginError.invalidPlan("Unknown plan node type.")
    }

    self.type = type
    self.text = (json["text"] as? String)?.nilIfEmpty
    let rawColumns = json["columns"] as? [[String: Any]] ?? []
    self.columns = rawColumns.map(ReceiptPrintPlanColumn.init(json:))
    self.align = Align(rawValue: (json["align"] as? String) ?? "left") ?? .left
    self.bold = (json["bold"] as? Bool) ?? false
    self.widthScale = json["widthScale"] as? Int ?? 1
    self.heightScale = json["heightScale"] as? Int ?? 1
    self.imageAssetKey = (json["imageAssetKey"] as? String)?.nilIfEmpty
    self.imageBase64 = (json["imageBase64"] as? String)?.nilIfEmpty
    self.qrData = (json["qrData"] as? String)?.nilIfEmpty
    self.spacerLines = json["spacerLines"] as? Int
    self.partialCut = (json["partialCut"] as? Bool) ?? true
  }
}

struct ReceiptPrintPlanColumn {
  let text: String
  let align: ReceiptPrintPlanNode.Align
  let flex: Int
  let bold: Bool

  init(json: [String: Any]) {
    self.text = (json["text"] as? String) ?? ""
    self.align = ReceiptPrintPlanNode.Align(rawValue: (json["align"] as? String) ?? "left") ?? .left
    self.flex = max(1, json["flex"] as? Int ?? 1)
    self.bold = (json["bold"] as? Bool) ?? false
  }
}

struct ReceiptDocumentContext {
  let locale: String?

  init(json: [String: Any]) {
    if let transaction = json["transaction"] as? [String: Any] {
      self.locale = (transaction["locale"] as? String)?.nilIfEmpty
    } else {
      self.locale = nil
    }
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
