import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../models/calculator_model.dart';

class CalculatorRepository {
  final ApiClient _apiClient;

  CalculatorRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get daftar produk untuk kalkulator
  Future<List<CalculatorProductModel>> getProducts() async {
    try {
      developer.log('Fetching products from: ${ApiEndpoints.calculatorProducts}', name: 'CalculatorRepository');
      final response = await _apiClient.get(ApiEndpoints.calculatorProducts);
      
      developer.log('Response statusCode: ${response.statusCode}', name: 'CalculatorRepository');
      developer.log('Response data type: ${response.data.runtimeType}', name: 'CalculatorRepository');
      developer.log('Response data: ${response.data}', name: 'CalculatorRepository');

      if (response.statusCode == 200) {
        // Handle different response structures
        dynamic rawData = response.data;
        List<dynamic> data;
        
        if (rawData is Map && rawData.containsKey('data')) {
          data = rawData['data'] as List<dynamic>;
        } else if (rawData is List) {
          data = rawData;
        } else {
          developer.log('Unexpected response structure: $rawData', name: 'CalculatorRepository');
          throw ServerException(message: 'Format response tidak sesuai');
        }
        
        developer.log('Products count: ${data.length}', name: 'CalculatorRepository');
        
        // Log each product data for debugging
        for (var i = 0; i < data.length; i++) {
          developer.log('Product[$i]: ${data[i]}', name: 'CalculatorRepository');
          if (data[i] is Map) {
            final map = data[i] as Map;
            map.forEach((key, value) {
              developer.log('  $key: $value (${value.runtimeType})', name: 'CalculatorRepository');
            });
          }
        }
        
        final products = <CalculatorProductModel>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final product = CalculatorProductModel.fromJson(data[i]);
            developer.log('Successfully parsed product[$i]: ${product.name}', name: 'CalculatorRepository');
            products.add(product);
          } catch (parseError, parseStack) {
            developer.log('Error parsing product[$i]: $parseError', name: 'CalculatorRepository', error: parseError, stackTrace: parseStack);
          }
        }
        
        developer.log('Total products parsed successfully: ${products.length}', name: 'CalculatorRepository');
        return products;
      } else {
        throw ServerException(
          message: 'Gagal mengambil data produk',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e, stackTrace) {
      developer.log('DioException getProducts: ${e.type} - ${e.message}', name: 'CalculatorRepository');
      developer.log('DioException response: ${e.response?.data}', name: 'CalculatorRepository');
      developer.log('DioException statusCode: ${e.response?.statusCode}', name: 'CalculatorRepository', stackTrace: stackTrace);
      
      String errorMessage = 'Gagal mengambil data produk';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Koneksi timeout, periksa jaringan anda';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Tidak dapat terhubung ke server';
      } else if (e.response != null) {
        errorMessage = e.response?.data?['message'] ?? 'Server error: ${e.response?.statusCode}';
      }
      
      throw ServerException(message: errorMessage, statusCode: e.response?.statusCode);
    } on TypeError catch (e, stackTrace) {
      developer.log('TypeError getProducts: $e', name: 'CalculatorRepository', error: e, stackTrace: stackTrace);
      throw ServerException(message: 'Error parsing data: $e');
    } catch (e, stackTrace) {
      developer.log('Error getProducts: $e (${e.runtimeType})', name: 'CalculatorRepository', error: e, stackTrace: stackTrace);
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  /// Get tier/tingkatan untuk produk tertentu
  Future<List<CalculatorTierModel>> getProductTiers(int productId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.calculatorTiers(productId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => CalculatorTierModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil data tier produk',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  /// Get kategori jaminan (collateral)
  Future<List<CollateralCategoryModel>> getCollateralCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.collateralCategories);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => CollateralCategoryModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil kategori jaminan',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  /// Get kategori produk
  Future<List<ProductCategoryModel>> getProductCategories() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.productCategories);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => ProductCategoryModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil kategori produk',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  /// Hitung estimasi pinjaman via API
  Future<CalculateResultModel> calculate(CalculateRequest request) async {
    try {
      developer.log('calculate: request=${request.toJson()}', name: 'CalculatorRepository');
      final response = await _apiClient.post(
        ApiEndpoints.calculatorCalculate,
        data: request.toJson(),
      );

      developer.log('calculate: statusCode=${response.statusCode}', name: 'CalculatorRepository');
      developer.log('calculate: response=${response.data}', name: 'CalculatorRepository');

      if (response.statusCode == 200) {
        final result = CalculateResultModel.fromJson(response.data['data']);
        developer.log('calculate: parsed adminFee=${result.adminFee}, tenor=${result.tenor}', 
            name: 'CalculatorRepository');
        return result;
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Gagal menghitung pinjaman',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      developer.log('calculate error: $e', name: 'CalculatorRepository', error: e, stackTrace: stackTrace);
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  /// Hitung estimasi pinjaman secara lokal (fallback jika API tidak tersedia)
  /// Untuk produk dengan tiers: cari tier terdekat dan gunakan biayanya
  CalculateResultModel calculateLocal({
    required CalculatorProductModel product,
    required double amount,
    int? tenor,
  }) {
    double interestRate = 0;
    double interest = 0;
    double adminFee = 0;
    double adminFeePercent = 0;
    int effectiveTenor = tenor ?? product.defaultTenor ?? 30;
    
    // Jika produk memiliki tiers, cari tier yang cocok
    if (product.hasTiers && product.tiers != null && product.tiers!.isNotEmpty) {
      final matchingTier = product.getTierForAmount(amount);
      developer.log('calculateLocal: hasTiers=true, amount=$amount, matchingTier=${matchingTier?.id}', 
          name: 'CalculatorRepository');
      
      if (matchingTier != null) {
        // Gunakan tenor dari tier jika ada
        if (matchingTier.tenor != null) {
          effectiveTenor = matchingTier.tenor!;
        }
        
        if (product.isSharia) {
          // Syariah: gunakan initialFee + adminFee dari tier
          adminFee = (matchingTier.adminFee ?? 0) + (matchingTier.initialFee ?? 0);
          interestRate = 0;
          interest = 0;
        } else {
          // Non-syariah dengan tier: gunakan interestRate dan adminFeePercent dari tier
          interestRate = matchingTier.interestRate ?? product.interestRate ?? 0;
          interest = amount * (interestRate / 100);
          
          adminFeePercent = matchingTier.adminFeePercent ?? product.adminFeePercent ?? 0;
          if (adminFeePercent > 0) {
            adminFee = amount * (adminFeePercent / 100);
          }
          // Juga cek adminFee fixed dari tier
          if (matchingTier.adminFee != null && matchingTier.adminFee! > 0) {
            adminFee += matchingTier.adminFee!;
          }
        }
      }
    } else {
      // Produk tanpa tier: gunakan rate dari produk langsung
      interestRate = product.getInterestRateForAmount(amount);
      interest = amount * (interestRate / 100);
      
      adminFeePercent = product.getAdminFeePercentForAmount(amount);
      if (adminFeePercent > 0) {
        adminFee = amount * (adminFeePercent / 100);
      }
      if (product.adminFeeFixed != null && product.adminFeeFixed! > 0) {
        adminFee += product.adminFeeFixed!;
      }
    }
    
    // Calculate totals
    final totalDeduction = adminFee + interest;
    final cashReceived = amount - totalDeduction;
    final dueDate = DateTime.now().add(Duration(days: effectiveTenor));
    
    developer.log('calculateLocal result: adminFee=$adminFee, interest=$interest, tenor=$effectiveTenor', 
        name: 'CalculatorRepository');
    
    return CalculateResultModel(
      loanAmount: amount,
      adminFee: adminFee,
      adminFeePercent: adminFeePercent,
      interest: interest,
      interestRate: interestRate,
      totalDeduction: totalDeduction,
      cashReceived: cashReceived,
      tenor: effectiveTenor,
      dueDate: dueDate,
      productName: product.name,
      note: product.isSharia 
          ? 'Pembiayaan syariah dengan akad sesuai ketentuan syariah.'
          : 'Nilai aktual dapat berbeda tergantung hasil taksiran.',
    );
  }
}
