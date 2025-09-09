import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/activation_viewmodel.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(activationViewModelProvider);
    final controller = ref.read(activationViewModelProvider.notifier).codeController;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('设备激活', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: '激活码',
                    prefixIcon: const Icon(Icons.vpn_key),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => ref.read(activationViewModelProvider.notifier).mockScan(),
                    ),
                  ),
                  onSubmitted: (_) => ref.read(activationViewModelProvider.notifier).submit(context),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: vm.isLoading || vm.code.trim().isEmpty ? null : () => ref.read(activationViewModelProvider.notifier).submit(context),
                  child: vm.isLoading ? const SizedBox(height:20,width:20,child: CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Text('激活并进入'),
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: 12),
                  Text(vm.error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
