import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_staff/application/auth/login_flow_usecase.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import '../../../data/providers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/app_role.dart';

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
    if (_inFlight) return;
    setState(() => _inFlight = true);
    try {
      final t = AppLocalizations.of(context);
      final login = ref.read(loginFlowUseCaseProvider);
      final result = await login.resume();
      if (!mounted) return;
      if (result == null) {
        context.go('/login');
        return;
      }
      ref.read(shopInfoProvider.notifier).state = result.startup.shopInfo;
      ref.read(appSettingsSnapshotProvider.notifier).state = result.startup.settings;
      ref.read(appRoleProvider.notifier).state = result.role;
      _error = null;
      debugPrint('[Splash] resume success, navigating to role=${result.role.name}');
      context.go(result.role == AppRole.customer ? '/customer' : '/entry');
    } catch (e) {
      final t = AppLocalizations.of(context);
      String msg;
      if (e is ApiException) {
        final sc = e.statusCode;
        // 截断超长 HTML
        final raw = e.data is String ? (e.data as String) : e.toString();
        final short = raw
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ');
        final statusLabel = sc?.toString() ?? t.commonNetworkLabel;
        msg = t.splashActivationFailedMessage(
          statusLabel,
          short.substring(0, short.length > 180 ? 180 : short.length),
        );
      } else {
        final s = e.toString();
        msg = t.splashLoadFailedMessage(
          s.substring(0, s.length > 180 ? 180 : s.length),
        );
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _inFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
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
              Text(t.splashInitializing, style: theme.textTheme.titleMedium),
            ] else ...[
              Icon(Icons.error_outline, color: Colors.red[400], size: 44),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 320,
                  maxHeight: 180,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.splashPossibleCauses,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                children: [
                  ElevatedButton(
                    onPressed: _inFlight ? null : _run,
                    child: Text(t.splashRetry),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go('/login'),
                    child: Text(t.splashReactivate),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
