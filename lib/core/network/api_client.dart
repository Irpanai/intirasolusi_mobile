import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';
import '../constants/storage_keys.dart';
import '../constants/app_constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    final baseUrl = ApiEndpoints.baseUrl;
    developer.log('ApiClient initialized with baseUrl: $baseUrl', name: 'ApiClient');
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add token to protected routes
        final token = await _storage.read(key: StorageKeys.authToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired - clear storage
          await _storage.deleteAll();
        }
        return handler.next(error);
      },
    ));

    // Add logging only in debug mode to prevent leaking credentials in production
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  Dio get dio => _dio;

  // Helper methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post(String path, {dynamic data, Options? options}) {
    return _dio.post(path, data: data, options: options);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  // Multipart upload
  Future<Response> uploadFiles(
    String path, {
    required List<File> files,
    required String fieldName,
    Map<String, dynamic>? extraData,
  }) async {
    final formData = FormData();

    for (var file in files) {
      formData.files.add(MapEntry(
        fieldName,
        await MultipartFile.fromFile(file.path),
      ));
    }

    if (extraData != null) {
      extraData.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }

    return _dio.post(path, data: formData);
  }

  // Update base URL
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }
}
