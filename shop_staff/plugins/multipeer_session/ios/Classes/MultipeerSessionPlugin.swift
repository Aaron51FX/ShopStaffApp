import Flutter
import UIKit
import MultipeerConnectivity

public class MultipeerSessionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var methodChannel: FlutterMethodChannel?
  private var eventSink: FlutterEventSink?

  // Multipeer state
  private var peerID: MCPeerID?
  private var session: MCSession?
  private var advertiser: MCNearbyServiceAdvertiser?
  private var browser: MCNearbyServiceBrowser?
  private var role: String = "unknown"
  private var serviceName: String = "multipeer-session"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MultipeerSessionPlugin()
    instance.methodChannel = FlutterMethodChannel(name: "multipeer_session/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)
    let eventChannel = FlutterEventChannel(name: "multipeer_session/events", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
  }

  // MARK: - MethodChannel
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      guard let args = call.arguments as? [String: Any],
            let role = args["role"] as? String,
            let serviceName = args["serviceName"] as? String else {
        result(FlutterError(code: "bad_args", message: "Missing role/serviceName", details: nil))
        return
      }
      self.role = role
      self.serviceName = String(serviceName.prefix(15)).lowercased()
      startSession()
      result(nil)
    case "stop":
      stopSession()
      result(nil)
    case "send":
      guard let args = call.arguments as? [String: Any],
            let dataStr = args["data"] as? String,
            let data = dataStr.data(using: .utf8),
            let session = session else {
        result(FlutterError(code: "send_fail", message: "No session or data", details: nil))
        return
      }
      do {
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        result(nil)
      } catch {
        result(FlutterError(code: "send_fail", message: error.localizedDescription, details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - EventChannel
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  // MARK: - Multipeer Helpers
  private func startSession() {
    stopSession()
    let peer = MCPeerID(displayName: UIDevice.current.name)
    peerID = peer
    let session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
    session.delegate = self
    self.session = session

    let info = ["role": role]
    let advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: info, serviceType: serviceName)
    advertiser.delegate = self
    advertiser.startAdvertisingPeer()
    self.advertiser = advertiser

    let browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceName)
    browser.delegate = self
    browser.startBrowsingForPeers()
    self.browser = browser
  }

  private func stopSession() {
    advertiser?.stopAdvertisingPeer()
    browser?.stopBrowsingForPeers()
    advertiser = nil
    browser = nil
    session?.disconnect()
    session?.delegate = nil
    session = nil
    peerID = nil
  }

  private func emit(_ map: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(map)
    }
  }
}

// MARK: - MCSessionDelegate
extension MultipeerSessionPlugin: MCSessionDelegate {
  public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    switch state {
    case .connected:
      emit(["type": "connected", "peerName": peerID.displayName])
    case .notConnected:
      emit(["type": "disconnected", "peerName": peerID.displayName])
    case .connecting:
      break
    @unknown default:
      break
    }
  }

  public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    guard let str = String(data: data, encoding: .utf8) else { return }
    emit(["type": "message", "data": str, "peerName": peerID.displayName])
  }

  public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
  public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
  public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
  public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
    certificateHandler(true)
  }
}

// MARK: - Advertiser & Browser Delegates
extension MultipeerSessionPlugin: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
  public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    invitationHandler(true, session)
  }

  public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    emit(["type": "error", "message": "adv_error: \(error.localizedDescription)"])
  }

  public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
    guard let session = session else { return }
    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
  }

  public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

  public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
    emit(["type": "error", "message": "browse_error: \(error.localizedDescription)"])
  }
}
