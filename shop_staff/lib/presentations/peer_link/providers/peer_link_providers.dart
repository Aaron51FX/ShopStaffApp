import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multipeer_session/multipeer_session.dart';

import '../controllers/peer_link_controller.dart';
import '../state/peer_link_state.dart';

final peerLinkControllerProvider =
    StateNotifierProvider<PeerLinkController, PeerLinkState>((ref) {
      return PeerLinkController(
        role: PeerRole.staff,
        serviceName: 'shop-staff',
      );
    });

final customerPeerLinkControllerProvider =
    StateNotifierProvider<PeerLinkController, PeerLinkState>((ref) {
      return PeerLinkController(
        role: PeerRole.customer,
        serviceName: 'shop-staff',
      );
    });
