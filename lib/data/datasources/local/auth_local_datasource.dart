import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/storage_keys.dart';
import '../../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  Future<String?> getToken();
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  Future<bool> hasToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _storage;

  AuthLocalDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> cacheToken(String token) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.authToken);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await _storage.write(
      key: StorageKeys.userData,
      value: jsonEncode(user.toJson()),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = await _storage.read(key: StorageKeys.userData);
    if (jsonString != null) {
      return UserModel.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    await _storage.deleteAll();
  }

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
