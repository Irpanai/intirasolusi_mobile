import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? nik,
    File? ktpImage,
  });

  Future<Map<String, dynamic>> registerWithKtp({
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
  });

  Future<UserModel> getCurrentUser();

  Future<UserModel> getProfile();

  Future<void> logout();

  Future<UserModel> updateProfile(Map<String, dynamic> data);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Login gagal',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'login');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan saat login: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? nik,
    File? ktpImage,
  }) async {
    try {
      // If ktpImage is provided, use multipart form
      if (ktpImage != null) {
        final formData = FormData.fromMap({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': password,
          'agree_terms': true,
          if (nik != null) 'nik': nik,
          'ktp_image': await MultipartFile.fromFile(
            ktpImage.path,
            filename: 'ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        });

        final response = await _apiClient.post(
          ApiEndpoints.register,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data;
        } else {
          throw ServerException(
            message: response.data['message'] ?? 'Registrasi gagal',
            statusCode: response.statusCode,
            errors: response.data['errors'],
          );
        }
      }

      // Without ktpImage, use regular JSON
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': password,
          'agree_terms': true,
          if (nik != null) 'nik': nik,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Registrasi gagal',
          statusCode: response.statusCode,
          errors: response.data['errors'],
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'registrasi');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan saat registrasi: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> registerWithKtp({
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
      final formData = FormData.fromMap({
        'email': email,
        'password': password,
        'password_confirmation': password,
        'nik': nik,
        'name': name,
        'birth_place': birthPlace,
        'birth_date': birthDate,
        'gender': gender,
        'address': address,
        'rt': rt,
        'rw': rw,
        'kelurahan': kelurahan,
        'kecamatan': kecamatan,
        if (religion != null) 'religion': religion,
        if (maritalStatus != null) 'marital_status': maritalStatus,
        if (occupation != null) 'occupation': occupation,
        if (phone != null) 'phone': phone,
        'agree_terms': true,
        'ktp_image': await MultipartFile.fromFile(
          ktpImage.path,
          filename: 'ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'selfie_image': await MultipartFile.fromFile(
          selfieImage.path,
          filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _apiClient.post(
        ApiEndpoints.registerWithKtp,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Registrasi gagal',
          statusCode: response.statusCode,
          errors: response.data['errors'],
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'registrasi KTP');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan saat registrasi: $e');
    }
  }

  ServerException _handleDioError(DioException e, String action) {
    String message;
    Map<String, dynamic>? errors;
    
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? 'Gagal $action';
        errors = data['errors'];
      } else {
        message = 'Server error: ${e.response!.statusCode}';
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.sendTimeout ||
               e.type == DioExceptionType.receiveTimeout) {
      message = 'Koneksi timeout. Periksa koneksi internet Anda.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    } else {
      message = 'Gagal $action: ${e.message ?? "Unknown error"}';
    }
    
    return ServerException(
      message: message,
      statusCode: e.response?.statusCode,
      errors: errors,
    );
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me);

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        
        // API /me returns separate 'user' and 'customer' objects
        // Combine them into the structure UserModel expects
        final userData = Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);
        userData['customer'] = data['customer'];
        
        return UserModel.fromJson(userData);
      } else {
        throw ServerException(
          message: 'Gagal mengambil data user',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.profile);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return UserModel.fromJson(data);
        }
        throw ServerException(message: 'Format data profil tidak valid');
      } else {
        throw ServerException(
          message: 'Gagal mengambil data profil',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan saat mengambil profil: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      // Ignore logout errors, still clear local cache
    }
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.profile,
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        
        // API returns {user: {...}, customer: {...}} at same level
        // Merge them for UserModel.fromJson which expects {user fields..., customer: {...}}
        final userJson = Map<String, dynamic>.from(responseData['user'] ?? {});
        if (responseData['customer'] != null) {
          userJson['customer'] = responseData['customer'];
        }
        
        return UserModel.fromJson(userJson);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Gagal update profil',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        String message = 'Gagal update profil';
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? message;
        }
        throw ServerException(
          message: message,
          statusCode: e.response!.statusCode,
        );
      }
      throw ServerException(message: 'Terjadi kesalahan saat update profil');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Gagal mengubah password',
          statusCode: response.statusCode,
          errors: response.data['errors'],
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'mengubah password');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan saat mengubah password');
    }
  }
}
