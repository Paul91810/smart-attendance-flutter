class DummyUser {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String role; // 'admin' or 'employee'
  final String password;

  const DummyUser({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.role,
    required this.password,
  });

  Map<String, dynamic> toUserMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}

class DummyUsersStore {
  DummyUsersStore._();

  static final List<DummyUser> users = [
    // 1 Admin
    const DummyUser(
      id: 'usr_admin_000',
      employeeId: 'EMP000',
      name: 'System Admin',
      email: 'admin@smartattendance.com',
      role: 'admin',
      password: 'admin123',
    ),
    // 5 Employees
    const DummyUser(
      id: 'usr_emp_001',
      employeeId: 'EMP001',
      name: 'Alice Johnson',
      email: 'alice@smartattendance.com',
      role: 'employee',
      password: 'password123',
    ),
    const DummyUser(
      id: 'usr_emp_002',
      employeeId: 'EMP002',
      name: 'Bob Smith',
      email: 'bob@smartattendance.com',
      role: 'employee',
      password: 'password123',
    ),
    const DummyUser(
      id: 'usr_emp_003',
      employeeId: 'EMP003',
      name: 'Charlie Brown',
      email: 'charlie@smartattendance.com',
      role: 'employee',
      password: 'password123',
    ),
    const DummyUser(
      id: 'usr_emp_004',
      employeeId: 'EMP004',
      name: 'Diana Prince',
      email: 'diana@smartattendance.com',
      role: 'employee',
      password: 'password123',
    ),
    const DummyUser(
      id: 'usr_emp_005',
      employeeId: 'EMP005',
      name: 'Evan Wright',
      email: 'evan@smartattendance.com',
      role: 'employee',
      password: 'password123',
    ),
  ];

  static DummyUser? findByIdentifier(String identifier) {
    final clean = identifier.trim().toLowerCase();
    for (final user in users) {
      if (user.email.toLowerCase() == clean ||
          user.employeeId.toLowerCase() == clean) {
        return user;
      }
    }
    return null;
  }

  static DummyUser? findById(String id) {
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }
}
