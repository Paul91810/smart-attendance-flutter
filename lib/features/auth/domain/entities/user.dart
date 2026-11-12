import 'package:equatable/equatable.dart';
import 'user_role.dart';

/// Pure domain entity representing an authenticated user.
class User extends Equatable {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final UserRole role;

  const User({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isEmployee => role == UserRole.employee;

  @override
  List<Object?> get props => [id, employeeId, name, email, role];

  @override
  String toString() =>
      'User(id: $id, employeeId: $employeeId, name: $name, role: ${role.name})';
}
