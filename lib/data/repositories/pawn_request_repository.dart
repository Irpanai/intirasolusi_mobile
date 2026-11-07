import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../../core/services/cache_service.dart';
import '../models/pawn_request_model.dart';
import '../models/product_model.dart';
import '../models/branch_model.dart';

class PawnRequestRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService = CacheService.instance;

  PawnRequestRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<PawnRequestModel>> getPawnRequests({
    int? page,
    int? perPage,
    String? status,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.pawnRequests,
        queryParams: {
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
          if (status != null) 'status': status,
        },
      );

      if (response.statusCode == 200) {
        // Handle paginated response: data.data contains actual items
        final responseData = response.data['data'];
        List<dynamic> items;
        
        if (responseData is Map && responseData['data'] != null) {
          // Paginated response: {data: {current_page: 1, data: [...], ...}}
          items = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          // Direct list response: {data: [...]}
          items = responseData;
        } else {
          items = [];
        }
        
        return items.map((e) => PawnRequestModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil data pengajuan',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  Future<PawnRequestModel> getPawnRequestDetail(String code) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.pawnRequestDetail(code),
      );

      if (response.statusCode == 200) {
        return PawnRequestModel.fromJson(response.data['data']);
      } else {
        throw ServerException(
          message: 'Gagal mengambil detail pengajuan',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  Future<PawnRequestModel> createPawnRequest({
    required int productId,
    int? categoryId,
    required String collateralName,
    String? collateralDescription,
    double? estimatedValue,
    required double loanAmount,
    int? preferredBranchId,
    String? notes,
    required List<File> photos,
  }) async {
    try {
      final response = await _apiClient.uploadFiles(
        ApiEndpoints.pawnRequests,
        files: photos,
        fieldName: 'collateral_photos[]',
        extraData: {
          'loan_product_id': productId,
          if (categoryId != null) 'collateral_category_id': categoryId,
          'collateral_name': collateralName,
          if (collateralDescription != null)
            'collateral_description': collateralDescription,
          if (estimatedValue != null) 'estimated_value': estimatedValue,
          'requested_loan_amount': loanAmount,
          if (preferredBranchId != null)
            'preferred_branch_id': preferredBranchId,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PawnRequestModel.fromJson(response.data['data']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Gagal membuat pengajuan',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Handle validation errors (422) or other API errors
      final response = e.response;
      if (response != null) {
        final data = response.data;
        String errorMessage = 'Gagal membuat pengajuan';
        
        if (data is Map) {
          // Check for validation errors
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            final errorMessages = <String>[];
            errors.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errorMessages.add(value.first.toString());
              }
            });
            if (errorMessages.isNotEmpty) {
              errorMessage = errorMessages.join('\n');
            }
          } else if (data['message'] != null) {
            errorMessage = data['message'].toString();
          }
        }
        
        throw ServerException(
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }
      throw ServerException(message: 'Terjadi kesalahan koneksi');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  Future<void> cancelPawnRequest(String code) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.pawnRequestCancel(code),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Gagal membatalkan pengajuan',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  // Calculator related
  /// Get products with caching (1 hour)
  Future<List<ProductModel>> getProducts({bool forceRefresh = false}) async {
    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      try {
        final cachedData = await _cacheService.getRawCache(CacheKeys.products);
        if (cachedData != null && cachedData is List) {
          return cachedData
              .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // Ignore cache errors, proceed to fetch
      }
    }

    try {
      final response = await _apiClient.get(ApiEndpoints.calculatorProducts);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final products = data.map((e) => ProductModel.fromJson(e)).toList();
        
        // Cache the products for 1 hour
        await _cacheService.setCache(
          key: CacheKeys.products,
          data: products.map((p) => p.toJson()).toList(),
          expiration: CacheDurations.products,
        );
        
        return products;
      } else {
        throw ServerException(
          message: 'Gagal mengambil data produk',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // On error, try to return cached data if available
      try {
        final cachedData = await _cacheService.getRawCache(CacheKeys.products);
        if (cachedData != null && cachedData is List) {
          return cachedData
              .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
      
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  Future<List<CollateralCategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.collateralCategories);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => CollateralCategoryModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil data kategori',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  Future<List<BranchModel>> getBranches() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.branches);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => BranchModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil data cabang',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  /// Get number of submissions made today
  Future<int> getTodaySubmissionCount() async {
    try {
      // Get all requests and filter by today's date
      final requests = await getPawnRequests();
      final today = DateTime.now();
      
      final todayCount = requests.where((request) {
        if (request.createdAt == null) return false;
        return request.createdAt!.year == today.year &&
               request.createdAt!.month == today.month &&
               request.createdAt!.day == today.day;
      }).length;
      
      return todayCount;
    } catch (e) {
      // If there's an error, return 0 to allow submission
      return 0;
    }
  }

  /// Clear products cache
  Future<void> clearProductsCache() async {
    await _cacheService.removeCache(CacheKeys.products);
  }
}
