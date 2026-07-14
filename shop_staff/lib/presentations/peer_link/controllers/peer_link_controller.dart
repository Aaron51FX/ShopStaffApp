import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multipeer_session/multipeer_session.dart';
import 'package:permission_handler/permission_handler.dart';

import '../state/peer_link_state.dart';

class PeerLinkController extends StateNotifier<PeerLinkState> {
  PeerLinkController({required this.role, this.serviceName = 'shop-staff'})
    : super(const PeerLinkState());

  final PeerRole role;
  final String serviceName;

  StreamSubscription<PeerEvent>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    state = state.copyWith(status: PeerLinkStatus.searching, clearError: true);
    _sub = MultipeerSession.events().listen(_onEvent);

    final ok = await _ensureAndroidPermissions();
    if (!ok) {
      state = state.copyWith(status: PeerLinkStatus.error);
      _started = false;
      return;
    }

    await MultipeerSession.start(role: role, serviceName: serviceName);
  }

  Future<bool> _ensureAndroidPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      final permissionsToRequest = <Permission>{
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      };

      if (sdkInt >= 33) {
        permissionsToRequest.add(Permission.nearbyWifiDevices);
        permissionsToRequest.add(Permission.locationWhenInUse);
      } else {
        permissionsToRequest.add(Permission.locationWhenInUse);
      }

      final results = await permissionsToRequest.toList().request();

      final required = <Permission>{
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        if (sdkInt >= 33) Permission.nearbyWifiDevices,
        Permission.locationWhenInUse,
      };

      final denied = <Permission>[];
      for (final permission in required) {
        final status = results[permission] ?? await permission.status;
        if (!status.isGranted) denied.add(permission);
      }

      if (denied.isNotEmpty) {
        state = state.copyWith(
          status: PeerLinkStatus.error,
          lastError: '需要授予权限: ${denied.map((e) => e.toString()).join(', ')}',
        );
        return false;
      }

      return true;
    } catch (error) {
      state = state.copyWith(
        status: PeerLinkStatus.error,
        lastError: '权限检查失败: $error',
      );
      return false;
    }
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
      state = state.copyWith(status: PeerLinkStatus.searching, peerName: null);
    } else if (event is PeerError) {
      debugPrint('Peer error: ${event.message}');
      state = state.copyWith(
        status: PeerLinkStatus.error,
        lastError: event.message,
      );
    } else if (event is PeerMessageEvent) {
      final msg = event.message;
      if (msg.type == 'reset_display') {
        state = state.copyWith(
          clearMessage: true,
          messageSeq: state.messageSeq + 1,
        );
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
    state = state.copyWith(
      clearMessage: true,
      messageSeq: state.messageSeq + 1,
    );
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}
