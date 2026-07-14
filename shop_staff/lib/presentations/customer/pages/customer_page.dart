import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multipeer_session/multipeer_session.dart';

import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../peer_link/peer_link.dart';
import '../dialogs/customer_peer_link_dialogs.dart';
import '../sections/home/customer_home_section.dart';
import '../sections/message/customer_message_overlay.dart';

class CustomerPage extends ConsumerStatefulWidget {
  const CustomerPage({super.key});

  @override
  ConsumerState<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends ConsumerState<CustomerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(customerPeerLinkControllerProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    ref.read(customerPeerLinkControllerProvider.notifier).stop();
    super.dispose();
  }

  Future<void> _showDisconnectedDialog() async {
    if (!mounted) return;
    final shouldReconnect = await showCustomerPeerDisconnectedDialog(
      context: context,
    );
    if (shouldReconnect && mounted) {
      await _showSearchDialog();
    }
  }

  Future<void> _showSearchDialog() {
    return showCustomerPeerSearchDialog(context: context, ref: ref);
  }

  Future<void> _selectPayment(Map<String, dynamic> option) async {
    final controller = ref.read(customerPeerLinkControllerProvider.notifier);
    controller.clearLocalMessage();
    await controller.sendMessage(
      PeerMessage(
        type: 'payment_choice',
        payload: {
          'group': option['group'],
          'code': option['code'],
          'label': option['label'],
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PeerLinkState>(customerPeerLinkControllerProvider, (prev, next) {
      final wasConnected = prev?.isConnected ?? false;
      if (wasConnected && !next.isConnected) {
        _showDisconnectedDialog();
      }
    });

    final role = ref.watch(appRoleProvider);
    final linkState = ref.watch(customerPeerLinkControllerProvider);
    final router = ref.read(appRouterProvider);

    return Stack(
      children: [
        CustomerHomeSection(
          role: role,
          linkState: linkState,
          onConnectionPressed: _showSearchDialog,
          onSettingsPressed: () => router.push('/settings'),
        ),
        Positioned.fill(
          child: CustomerMessageOverlay(
            message: linkState.lastMessage,
            sequence: linkState.messageSeq,
            onDismiss: () => ref
                .read(customerPeerLinkControllerProvider.notifier)
                .clearLocalMessage(),
            onPaymentSelected: _selectPayment,
          ),
        ),
      ],
    );
  }
}
