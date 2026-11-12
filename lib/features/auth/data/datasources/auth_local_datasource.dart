import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> saveToken(String token) async {
    try {
      await secureStorage.write(key: StorageKeys.authToken, value: token);
    } catch (e) {
      throw CacheException('Failed to persist auth token: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await secureStorage.read(key: StorageKeys.authToken);
    } catch (e) {
      throw CacheException('Failed to read auth token: $e');
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      final jsonString = jsonEncode(user.toJson());
      await secureStorage.write(key: StorageKeys.cachedUser, value: jsonString);
    } catch (e) {
      throw CacheException('Failed to cache user profile: $e');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = await secureStorage.read(key: StorageKeys.cachedUser);
      if (jsonString == null || jsonString.isEmpty) return null;
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (e) {
      throw CacheException('Failed to retrieve cached user: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await secureStorage.delete(key: StorageKeys.authToken);
      await secureStorage.delete(key: StorageKeys.cachedUser);
    } catch (e) {
      throw CacheException('Failed to clear local auth data: $e');
    }
  }
}
