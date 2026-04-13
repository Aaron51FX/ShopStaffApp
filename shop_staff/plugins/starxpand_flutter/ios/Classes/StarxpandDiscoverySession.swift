import Foundation
import StarIO10

@MainActor
final class StarxpandDiscoverySession: NSObject, StarDeviceDiscoveryManagerDelegate {
  private let manager: any StarDeviceDiscoveryManager
  private var continuation: CheckedContinuation<[[String: Any]], Error>?
  private var results: [String: StarxpandDiscoveredPrinter] = [:]
  private let usbTransport: StarxpandPrinterTarget.Transport

  init(
    manager: any StarDeviceDiscoveryManager,
    usbTransport: StarxpandPrinterTarget.Transport = .lightningUsb
  ) {
    self.manager = manager
    self.usbTransport = usbTransport
  }

  func start(timeoutMs: Int) async throws -> [[String: Any]] {
    manager.stopDiscovery()
    manager.discoveryTime = max(1_000, timeoutMs)
    manager.delegate = self

    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
      do {
        try manager.startDiscovery()
      } catch {
        self.continuation = nil
        continuation.resume(throwing: error)
      }
    }
  }

  nonisolated func manager(_ manager: any StarDeviceDiscoveryManager, didFind printer: StarPrinter) {
    Task { @MainActor in
      let payload = map(printer: printer)
      let key = "\(payload.transport.rawValue)|\(payload.identifier)"
      results[key] = payload
    }
  }

  nonisolated func managerDidFinishDiscovery(_ manager: any StarDeviceDiscoveryManager) {
    Task { @MainActor in
      finishIfNeeded()
    }
  }

  private func finishIfNeeded() {
    guard let continuation else {
      return
    }

    manager.stopDiscovery()
    manager.delegate = nil
    self.continuation = nil

    let payload = results.values
      .sorted { lhs, rhs in
        let left = lhs.displayName ?? lhs.modelName ?? lhs.identifier
        let right = rhs.displayName ?? rhs.modelName ?? rhs.identifier
        return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
      }
      .map(\.dictionary)

    continuation.resume(returning: payload)
  }

  private func map(printer: StarPrinter) -> StarxpandDiscoveredPrinter {
    let transport = mapTransport(printer.connectionSettings.interfaceType)
    let identifier = printer.connectionSettings.identifier
    let info = printer.information
    let modelName = info.map { String(describing: $0.model) }.nilIfEmpty

    switch transport {
    case .network:
      let host = info?.detail.lan.ipAddress?.nilIfEmpty ?? identifier.nilIfEmpty
      return StarxpandDiscoveredPrinter(
        transport: transport,
        identifier: identifier,
        host: host,
        modelName: modelName,
        displayName: modelName ?? host ?? identifier,
        connectionInfo: info?.detail.lan.macAddress?.nilIfEmpty
      )

    case .bluetoothClassic:
      let connectionInfo =
        info?.detail.bluetooth.address?.nilIfEmpty ??
        info?.detail.bluetooth.serialNumber?.nilIfEmpty
      return StarxpandDiscoveredPrinter(
        transport: transport,
        identifier: identifier,
        host: nil,
        modelName: modelName,
        displayName: modelName ?? connectionInfo ?? identifier,
        connectionInfo: connectionInfo
      )

    case .bluetoothLe:
      let connectionInfo = info?.detail.bluetoothLE.address?.nilIfEmpty
      return StarxpandDiscoveredPrinter(
        transport: transport,
        identifier: identifier,
        host: nil,
        modelName: modelName,
        displayName: modelName ?? connectionInfo ?? identifier,
        connectionInfo: connectionInfo
      )

    case .usb, .usbC, .lightningUsb:
      let connectionInfo =
        info?.detail.usb.usbSerialNumber?.nilIfEmpty ??
        info?.detail.usb.productSerialNumber?.nilIfEmpty ??
        info?.detail.usb.portName?.nilIfEmpty
      return StarxpandDiscoveredPrinter(
        transport: transport,
        identifier: identifier,
        host: nil,
        modelName: modelName,
        displayName: modelName ?? info?.detail.usb.portName?.nilIfEmpty ?? identifier,
        connectionInfo: connectionInfo
      )
    }
  }

  private func mapTransport(_ interfaceType: InterfaceType) -> StarxpandPrinterTarget.Transport {
    switch interfaceType {
    case .lan:
      return .network
    case .bluetooth:
      return .bluetoothClassic
    case .bluetoothLE:
      return .bluetoothLe
    case .usb:
      return usbTransport
    @unknown default:
      return .network
    }
  }
}

private extension Optional where Wrapped == String {
  var nilIfEmpty: String? {
    switch self {
    case .none:
      return nil
    case .some(let value):
      return value.isEmpty ? nil : value
    }
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
