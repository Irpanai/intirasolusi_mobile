import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../models/location_model.dart';

class LocationRepository {
  final ApiClient _apiClient;

  LocationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get all provinces
  Future<List<ProvinceModel>> getProvinces() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.provinces);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => ProvinceModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw ServerException(
          message: 'Gagal mengambil data provinsi',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  /// Get cities by province code
  Future<List<CityModel>> getCities(String provinceCode) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.cities(provinceCode));

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => CityModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw ServerException(
          message: 'Gagal mengambil data kota/kabupaten',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  /// Get districts by city code
  Future<List<DistrictModel>> getDistricts(String cityCode) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.districts(cityCode));

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => DistrictModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw ServerException(
          message: 'Gagal mengambil data kecamatan',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  /// Get villages by district code
  Future<List<VillageModel>> getVillages(String districtCode) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.villages(districtCode));

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => VillageModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw ServerException(
          message: 'Gagal mengambil data kelurahan/desa',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }
}
