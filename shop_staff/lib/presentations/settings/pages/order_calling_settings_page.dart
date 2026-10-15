import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/application/order_calling/order_calling_controller.dart';
import 'package:shop_staff/domain/order_calling/order_calling.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

class OrderCallingSettingsPage extends ConsumerStatefulWidget {
  const OrderCallingSettingsPage({super.key});
  @override
  ConsumerState<OrderCallingSettingsPage> createState() =>
      _OrderCallingSettingsPageState();
}

class _OrderCallingSettingsPageState
    extends ConsumerState<OrderCallingSettingsPage> {
  final _ip = TextEditingController();
  final _port = TextEditingController(text: '3000');
  final _form = GlobalKey<FormState>();
  bool _loaded = false, _enabled = false, _saving = false;
  @override
  void dispose() {
    _ip.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final saved = await ref
        .read(orderCallingControllerProvider.notifier)
        .saveSettings(
          OrderCallingSettings(
            enabled: _enabled,
            ip: _ip.text.trim(),
            port: int.tryParse(_port.text.trim()) ?? 3000,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      if (_port.text.trim().isEmpty) _port.text = '3000';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).callingSaved)),
      );
    }
  }

  Future<void> _retry(String id) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.callingRetry),
        content: Text(t.callingRetryNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.dialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(orderCallingControllerProvider.notifier).retry(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderCallingControllerProvider);
    final t = AppLocalizations.of(context);
    if (!_loaded && !state.loading) {
      _loaded = true;
      _ip.text = state.settings.ip;
      _port.text = state.settings.port.toString();
      _enabled = state.settings.enabled;
    }
    String status(String? value) => switch (value) {
      'pending' => t.callingPending,
      'sending' => t.callingSending,
      'sent' => t.callingSent,
      'uncertain' => t.callingUncertain,
      _ => t.callingFailed,
    };
    return Scaffold(
      appBar: AppBar(title: Text(t.callingTitle)),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(t.callingNote),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.callingEnabled),
                    value: _enabled,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _enabled = value),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  key: const ValueKey('orderPushIp'),
                                  controller: _ip,
                                  enabled: !_saving,
                                  autocorrect: false,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    labelText: t.callingAddress,
                                    hintText: t.callingAddressHint,
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (!_enabled &&
                                        (value?.trim().isEmpty ?? true)) {
                                      return null;
                                    }
                                    return OrderCallingSettings.isValidIp(
                                          value ?? '',
                                        )
                                        ? null
                                        : t.callingAddressInvalid;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: const ValueKey('orderPushPort'),
                                  controller: _port,
                                  enabled: !_saving,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: t.callingPort,
                                    hintText: '3000',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value?.trim().isEmpty ?? true) {
                                      return null;
                                    }
                                    final port = int.tryParse(value!.trim());
                                    return port != null &&
                                            port >= 1 &&
                                            port <= 65535
                                        ? null
                                        : t.callingPortInvalid;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.callingPortHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(t.callingSave),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    t.callingHistory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (state.records
                      .where(
                        (r) => isCallingOrderEvent(
                          r['event'] as String? ?? 'message',
                        ),
                      )
                      .isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(t.callingEmpty),
                    ),
                  for (final record
                      in state.records.reversed
                          .where(
                            (r) => isCallingOrderEvent(
                              r['event'] as String? ?? 'message',
                            ),
                          )
                          .take(100))
                    Card(
                      child: ExpansionTile(
                        title: Text(
                          '${status(record['status'] as String?)} · ${record['event']}',
                        ),
                        subtitle: Text(
                          '${record['time']} · ${record['source']}\n${record['uuid']}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  '${record['endpoint']}\n${record['error'] ?? ''}',
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  const JsonEncoder.withIndent(
                                    '  ',
                                  ).convert(record['payload']),
                                ),
                                if ({
                                  'failed',
                                  'uncertain',
                                }.contains(record['status']))
                                  TextButton.icon(
                                    onPressed: state.settings.enabled
                                        ? () => _retry(record['id'] as String)
                                        : null,
                                    icon: const Icon(Icons.refresh),
                                    label: Text(t.callingRetry),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
