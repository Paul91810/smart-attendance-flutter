import 'package:equatable/equatable.dart';

/// Pure Dart entity representing an employee in the admin view.
class Employee extends Equatable {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String role;
  final String department;

  const Employee({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
  });

  @override
  List<Object?> get props => [id, employeeId, name, email, role, department];
}
