import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../../core/services/cache_service.dart';
import '../models/branch_model.dart';

class BranchRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService = CacheService.instance;

  BranchRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get all branches with caching (1 day)
  /// Only caches when no filters are applied
  Future<List<BranchModel>> getBranches({
    String? province,
    String? city,
    String? search,
    bool forceRefresh = false,
  }) async {
    // Only use cache when no filters are applied
    final useCache = province == null && city == null && search == null;
    
    // Try cache first if applicable
    if (useCache && !forceRefresh) {
      try {
        final cachedData = await _cacheService.getRawCache(CacheKeys.branches);
        if (cachedData != null && cachedData is List) {
          return cachedData
              .map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // Ignore cache errors, proceed to fetch
      }
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.branches,
        queryParams: {
          if (province != null) 'province': province,
          if (city != null) 'city': city,
          if (search != null) 'search': search,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final branches = data.map((e) => BranchModel.fromJson(e)).toList();
        
        // Cache only when no filters (full list)
        if (useCache) {
          await _cacheService.setCache(
            key: CacheKeys.branches,
            data: branches.map((b) => b.toJson()).toList(),
            expiration: CacheDurations.branches,
          );
        }
        
        return branches;
      } else {
        throw ServerException(
          message: 'Gagal mengambil data cabang',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // On error, try to return cached data if available
      if (useCache) {
        try {
          final cachedData = await _cacheService.getRawCache(CacheKeys.branches);
          if (cachedData != null && cachedData is List) {
            return cachedData
                .map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }

      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  Future<BranchModel> getBranchDetail(String code) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.branchDetail(code));

      if (response.statusCode == 200) {
        return BranchModel.fromJson(response.data['data']);
      } else {
        throw ServerException(
          message: 'Gagal mengambil detail cabang',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  Future<List<BranchModel>> getNearbyBranches({
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.branchesNearby,
        queryParams: {
          'latitude': latitude,
          'longitude': longitude,
          if (radius != null) 'radius': radius,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => BranchModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil cabang terdekat',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  Future<List<String>> getCities() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.branchesCities);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => e.toString()).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil daftar kota',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  Future<List<String>> getProvinces() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.branchesProvinces);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => e.toString()).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil daftar provinsi',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }

  /// Clear branches cache
  Future<void> clearCache() async {
    await _cacheService.removeCache(CacheKeys.branches);
  }
}
