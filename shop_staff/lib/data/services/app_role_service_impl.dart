import 'package:logging/logging.dart';

import '../../core/app_role.dart';
import '../../core/storage/key_value_store.dart';
import '../../domain/services/app_role_service.dart';

class AppRoleServiceImpl implements AppRoleService {
  AppRoleServiceImpl(this._store, {Logger? logger})
      : _logger = logger ?? Logger('AppRoleService');

  final KeyValueStore _store;
  final Logger _logger;

  @override
  Future<AppRole> loadRole() async {
    try {
      final raw = await _store.read(AppStorageKeys.appRole);
      return parseAppRole(raw);
    } catch (e, stack) {
      _logger.warning('Failed to load app role, fallback to staff', e, stack);
      return AppRole.staff;
    }
  }

  @override
  Future<void> saveRole(AppRole role) {
    return _store.write(AppStorageKeys.appRole, role.storageValue);
  }
}
