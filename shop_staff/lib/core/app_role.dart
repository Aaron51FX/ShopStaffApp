enum AppRole { staff, customer }

AppRole parseAppRole(String? raw) {
  switch (raw) {
    case 'customer':
      return AppRole.customer;
    case 'staff':
    default:
      return AppRole.staff;
  }
}

extension AppRoleLabel on AppRole {
  String get label => this == AppRole.staff ? '店员端' : '顾客端';
  String get storageValue => name;
}
