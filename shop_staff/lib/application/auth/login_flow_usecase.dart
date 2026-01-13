import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/core/app_role.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/services/app_role_service.dart';
import 'package:shop_staff/domain/services/startup_service.dart';

final loginFlowUseCaseProvider = Provider<LoginFlowUseCase>((ref) {
  return LoginFlowUseCase(
    startupService: ref.watch(startupServiceProvider),
    appRoleService: ref.watch(appRoleServiceProvider),
    logger: Logger('LoginFlowUseCase'),
  );
});

class LoginBootstrapResult {
  const LoginBootstrapResult({
    required this.startup,
    required this.role,
  });

  final StartupResult startup;
  final AppRole role;
}

class LoginFlowUseCase {
  LoginFlowUseCase({
    required StartupService startupService,
    required AppRoleService appRoleService,
    Logger? logger,
  })  : _startupService = startupService,
        _appRoleService = appRoleService,
        _logger = logger ?? Logger('LoginFlowUseCase');

  final StartupService _startupService;
  final AppRoleService _appRoleService;
  final Logger _logger;

  Future<LoginBootstrapResult> activate(String machineCode) async {
    _logger.fine('Activate with machineCode=${machineCode.trim()}');
    final startup = await _startupService.activate(machineCode);
    final role = await _appRoleService.loadRole();
    return LoginBootstrapResult(startup: startup, role: role);
  }

  Future<LoginBootstrapResult?> resume() async {
    _logger.fine('Resume activation');
    final startup = await _startupService.resume();
    if (startup == null) return null;
    final role = await _appRoleService.loadRole();
    return LoginBootstrapResult(startup: startup, role: role);
  }
}
