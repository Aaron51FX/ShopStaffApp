import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:multipeer_session/multipeer_session.dart';

import 'widgets/cart_content.dart';
import 'widgets/category_grid_content.dart';
import 'widgets/option_group_content.dart';
import 'widgets/payment_selection_content.dart';
import 'widgets/product_options_content.dart';
import 'widgets/product_preview_content.dart';
import 'widgets/unknown_message_content.dart';

class CustomerMessageOverlay extends StatelessWidget {
  const CustomerMessageOverlay({
    required this.message,
    required this.sequence,
    required this.onDismiss,
    required this.onPaymentSelected,
    super.key,
  });

  final PeerMessage? message;
  final int sequence;
  final VoidCallback onDismiss;
  final PaymentOptionSelected onPaymentSelected;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) {
              if (child is! _TypedMessageOverlay) return child;
              final isEntering = child.key == ValueKey(sequence);
              final (enterOffset, exitOffset) = _transitionOffsets(child.type);
              final tween = isEntering
                  ? Tween<Offset>(begin: enterOffset, end: Offset.zero)
                  : Tween<Offset>(begin: exitOffset, end: Offset.zero);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: tween.animate(animation),
                  child: child,
                ),
              );
            },
            child: _TypedMessageOverlay(
              key: ValueKey(sequence),
              type: message.type,
              child: GestureDetector(
                onLongPress: onDismiss,
                child: _CustomerMessageCard(
                  message: message,
                  onPaymentSelected: onPaymentSelected,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

(Offset, Offset) _transitionOffsets(String type) {
  return switch (type) {
    'category_grid' ||
    'cart_snapshot' => (const Offset(0, 1), const Offset(0, -1)),
    'product_preview' => (const Offset(1, 0), const Offset(-1, 0)),
    _ => (Offset.zero, Offset.zero),
  };
}

class _TypedMessageOverlay extends StatelessWidget {
  const _TypedMessageOverlay({
    required this.type,
    required this.child,
    super.key,
  });

  final String type;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _CustomerMessageCard extends StatelessWidget {
  const _CustomerMessageCard({
    required this.message,
    required this.onPaymentSelected,
  });

  final PeerMessage message;
  final PaymentOptionSelected onPaymentSelected;

  @override
  Widget build(BuildContext context) {
    final content = switch (message.type) {
      'category_grid' => CategoryGridContent(payload: message.payload),
      'product_preview' => ProductPreviewContent(payload: message.payload),
      'product_options' => ProductOptionsContent(payload: message.payload),
      'option_group' => OptionGroupContent(payload: message.payload),
      'cart_snapshot' => CartContent(payload: message.payload),
      'payment_selection' => PaymentSelectionContent(
        payload: message.payload,
        onSelected: onPaymentSelected,
      ),
      'payment_cash' ||
      'payment_card' ||
      'payment_qrcode' => const SizedBox.shrink(),
      _ => UnknownMessageContent(type: message.type),
    };

    return FractionallySizedBox(
      widthFactor: 0.9,
      heightFactor: 0.9,
      child: Material(
        color: Colors.transparent,
        child: Center(child: content),
      ),
    );
  }
}
