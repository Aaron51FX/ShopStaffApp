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
