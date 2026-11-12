import '../../domain/entities/user.dart';
import '../../domain/entities/user_role.dart';

/// Data model representing a user with JSON serialization.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.employeeId,
    required super.name,
    required super.email,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'employee'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'name': name,
      'email': email,
      'role': role.toRoleString(),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      employeeId: user.employeeId,
      name: user.name,
      email: user.email,
      role: user.role,
    );
  }

  User toEntity() {
    return User(
      id: id,
      employeeId: employeeId,
      name: name,
      email: email,
      role: role,
    );
  }
}
