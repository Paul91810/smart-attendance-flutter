/// Roles supported in Smart Attendance. Pure Dart enum.
enum UserRole {
  admin,
  employee;

  static UserRole fromString(String role) {
    if (role.toLowerCase() == 'admin') return UserRole.admin;
    return UserRole.employee;
  }

  String toRoleString() {
    return this == UserRole.admin ? 'admin' : 'employee';
  }
}
