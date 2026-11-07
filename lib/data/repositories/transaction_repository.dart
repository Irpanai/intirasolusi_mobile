import '../datasources/remote/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final TransactionRemoteDataSource _remoteDataSource;

  TransactionRepository({TransactionRemoteDataSource? remoteDataSource})
      : _remoteDataSource =
            remoteDataSource ?? TransactionRemoteDataSourceImpl();

  Future<List<TransactionModel>> getTransactions({
    int? page,
    int? perPage,
    String? status,
  }) async {
    return await _remoteDataSource.getTransactions(
      page: page,
      perPage: perPage,
      status: status,
    );
  }

  Future<TransactionDetailModel> getTransactionDetail(String code) async {
    return await _remoteDataSource.getTransactionDetail(code);
  }

  Future<List<TransactionHistoryModel>> getTransactionHistory(
      String code) async {
    return await _remoteDataSource.getTransactionHistory(code);
  }
}
