import Flutter
import UIKit
import StarIO10

public class StarxpandFlutterPlugin: NSObject, FlutterPlugin {
  private var assetLookupKeyResolver: ((String) -> String)?

  init(assetLookupKeyResolver: ((String) -> String)? = nil) {
    self.assetLookupKeyResolver = assetLookupKeyResolver
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "starxpand_flutter/methods",
      binaryMessenger: registrar.messenger()
    )
    let instance = StarxpandFlutterPlugin(
      assetLookupKeyResolver: { registrar.lookupKey(forAsset: $0) }
    )
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "discoverPrinters":
      guard let arguments = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "discoverPrinters expects a map argument.",
            details: nil
          )
        )
        return
      }

      Task {
        do {
          let printers = try await discoverPrinters(arguments: arguments)
          DispatchQueue.main.async {
            result(printers)
          }
        } catch let error as StarxpandPluginError {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: error.code,
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "printer_error",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }

    case "printReceipt":
      guard let arguments = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "printReceipt expects a map argument.",
            details: nil
          )
        )
        return
      }

      Task {
        do {
          try await printReceipt(arguments: arguments)
          DispatchQueue.main.async {
            result(nil)
          }
        } catch let error as StarxpandPluginError {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: error.code,
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "printer_error",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }

    case "getDrawerStatus":
      guard let arguments = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "getDrawerStatus expects a map argument.",
            details: nil
          )
        )
        return
      }

      Task {
        do {
          let status = try await getDrawerStatus(arguments: arguments)
          DispatchQueue.main.async {
            result(status)
          }
        } catch let error as StarxpandPluginError {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: error.code,
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "printer_error",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }

    case "openDrawer":
      guard let arguments = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "openDrawer expects a map argument.",
            details: nil
          )
        )
        return
      }

      Task {
        do {
          try await openDrawer(arguments: arguments)
          DispatchQueue.main.async {
            result(nil)
          }
        } catch let error as StarxpandPluginError {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: error.code,
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "printer_error",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @MainActor
  private func discoverPrinters(arguments: [String: Any]) async throws -> [[String: Any]] {
    let transports = StarxpandPrinterTarget.discoveryTransports(json: arguments)
    if transports.isEmpty {
      throw StarxpandPluginError.invalidArguments(
        "At least one discovery transport is required."
      )
    }

    let interfaceTypes = orderedDiscoveryInterfaceTypes(for: transports)
    if interfaceTypes.isEmpty {
      throw StarxpandPluginError.invalidArguments(
        "No supported discovery transports were provided."
      )
    }

    let timeoutMs = arguments["timeoutMs"] as? Int ?? 10_000

    do {
      return try await runDiscovery(
        interfaceTypes: interfaceTypes,
        transports: transports,
        timeoutMs: timeoutMs
      )
    } catch {
      return try await runDiscoveryFallback(
        transports: transports,
        timeoutMs: timeoutMs,
        initialError: error
      )
    }
  }

  private func printReceipt(arguments: [String: Any]) async throws {
    guard let printerJSON = arguments["printer"] as? [String: Any] else {
      throw StarxpandPluginError.invalidArguments("Missing printer payload.")
    }
    guard let planJSON = arguments["printPlan"] as? [String: Any] else {
      throw StarxpandPluginError.invalidArguments("Missing printPlan payload.")
    }

    let target = try StarxpandPrinterTarget(json: printerJSON)
    let plan = try ReceiptPrintPlanDocument(json: planJSON)
    let context = ReceiptDocumentContext(
      json: arguments["receiptDocument"] as? [String: Any] ?? [:]
    )

    let mapper = StarxpandReceiptCommandMapper(
      assetLookupKeyResolver: assetLookupKeyResolver
    )
    let command = try mapper.buildCommand(from: plan, locale: context.locale)
    let printer = StarPrinter(try target.makeConnectionSettings())

    try await printer.open()
    defer {
      Task {
        await printer.close()
      }
    }

    try await printer.print(command: command)
  }

  private func getDrawerStatus(arguments: [String: Any]) async throws -> [String: Any] {
    guard let printerJSON = arguments["printer"] as? [String: Any] else {
      throw StarxpandPluginError.invalidArguments("Missing printer payload.")
    }

    let target = try StarxpandPrinterTarget(json: printerJSON)
    let printer = StarPrinter(try target.makeConnectionSettings())

    try await printer.open()
    defer {
      Task {
        await printer.close()
      }
    }

    let status = try await printer.getStatus()
    return StarxpandDrawerStatusPayload(status: status).dictionary
  }

  private func openDrawer(arguments: [String: Any]) async throws {
    guard let printerJSON = arguments["printer"] as? [String: Any] else {
      throw StarxpandPluginError.invalidArguments("Missing printer payload.")
    }

    let target = try StarxpandPrinterTarget(json: printerJSON)
    let request = StarxpandDrawerOpenRequest(json: arguments)
    let printer = StarPrinter(try target.makeConnectionSettings())

    let parameter = StarXpandCommand.Drawer.OpenParameter()
      .setChannel(request.channel.starChannel)
      .setOnTime(request.onTimeMs)

    let builder = StarXpandCommand.StarXpandCommandBuilder()
    let documentBuilder = StarXpandCommand.DocumentBuilder()
    let drawerBuilder = StarXpandCommand.DrawerBuilder().actionOpen(parameter)
    _ = documentBuilder.addDrawer(drawerBuilder)
    _ = builder.addDocument(documentBuilder)

    try await printer.open()
    defer {
      Task {
        await printer.close()
      }
    }

    try await printer.print(command: builder.getCommands())
  }

  private func orderedDiscoveryInterfaceTypes(
    for transports: [StarxpandPrinterTarget.Transport]
  ) -> [InterfaceType] {
    var interfaceTypes: [InterfaceType] = []
    for transport in transports {
      let interfaceType: InterfaceType?
      switch transport {
      case .network:
        interfaceType = .lan
      case .bluetoothClassic:
        interfaceType = .bluetooth
      case .bluetoothLe:
        interfaceType = .bluetoothLE
      case .usb, .usbC, .lightningUsb:
        interfaceType = .usb
      }

      if let interfaceType, !interfaceTypes.contains(interfaceType) {
        interfaceTypes.append(interfaceType)
      }
    }

    return interfaceTypes
  }

  @MainActor
  private func runDiscovery(
    interfaceTypes: [InterfaceType],
    transports: [StarxpandPrinterTarget.Transport],
    timeoutMs: Int
  ) async throws -> [[String: Any]] {
    let manager = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: interfaceTypes)
    let usbTransport = resolvedUSBTransport(for: transports)
    let session = StarxpandDiscoverySession(manager: manager, usbTransport: usbTransport)
    return try await session.start(timeoutMs: timeoutMs)
  }

  @MainActor
  private func runDiscoveryFallback(
    transports: [StarxpandPrinterTarget.Transport],
    timeoutMs: Int,
    initialError: Error
  ) async throws -> [[String: Any]] {
    var merged: [String: [String: Any]] = [:]
    var lastError: Error = initialError
    var hasSuccessfulTransport = false

    for transport in transports {
      let interfaceTypes = orderedDiscoveryInterfaceTypes(for: [transport])
      guard !interfaceTypes.isEmpty else {
        continue
      }

      do {
        let partial = try await runDiscovery(
          interfaceTypes: interfaceTypes,
          transports: [transport],
          timeoutMs: timeoutMs
        )
        hasSuccessfulTransport = true

        for payload in partial {
          guard let transport = payload["transport"] as? String,
                let identifier = payload["identifier"] as? String
          else {
            continue
          }
          merged["\(transport)|\(identifier)"] = payload
        }
      } catch {
        lastError = error
        NSLog(
          "starxpand_flutter: discovery skipped unavailable transport \(transport.rawValue): \(error.localizedDescription)"
        )
      }
    }

    if hasSuccessfulTransport {
      return merged.values.sorted { lhs, rhs in
        let left = (lhs["displayName"] as? String) ??
          (lhs["modelName"] as? String) ??
          (lhs["identifier"] as? String) ?? ""
        let right = (rhs["displayName"] as? String) ??
          (rhs["modelName"] as? String) ??
          (rhs["identifier"] as? String) ?? ""
        return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
      }
    }

    throw lastError
  }

  private func resolvedUSBTransport(
    for transports: [StarxpandPrinterTarget.Transport]
  ) -> StarxpandPrinterTarget.Transport {
    if transports.contains(.lightningUsb) {
      return .lightningUsb
    }
    if transports.contains(.usbC) {
      return .usbC
    }
    return .usb
  }
}
