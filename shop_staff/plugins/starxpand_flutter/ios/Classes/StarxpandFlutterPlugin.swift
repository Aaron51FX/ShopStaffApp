import Flutter
import UIKit

public class StarxpandFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "starxpand_flutter/methods",
      binaryMessenger: registrar.messenger()
    )
    let instance = StarxpandFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "printReceipt":
      result(
        FlutterError(
          code: "unimplemented",
          message: "StarXpand iOS native mapping is not implemented yet.",
          details: nil
        )
      )
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
