import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getTransactions({
    int? page,
    int? perPage,
    String? status,
  });

  Future<TransactionDetailModel> getTransactionDetail(String code);

  Future<List<TransactionHistoryModel>> getTransactionHistory(String code);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient _apiClient;

  TransactionRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<TransactionModel>> getTransactions({
    int? page,
    int? perPage,
    String? status,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.transactions,
        queryParams: {
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
          if (status != null) 'status': status,
        },
      );

      print('Transaction API Response Status: ${response.statusCode}');
      print('Transaction API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle Laravel paginated response: {data: {data: [...], current_page: 1, ...}}
        final responseData = response.data['data'];
        print('Response data type: ${responseData.runtimeType}');
        print('Response data content: $responseData');
        
        final List<dynamic> data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          // Paginated response
          data = responseData['data'] as List<dynamic>;
        } else if (responseData is List) {
          // Non-paginated response
          data = responseData;
        } else {
          data = [];
        }
        print('Parsed transactions count: ${data.length}');
        return data.map((e) => TransactionModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil data transaksi',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      print('Transaction Datasource Error: $e');
      print('StackTrace: $stackTrace');
      if (e is ServerException) rethrow;
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.message;
        print('Dio Error: statusCode=$statusCode, message=$message');
        if (statusCode == 401) {
          throw ServerException(message: 'Sesi habis, silakan login ulang', statusCode: 401);
        } else if (statusCode == 403) {
          throw ServerException(message: 'Akses ditolak', statusCode: 403);
        } else if (statusCode == 404) {
          throw ServerException(message: 'Data tidak ditemukan', statusCode: 404);
        } else if (statusCode == 500) {
          throw ServerException(message: 'Server error, coba lagi nanti', statusCode: 500);
        }
        throw ServerException(message: 'Gagal memuat: $message', statusCode: statusCode);
      }
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  @override
  Future<TransactionDetailModel> getTransactionDetail(String code) async {
    try {
      print('Loading transaction detail for code: $code');
      final response = await _apiClient.get(
        ApiEndpoints.transactionDetail(code),
      );

      print('Transaction Detail API Response Status: ${response.statusCode}');
      print('Transaction Detail API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        print('Detail data type: ${data.runtimeType}');
        print('Detail data content: $data');
        return TransactionDetailModel.fromJson(data);
      } else {
        throw ServerException(
          message: 'Gagal mengambil detail transaksi',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      print('Transaction Detail Datasource Error: $e');
      print('StackTrace: $stackTrace');
      if (e is ServerException) rethrow;
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.message;
        print('Dio Error: statusCode=$statusCode, message=$message');
        print('Response Data: ${e.response?.data}');
        if (statusCode == 401) {
          throw ServerException(message: 'Sesi habis, silakan login ulang', statusCode: 401);
        } else if (statusCode == 404) {
          throw ServerException(message: 'Transaksi tidak ditemukan', statusCode: 404);
        } else if (statusCode == 500) {
          throw ServerException(message: 'Server error. Coba beberapa saat lagi', statusCode: 500);
        }
        throw ServerException(message: 'Gagal memuat detail: $message', statusCode: statusCode);
      }
      throw ServerException(message: 'Terjadi kesalahan: $e');
    }
  }

  @override
  Future<List<TransactionHistoryModel>> getTransactionHistory(
      String code) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.transactionHistory(code),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => TransactionHistoryModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Gagal mengambil riwayat transaksi',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Terjadi kesalahan');
    }
  }
}
