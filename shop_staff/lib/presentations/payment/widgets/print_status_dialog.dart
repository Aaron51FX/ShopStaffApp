import 'package:flutter/material.dart';
import 'package:shop_staff/presentations/printing/print_job_models.dart';

class PrintStatusDialog extends StatelessWidget {
  const PrintStatusDialog({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onSkip,
    required this.onClose,
  });

  final PrintProgressState state;
  final VoidCallback onRetry;
  final VoidCallback onSkip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final hasFailure = state.hasFailure;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.print_rounded, size: 26),
                const SizedBox(width: 8),
                const Text('打印票据', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!state.completed)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  Icon(
                    hasFailure ? Icons.error_outline : Icons.check_circle,
                    color: hasFailure ? Colors.orange : Colors.green,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.error ?? state.stage,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...state.jobs.map((job) => _JobRow(job: job)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onSkip, child: const Text('跳过')),
                const SizedBox(width: 8),
                if (hasFailure)
                  FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onClose,
                  child: Text(state.completed ? '完成' : '后台继续'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

  final PrintJobStateItem job;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color? color;
    switch (job.status) {
      case PrintJobStatus.success:
        icon = Icons.check_circle; color = Colors.green;
        break;
      case PrintJobStatus.failure:
        icon = Icons.error_outline; color = Colors.orange;
        break;
      case PrintJobStatus.running:
        icon = Icons.autorenew; color = Colors.blueGrey;
        break;
      default:
        icon = Icons.pending; color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(job.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (job.error != null)
            Text(job.error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ],
      ),
    );
  }
}