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

    default:
      result(FlutterMethodNotImplemented)
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
}
