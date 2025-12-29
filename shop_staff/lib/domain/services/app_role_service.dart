import '../../core/app_role.dart';

abstract class AppRoleService {
  Future<AppRole> loadRole();
  Future<void> saveRole(AppRole role);
}
