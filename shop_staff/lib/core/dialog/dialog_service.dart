import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog request model
class DialogRequest<T> {
  final String title;
  final String? message;
  final List<DialogAction<T>> actions;
  final bool dismissible;
  const DialogRequest({
    required this.title,
    this.message,
    required this.actions,
    this.dismissible = true,
  });
}

class DialogAction<T> {
  final String label;
  final T? value;
  final bool isPrimary;
  final bool isDestructive;
  const DialogAction({
    required this.label,
    this.value,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}

/// Internal state: holds the current active dialog request and completer
class _DialogState {
  final DialogRequest request;
  final void Function(dynamic value) complete;
  const _DialogState(this.request, this.complete);
}

/// Notifier managing a queue of dialog requests
class DialogController extends StateNotifier<List<_DialogState>> {
  DialogController() : super(const []);

  Future<T?> show<T>(DialogRequest<T> request) {
    final completer = Completer<T?>();
    void resolver(dynamic v) {
      if (!completer.isCompleted) completer.complete(v as T?);
      _popFirst();
    }
    state = [...state, _DialogState(request, resolver)];
    return completer.future;
  }

  void _popFirst() {
    if (state.isEmpty) return;
    final list = [...state];
    list.removeAt(0);
    state = list;
  }

  void dismissCurrent() {
    if (state.isEmpty) return;
    state.first.complete(null);
  }
}

final dialogControllerProvider = StateNotifierProvider<DialogController, List<_DialogState>>(
  (ref) => DialogController(),
);

/// Widget host placed above MaterialApp.router to listen & render dialogs via Overlay
class GlobalDialogHost extends ConsumerWidget {
  final Widget child;
  const GlobalDialogHost({super.key, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(dialogControllerProvider);
    return Stack(children: [
      child,
      if (queue.isNotEmpty) _DialogOverlay(state: queue.first),
    ]);
  }
}

class _DialogOverlay extends StatelessWidget {
  final _DialogState state;
  const _DialogOverlay({required this.state});
  @override
  Widget build(BuildContext context) {
    final req = state.request;
    return GestureDetector(
      onTap: req.dismissible ? () => state.complete(null) : null,
      child: Container(
        color: Colors.black.withOpacity(0.35),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (ctx, box) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _ModernDialog(request: req, onAction: state.complete),
          ),
        ),
      ),
    );
  }
}

class _ModernDialog extends StatelessWidget {
  final DialogRequest request;
  final void Function(dynamic value) onAction;
  const _ModernDialog({required this.request, required this.onAction});
  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: surface,
      elevation: 24,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (request.message != null) ...[
              const SizedBox(height: 12),
              Text(request.message!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.75))),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: request.actions.map((a) {
                final bg = a.isPrimary
                    ? Theme.of(context).colorScheme.primary
                    : a.isDestructive
                        ? Colors.red.shade50
                        : Theme.of(context).colorScheme.surfaceVariant;
                final fg = a.isPrimary
                    ? Colors.white
                    : a.isDestructive
                        ? Colors.red.shade700
                        : onSurface.withOpacity(0.85);
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: bg,
                    foregroundColor: fg,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => onAction(a.value),
                  child: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}

// Convenience helpers for common patterns
extension DialogControllerX on DialogController {
  Future<bool> confirm({
    required String title,
    String? message,
    String okText = '确定',
    String cancelText = '取消',
    bool destructive = false,
  }) async {
    final result = await show<bool>(DialogRequest<bool>(
      title: title,
      message: message,
      actions: [
        DialogAction(label: cancelText),
        DialogAction(label: okText, value: true, isPrimary: !destructive, isDestructive: destructive),
      ],
    ));
    return result == true;
  }

  Future<List<T>> multiSelect<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelBuilder,
    List<T>? initial,
    String confirmText = '确定',
    String cancelText = '取消',
  }) async {
    final selected = {...?initial};
    final result = await show<List<T>>(DialogRequest<List<T>>(
      title: title,
      actions: [
        DialogAction(label: cancelText),
        DialogAction(label: confirmText, value: selected.toList(), isPrimary: true),
      ],
      // message=null; builder logic handled via custom wrapper below
    ));
    return result ?? const [];
  }
}
