import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/repositories/pawn_request_repository.dart';
import '../../../data/models/pawn_request_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/branch_model.dart';

// Events
abstract class PawnRequestEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFormData extends PawnRequestEvent {}

class PawnRequestLoadList extends PawnRequestEvent {
  final String? status;
  final int page;

  PawnRequestLoadList({this.status, this.page = 1});

  @override
  List<Object?> get props => [status, page];
}

class PawnRequestLoadDetail extends PawnRequestEvent {
  final String code;

  PawnRequestLoadDetail({required this.code});

  @override
  List<Object?> get props => [code];
}

class SubmitPawnRequest extends PawnRequestEvent {
  final int productId;
  final int? categoryId;
  final String collateralName;
  final String? collateralDescription;
  final double? estimatedValue;
  final double loanAmount;
  final int? preferredBranchId;
  final String? notes;
  final List<File> photos;

  SubmitPawnRequest({
    required this.productId,
    this.categoryId,
    required this.collateralName,
    this.collateralDescription,
    this.estimatedValue,
    required this.loanAmount,
    this.preferredBranchId,
    this.notes,
    required this.photos,
  });

  @override
  List<Object?> get props => [
        productId,
        categoryId,
        collateralName,
        collateralDescription,
        estimatedValue,
        loanAmount,
        preferredBranchId,
        notes,
        photos,
      ];
}

class CancelPawnRequest extends PawnRequestEvent {
  final String code;

  CancelPawnRequest({required this.code});

  @override
  List<Object?> get props => [code];
}

// States
abstract class PawnRequestState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PawnRequestInitial extends PawnRequestState {}

class PawnRequestLoading extends PawnRequestState {}

class PawnRequestFormLoading extends PawnRequestState {}

class PawnRequestFormLoaded extends PawnRequestState {
  final List<ProductModel> products;
  final List<CollateralCategoryModel> categories;
  final List<BranchModel> branches;

  PawnRequestFormLoaded({
    required this.products,
    required this.categories,
    required this.branches,
  });

  @override
  List<Object?> get props => [products, categories, branches];
}

class PawnRequestListLoaded extends PawnRequestState {
  final List<PawnRequestModel> requests;
  final bool hasMore;

  PawnRequestListLoaded({
    required this.requests,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [requests, hasMore];
}

class PawnRequestDetailLoaded extends PawnRequestState {
  final PawnRequestModel request;

  PawnRequestDetailLoaded({required this.request});

  @override
  List<Object?> get props => [request];
}

class PawnRequestSubmitSuccess extends PawnRequestState {
  final String requestCode;

  PawnRequestSubmitSuccess({required this.requestCode});

  @override
  List<Object?> get props => [requestCode];
}

class PawnRequestCancelSuccess extends PawnRequestState {}

class PawnRequestError extends PawnRequestState {
  final String message;

  PawnRequestError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class PawnRequestBloc extends Bloc<PawnRequestEvent, PawnRequestState> {
  final PawnRequestRepository _repository;

  PawnRequestBloc({PawnRequestRepository? repository})
      : _repository = repository ?? PawnRequestRepository(),
        super(PawnRequestInitial()) {
    on<LoadFormData>(_onLoadFormData);
    on<PawnRequestLoadList>(_onLoadList);
    on<PawnRequestLoadDetail>(_onLoadDetail);
    on<SubmitPawnRequest>(_onSubmit);
    on<CancelPawnRequest>(_onCancel);
  }

  Future<void> _onLoadFormData(
    LoadFormData event,
    Emitter<PawnRequestState> emit,
  ) async {
    emit(PawnRequestFormLoading());

    try {
      final products = await _repository.getProducts();
      final categories = await _repository.getCategories();
      final branches = await _repository.getBranches();

      emit(PawnRequestFormLoaded(
        products: products,
        categories: categories,
        branches: branches,
      ));
    } catch (e) {
      emit(PawnRequestError(message: 'Gagal memuat data form'));
    }
  }

  Future<void> _onLoadList(
    PawnRequestLoadList event,
    Emitter<PawnRequestState> emit,
  ) async {
    emit(PawnRequestLoading());

    try {
      final requests = await _repository.getPawnRequests(
        page: event.page,
        status: event.status,
      );
      emit(PawnRequestListLoaded(
        requests: requests,
        hasMore: requests.length >= 10,
      ));
    } catch (e) {
      emit(PawnRequestError(message: 'Gagal memuat pengajuan'));
    }
  }

  Future<void> _onLoadDetail(
    PawnRequestLoadDetail event,
    Emitter<PawnRequestState> emit,
  ) async {
    emit(PawnRequestLoading());

    try {
      final request = await _repository.getPawnRequestDetail(event.code);
      emit(PawnRequestDetailLoaded(request: request));
    } catch (e) {
      emit(PawnRequestError(message: 'Gagal memuat detail pengajuan'));
    }
  }

  Future<void> _onSubmit(
    SubmitPawnRequest event,
    Emitter<PawnRequestState> emit,
  ) async {
    emit(PawnRequestLoading());

    try {
      final request = await _repository.createPawnRequest(
        productId: event.productId,
        categoryId: event.categoryId,
        collateralName: event.collateralName,
        collateralDescription: event.collateralDescription,
        estimatedValue: event.estimatedValue,
        loanAmount: event.loanAmount,
        preferredBranchId: event.preferredBranchId,
        notes: event.notes,
        photos: event.photos,
      );
      emit(PawnRequestSubmitSuccess(requestCode: request.code));
    } on ServerException catch (e) {
      emit(PawnRequestError(message: e.message));
    } catch (e) {
      emit(PawnRequestError(message: 'Gagal membuat pengajuan'));
    }
  }

  Future<void> _onCancel(
    CancelPawnRequest event,
    Emitter<PawnRequestState> emit,
  ) async {
    emit(PawnRequestLoading());

    try {
      await _repository.cancelPawnRequest(event.code);
      emit(PawnRequestCancelSuccess());
    } catch (e) {
      emit(PawnRequestError(message: 'Gagal membatalkan pengajuan'));
    }
  }
}
