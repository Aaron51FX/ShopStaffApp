import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/presentations/payment/widgets/print_status_dialog.dart';
import 'print_job_models.dart';
import 'print_job_viewmodel.dart';

Future<void> showPrintStatusDialog({
  required BuildContext context,
  required WidgetRef ref,
  required PrintJobRequest request,
  VoidCallback? onCompleted,
}) async {
  final provider = printJobViewModelProvider(request);
  final notifier = ref.read(provider.notifier);
  await notifier.start();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(provider);
          return PrintStatusDialog(
            state: state,
            onRetry: notifier.retry,
            onSkip: () => Navigator.of(context, rootNavigator: true).pop(),
            onClose: () {
              Navigator.of(context, rootNavigator: true).pop();
              onCompleted?.call();
            },
          );
        },
      );
    },
  );
}