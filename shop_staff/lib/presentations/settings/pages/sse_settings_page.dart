import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/application/sse/sse_runtime.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

class SseSettingsPage extends ConsumerWidget {
  const SseSettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sseRuntimeProvider);
    final runtime = ref.read(sseRuntimeProvider.notifier);
    final t = AppLocalizations.of(context);
    final machine = ref.watch(sseMachineCodeProvider);
    Future<void> edit(SseSubscriptionSettings? current) async {
      final identify = TextEditingController(text: current?.identify ?? '');
      var enabled = current?.enabled ?? false;
      var center = current?.center ?? false;
      var seat = current?.seat ?? false;
      final result = await showDialog<SseSubscriptionSettings>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              current?.kind == 'smartWe' ? 'SmartWe SSE' : 'Panda SSE',
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (current?.kind == 'smartWe')
                      ListTile(
                        title: Text(t.settingsMachineCodeLabel),
                        subtitle: Text(machine),
                      )
                    else
                      TextField(
                        controller: identify,
                        decoration: InputDecoration(labelText: t.sseIdentifier),
                      ),
                    SwitchListTile(
                      title: Text(t.sseEnabled),
                      value: enabled,
                      onChanged: (v) => setState(() => enabled = v),
                    ),
                    SwitchListTile(
                      title: Text(t.sseCenter),
                      value: center,
                      onChanged: (v) => setState(() => center = v),
                    ),
                    SwitchListTile(
                      title: Text(t.sseSeat),
                      value: seat,
                      onChanged: (v) => setState(() => seat = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.dialogCancel),
              ),
              FilledButton(
                onPressed: () {
                  if (current?.kind != 'smartWe' &&
                      identify.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(
                    context,
                    SseSubscriptionSettings(
                      id:
                          current?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
                      kind: current?.kind ?? 'panda',
                      identify: identify.text.trim(),
                      enabled: enabled,
                      center: center,
                      seat: seat,
                    ),
                  );
                },
                child: Text(t.sseSave),
              ),
            ],
          ),
        ),
      );
      // Dispose after the dialog's reverse animation has released its text field.
      Future<void>.delayed(const Duration(seconds: 1), identify.dispose);
      if (result != null) {
        final latest = ref.read(sseRuntimeProvider).settings;
        await runtime.save([...latest.where((s) => s.id != result.id), result]);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.sseTitle),
        actions: [
          IconButton(
            tooltip: t.sseReconnect,
            onPressed: () => runtime.reconcile(force: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(t.ssePrintNote),
                const SizedBox(height: 16),
                if (state.error != null)
                  Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                for (final config in state.settings)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        config.enabled ? Icons.wifi : Icons.wifi_off,
                      ),
                      title: Text(
                        '${config.kind} · ${config.kind == 'smartWe' ? machine : config.identify}',
                      ),
                      subtitle: Text(
                        [
                          _status(t, state.statuses[config.id]),
                          if (state.statuses[config.id]?.contains(' · ') ??
                              false)
                            state.statuses[config.id]!
                                .split(' · ')
                                .skip(1)
                                .join(' · '),
                        ].join(' · '),
                      ),
                      onTap: () => edit(config),
                      trailing: config.kind == 'smartWe'
                          ? const Icon(Icons.chevron_right)
                          : IconButton(
                              tooltip: t.sseDelete,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => runtime.save(
                                state.settings
                                    .where((s) => s.id != config.id)
                                    .toList(),
                              ),
                            ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => edit(null),
                    icon: const Icon(Icons.add),
                    label: Text(t.sseAdd),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t.sseRecords,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (state.records.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(t.sseEmpty),
                  ),
                for (final record in state.records.reversed.take(100))
                  Card(
                    child: ExpansionTile(
                      title: Text(
                        '${record['event']} · ${_status(t, record['status'] as String?)}',
                      ),
                      subtitle: Text('${record['time']} · ${record['uuid']}'),
                      children: [
                        if (record['status'] == 'invalid')
                          TextButton.icon(
                            onPressed: () =>
                                runtime.retryInvalid(record['uuid'] as String),
                            icon: const Icon(Icons.refresh),
                            label: Text(t.sseRetry),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            '${record['error'] ?? ''}\n${t.sseSentCount}: ${record['sent']}\n${record['data']}',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

String _status(AppLocalizations t, String? value) =>
    switch (value?.split(' · ').first) {
      'connecting' => t.sseConnecting,
      'connected' => t.sseConnected,
      'retrying' => t.sseRetrying,
      'rejected' => t.sseRejected,
      'preparing' => t.ssePreparing,
      'claiming' => t.sseClaiming,
      'sending' => t.sseSending,
      'sent' => t.sseSent,
      'declined' => t.sseDeclined,
      'invalid' => t.sseInvalid,
      'uncertain' => t.sseUncertain,
      _ => t.sseStopped,
    };
