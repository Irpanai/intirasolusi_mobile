import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/models/transaction_model.dart';

// Events
abstract class TransactionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionLoadList extends TransactionEvent {
  final String? status;
  final int page;

  TransactionLoadList({this.status, this.page = 1});

  @override
  List<Object?> get props => [status, page];
}

class TransactionLoadDetail extends TransactionEvent {
  final String code;

  TransactionLoadDetail({required this.code});

  @override
  List<Object?> get props => [code];
}

class TransactionRefresh extends TransactionEvent {}

// States
abstract class TransactionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionListLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final bool hasMore;

  TransactionListLoaded({
    required this.transactions,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [transactions, hasMore];
}

class TransactionDetailLoaded extends TransactionState {
  final TransactionDetailModel transaction;

  TransactionDetailLoaded({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class TransactionError extends TransactionState {
  final String message;

  TransactionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _repository;

  TransactionBloc({TransactionRepository? repository})
      : _repository = repository ?? TransactionRepository(),
        super(TransactionInitial()) {
    on<TransactionLoadList>(_onLoadList);
    on<TransactionLoadDetail>(_onLoadDetail);
    on<TransactionRefresh>(_onRefresh);
  }

  String? _currentStatus;

  Future<void> _onLoadList(
    TransactionLoadList event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    _currentStatus = event.status;

    try {
      final transactions = await _repository.getTransactions(
        page: event.page,
        status: event.status,
      );
      emit(TransactionListLoaded(
        transactions: transactions,
        hasMore: transactions.length >= 10,
      ));
    } catch (e, stackTrace) {
      print('TransactionBloc Error: $e');
      print('StackTrace: $stackTrace');
      emit(TransactionError(message: 'Gagal memuat transaksi: ${e.toString()}'));
    }
  }

  Future<void> _onLoadDetail(
    TransactionLoadDetail event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    try {
      print('TransactionBloc: Loading detail for code: ${event.code}');
      final transaction = await _repository.getTransactionDetail(event.code);
      print('TransactionBloc: Detail loaded successfully');
      emit(TransactionDetailLoaded(transaction: transaction));
    } catch (e, stackTrace) {
      print('TransactionBloc Detail Error: $e');
      print('StackTrace: $stackTrace');
      emit(TransactionError(message: 'Gagal memuat detail transaksi: ${e.toString()}'));
    }
  }

  Future<void> _onRefresh(
    TransactionRefresh event,
    Emitter<TransactionState> emit,
  ) async {
    add(TransactionLoadList(status: _currentStatus));
  }
}
