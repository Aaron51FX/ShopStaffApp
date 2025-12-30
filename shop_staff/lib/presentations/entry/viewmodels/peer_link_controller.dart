import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multipeer_session/multipeer_session.dart';

enum PeerLinkStatus { idle, searching, connected, error }

class PeerLinkState {
  const PeerLinkState({
    this.status = PeerLinkStatus.idle,
    this.peerName,
    this.lastError,
    this.lastMessage,
    this.messageSeq = 0,
  });

  final PeerLinkStatus status;
  final String? peerName;
  final String? lastError;
  final PeerMessage? lastMessage;
  final int messageSeq;

  bool get isConnected => status == PeerLinkStatus.connected;
  bool get isSearching => status == PeerLinkStatus.searching;
  bool get hasMessage => lastMessage != null;

  PeerLinkState copyWith({
    PeerLinkStatus? status,
    String? peerName,
    String? lastError,
    PeerMessage? lastMessage,
    int? messageSeq,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return PeerLinkState(
      status: status ?? this.status,
      peerName: peerName ?? this.peerName,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastMessage: clearMessage ? null : (lastMessage ?? this.lastMessage),
      messageSeq: messageSeq ?? this.messageSeq,
    );
  }
}

class PeerLinkController extends StateNotifier<PeerLinkState> {
  PeerLinkController({
    required this.role,
    this.serviceName = 'shop-staff',
  }) : super(const PeerLinkState());

  final PeerRole role;
  final String serviceName;

  StreamSubscription<PeerEvent>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    state = state.copyWith(status: PeerLinkStatus.searching, clearError: true);
    _sub = MultipeerSession.events().listen(_onEvent);
    await MultipeerSession.start(role: role, serviceName: serviceName);
  }

  Future<void> restart() async {
    await stop();
    _started = false;
    await start();
  }

  Future<void> stop() async {
    await MultipeerSession.stop();
    await _sub?.cancel();
    _sub = null;
    state = state.copyWith(status: PeerLinkStatus.idle, peerName: null);
  }

  void _onEvent(PeerEvent event) {
    if (event is PeerConnected) {
      state = state.copyWith(
        status: PeerLinkStatus.connected,
        peerName: event.peerName,
        clearError: true,
      );
    } else if (event is PeerDisconnected) {
      state = state.copyWith(
        status: PeerLinkStatus.searching,
        peerName: null,
      );
    } else if (event is PeerError) {
      debugPrint('Peer error: ${event.message}');
      state = state.copyWith(
        status: PeerLinkStatus.error,
        lastError: event.message,
      );
    } else if (event is PeerMessageEvent) {
      final msg = event.message;
      if (msg.type == 'reset_display') {
        state = state.copyWith(clearMessage: true, messageSeq: state.messageSeq + 1);
        return;
      }
      state = state.copyWith(
        status: PeerLinkStatus.connected,
        lastMessage: msg,
        messageSeq: state.messageSeq + 1,
        clearError: true,
      );
    }
  }

  Future<void> sendMessage(PeerMessage message) async {
    if (!state.isConnected) return;
    await MultipeerSession.send(message);
  }

  void clearLocalMessage() {
    state = state.copyWith(clearMessage: true, messageSeq: state.messageSeq + 1);
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}

final peerLinkControllerProvider =
    StateNotifierProvider<PeerLinkController, PeerLinkState>((ref) {
  return PeerLinkController(role: PeerRole.staff, serviceName: 'shop-staff');
});

final customerPeerLinkControllerProvider =
    StateNotifierProvider<PeerLinkController, PeerLinkState>((ref) {
  return PeerLinkController(role: PeerRole.customer, serviceName: 'shop-staff');
});
