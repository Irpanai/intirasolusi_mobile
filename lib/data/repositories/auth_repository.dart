import 'dart:io';
import '../models/user_model.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../../core/errors/exceptions.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepository({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl(),
        _localDataSource = localDataSource ?? AuthLocalDataSourceImpl();

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      final token = response['data']['token'] as String;
      await _localDataSource.cacheToken(token);

      // Combine user and customer data (API returns them separately)
      final userData = Map<String, dynamic>.from(response['data']['user'] as Map<String, dynamic>);
      userData['customer'] = response['data']['customer'];
      
      final user = UserModel.fromJson(userData);
      await _localDataSource.cacheUser(user);

      return AuthResult(
        success: true,
        message: response['message'] ?? 'Login berhasil',
        user: user,
        token: token,
        requiresProfileCompletion: !(user.customer?.isProfileComplete ?? false),
      );
    } on ServerException catch (e) {
      return AuthResult(
        success: false,
        message: e.message,
        errors: _parseErrors(e.errors),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Login gagal: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? nik,
    File? ktpImage,
  }) async {
    try {
      final response = await _remoteDataSource.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        nik: nik,
        ktpImage: ktpImage,
      );

      final token = response['data']['token'] as String;
      await _localDataSource.cacheToken(token);

      // Combine user and customer data (API returns them separately)
      final userData = Map<String, dynamic>.from(response['data']['user'] as Map<String, dynamic>);
      userData['customer'] = response['data']['customer'];
      
      final user = UserModel.fromJson(userData);
      await _localDataSource.cacheUser(user);

      return AuthResult(
        success: true,
        message: response['message'] ?? 'Registrasi berhasil',
        user: user,
        token: token,
        requiresProfileCompletion: true,
      );
    } on ServerException catch (e) {
      return AuthResult(
        success: false,
        message: e.message,
        errors: _parseErrors(e.errors),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registrasi gagal: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> registerWithKtp({
    required String email,
    required String password,
    required File ktpImage,
    required File selfieImage,
    required String nik,
    required String name,
    required String birthPlace,
    required String birthDate,
    required String gender,
    required String address,
    required String rt,
    required String rw,
    required String kelurahan,
    required String kecamatan,
    String? religion,
    String? maritalStatus,
    String? occupation,
    String? phone,
  }) async {
    try {
      final response = await _remoteDataSource.registerWithKtp(
        email: email,
        password: password,
        ktpImage: ktpImage,
        selfieImage: selfieImage,
        nik: nik,
        name: name,
        birthPlace: birthPlace,
        birthDate: birthDate,
        gender: gender,
        address: address,
        rt: rt,
        rw: rw,
        kelurahan: kelurahan,
        kecamatan: kecamatan,
        religion: religion,
        maritalStatus: maritalStatus,
        occupation: occupation,
        phone: phone,
      );

      final token = response['data']['token'] as String;
      await _localDataSource.cacheToken(token);

      // Combine user and customer data (API returns them separately)
      final userData = Map<String, dynamic>.from(response['data']['user'] as Map<String, dynamic>);
      userData['customer'] = response['data']['customer'];
      
      final user = UserModel.fromJson(userData);
      await _localDataSource.cacheUser(user);

      return AuthResult(
        success: true,
        message: response['message'] ?? 'Registrasi berhasil',
        user: user,
        token: token,
        requiresProfileCompletion: false,
      );
    } on ServerException catch (e) {
      return AuthResult(
        success: false,
        message: e.message,
        errors: _parseErrors(e.errors),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Registrasi gagal: ${e.toString()}',
      );
    }
  }

  Map<String, List<String>>? _parseErrors(Map<String, dynamic>? errors) {
    if (errors == null) return null;
    return errors.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.cast<String>());
      }
      return MapEntry(key, [value.toString()]);
    });
  }

  Future<bool> hasToken() async {
    return await _localDataSource.hasToken();
  }

  Future<UserModel> getCurrentUser() async {
    final user = await _remoteDataSource.getCurrentUser();
    await _localDataSource.cacheUser(user);
    return user;
  }

  Future<UserModel> getProfile() async {
    final user = await _remoteDataSource.getProfile();
    await _localDataSource.cacheUser(user);
    return user;
  }

  Future<UserModel?> getCachedUser() async {
    return await _localDataSource.getCachedUser();
  }

  Future<void> logout() async {
    await _remoteDataSource.logout();
    await _localDataSource.clearCache();
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final user = await _remoteDataSource.updateProfile(data);
    await _localDataSource.cacheUser(user);
    return user;
  }

  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return ChangePasswordResult(
        success: true,
        message: 'Password berhasil diubah',
      );
    } on ServerException catch (e) {
      return ChangePasswordResult(
        success: false,
        message: e.message,
        errors: _parseErrors(e.errors),
      );
    } catch (e) {
      return ChangePasswordResult(
        success: false,
        message: 'Gagal mengubah password: ${e.toString()}',
      );
    }
  }
}

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;
  final bool requiresProfileCompletion;
  final Map<String, List<String>>? errors;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.requiresProfileCompletion = false,
    this.errors,
  });
}

class ChangePasswordResult {
  final bool success;
  final String message;
  final Map<String, List<String>>? errors;

  ChangePasswordResult({
    required this.success,
    required this.message,
    this.errors,
  });
}
