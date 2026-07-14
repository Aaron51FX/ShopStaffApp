import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shop_staff/application/checkout/checkout_providers.dart';
import 'package:shop_staff/application/checkout/checkout_state.dart';
import 'package:shop_staff/application/printing/models/print_job_request.dart';
import 'package:shop_staff/presentations/printing/show_print_dialog.dart';

/// Checkout-owned bridge that presents printing without coupling payment UI to
/// the printing feature.
class CheckoutPrintListener extends ConsumerStatefulWidget {
  const CheckoutPrintListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CheckoutPrintListener> createState() =>
      _CheckoutPrintListenerState();
}

class _CheckoutPrintListenerState extends ConsumerState<CheckoutPrintListener> {
  ProviderSubscription<CheckoutState>? _subscription;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<CheckoutState>(
      checkoutCoordinatorProvider,
      (previous, next) {
        final request = next.printRequest;
        if (!mounted ||
            next.stage != CheckoutStage.printReady ||
            request == null ||
            identical(previous?.printRequest, request)) {
          return;
        }
        unawaited(_showPrint(request));
      },
    );
  }

  Future<void> _showPrint(PrintJobRequest request) async {
    if (_printing) return;
    _printing = true;
    final coordinator = ref.read(checkoutCoordinatorProvider.notifier);
    coordinator.printingStarted();
    try {
      await showPrintStatusDialog(
        context: context,
        ref: ref,
        request: request,
        onCompleted: () {
          if (mounted) context.go('/entry');
        },
      );
    } finally {
      coordinator.printingCompleted();
      _printing = false;
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
