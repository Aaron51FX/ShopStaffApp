import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Simple roles for this P2P channel.
enum PeerRole { staff, customer }

/// Envelope for messages exchanged between peers.
class PeerMessage {
  const PeerMessage({required this.type, required this.payload, this.version = 1});

  final String type; // e.g. item_preview, options_preview, order_summary, checkout_prompt, payment_result, reset, ping
  final Map<String, dynamic> payload;
  final int version;

  Map<String, dynamic> toJson() => {
        'version': version,
        'type': type,
        'payload': payload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

  static PeerMessage? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final type = json['type'] as String?;
    final payload = (json['payload'] as Map?)?.cast<String, dynamic>();
    if (type == null || payload == null) return null;
    return PeerMessage(type: type, payload: payload, version: json['version'] as int? ?? 1);
  }
}

/// Events emitted by the platform side.
sealed class PeerEvent {
  const PeerEvent();
}

class PeerConnected extends PeerEvent {
  const PeerConnected(this.peerName);
  final String peerName;
}

class PeerDisconnected extends PeerEvent {
  const PeerDisconnected();
}

class PeerMessageEvent extends PeerEvent {
  const PeerMessageEvent(this.message);
  final PeerMessage message;
}

class PeerError extends PeerEvent {
  const PeerError(this.message);
  final String message;
}

/// High-level session wrapper.
class MultipeerSession {
  MultipeerSession._();

  static const MethodChannel _method = MethodChannel('multipeer_session/methods');
  static const EventChannel _events = EventChannel('multipeer_session/events');

  static Stream<PeerEvent>? _eventStream;

  /// Start advertising/browsing.
  static Future<void> start({required PeerRole role, String serviceName = 'shop-staff'}) async {
    await _method.invokeMethod('start', {
      'role': role.name,
      'serviceName': serviceName,
    });
  }

  /// Stop session.
  static Future<void> stop() async {
    await _method.invokeMethod('stop');
  }

  /// Send a message to connected peer.
  static Future<void> send(PeerMessage message) async {
    await _method.invokeMethod('send', {'data': jsonEncode(message.toJson())});
  }

  /// Stream of peer events (connection state, inbound messages, errors).
  static Stream<PeerEvent> events() {
    _eventStream ??= _events.receiveBroadcastStream().asyncMap((dynamic raw) {
      try {
        final map = (raw as Map).cast<String, dynamic>();
        final type = map['type'] as String?;
        switch (type) {
          case 'connected':
            return PeerConnected(map['peerName'] as String? ?? 'peer');
          case 'disconnected':
            return const PeerDisconnected();
          case 'message':
            final data = map['data'];
            final decoded = data is String ? jsonDecode(data) as Map<String, dynamic> : (data as Map).cast<String, dynamic>();
            final msg = PeerMessage.fromJson(decoded);
            if (msg == null) return const PeerError('invalid_message');
            return PeerMessageEvent(msg);
          case 'error':
            return PeerError(map['message'] as String? ?? 'unknown_error');
          default:
            return PeerError('unknown_event');
        }
      } catch (e) {
        return PeerError('parse_error: $e');
      }
    }).asBroadcastStream();
    return _eventStream!;
  }
}
