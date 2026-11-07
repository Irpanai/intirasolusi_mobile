import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/repositories/auth_repository.dart';

// Events
abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardLoad extends DashboardEvent {}

class DashboardRefresh extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardData data;

  DashboardLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository(),
        super(DashboardInitial()) {
    on<DashboardLoad>(_onLoad);
    on<DashboardRefresh>(_onRefresh);
  }

  Future<void> _onLoad(
    DashboardLoad event,
    Emitter<DashboardState> emit,
  ) async {
    // 1. Instantly emit cached data if available (0ms delay)
    final cached = await _repository.getCachedDashboard();
    if (cached != null) {
      emit(DashboardLoaded(data: cached));
    } else if (state is! DashboardLoaded) {
      // If no dashboard cache yet, create an instant placeholder from cached user
      final cachedUser = await AuthRepository().getCachedUser();
      if (cachedUser != null) {
        emit(DashboardLoaded(
          data: DashboardData.fromUser(
            cachedUser.name,
            cachedUser.customer?.code,
            isProfileComplete: cachedUser.customer?.isProfileComplete ?? false,
          ),
        ));
      } else {
        emit(DashboardLoading());
      }
    }

    // 2. Fetch fresh data from network in background
    await _loadDashboard(emit, forceRefresh: false);
  }

  Future<void> _onRefresh(
    DashboardRefresh event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadDashboard(emit, forceRefresh: true);
  }

  Future<void> _loadDashboard(Emitter<DashboardState> emit, {bool forceRefresh = false}) async {
    try {
      final data = await _repository.getDashboard(forceRefresh: forceRefresh);
      emit(DashboardLoaded(data: data));
    } catch (e) {
      if (state is! DashboardLoaded) {
        emit(DashboardError(message: 'Gagal memuat dashboard: ${e.toString()}'));
      }
    }
  }
}
