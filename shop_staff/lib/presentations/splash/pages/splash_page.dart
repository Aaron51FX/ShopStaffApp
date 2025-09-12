import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/network/api_exception.dart';

/// SplashPage: 每次启动重新获取 ShopInfo / 做后续健康检查入口
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});
  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  String? _error;
  bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_inFlight) return; setState(() => _inFlight = true);
    final store = ref.read(keyValueStoreProvider);
    final hasCode = await store.contains(AppStorageKeys.activationCode);
    if (!mounted) return;
    if (!hasCode) {
      context.go('/login');
      return;
    }
    final code = await store.read(AppStorageKeys.activationCode) ?? '';
    if (code.isEmpty) {
      context.go('/login');
      return;
    }
    try {
      final repo = ref.read(activationRepositoryProvider);
  final shop = await repo.activate(machineCode: code, version: '1.0.0');
      ref.read(shopInfoProvider.notifier).state = shop; // 注入全局
      // 补齐 machineCode (激活接口未返回时)
      final current = ref.read(shopInfoProvider);
      if (current != null && (current.machineCode == null || current.machineCode!.isEmpty)) {
        ref.read(shopInfoProvider.notifier).state = current.copyWith(machineCode: code);
      }
      debugPrint('[Splash] backend success, navigating to /pos');
      if (!mounted) return;
      context.go('/pos');
    } catch (e) {
      String msg;
      if (e is ApiException) {
        final sc = e.statusCode;
        // 截断超长 HTML
        final raw = e.data is String ? (e.data as String) : e.toString();
        final short = raw.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ');
        msg = '激活失败(${sc ?? '网络'}): ${short.substring(0, short.length > 180 ? 180 : short.length)}';
      } else {
        final s = e.toString();
        msg = '加载失败: ${s.substring(0, s.length > 180 ? 180 : s.length)}';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _inFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            if (_error == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('正在初始化...', style: theme.textTheme.titleMedium),
            ] else ...[
              Icon(Icons.error_outline, color: Colors.red[400], size: 44),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320, maxHeight: 180),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                ),
              ),
              const SizedBox(height: 12),
              Text('可能原因: 临时网络/服务器 502, 版本号不匹配, 或机号无效',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 16),
              Wrap(spacing: 16, children: [
                ElevatedButton(onPressed: _inFlight ? null : _run, child: const Text('重试')),
                OutlinedButton(onPressed: () => context.go('/login'), child: const Text('重新激活')),
              ]),
            ]
          ],
        ),
      ),
    );
  }
}
