import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../core/errors/exceptions.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  AuthLogin({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegister extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String? nik;
  final File? ktpImage;

  AuthRegister({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.nik,
    this.ktpImage,
  });

  @override
  List<Object?> get props => [name, email, phone, password, nik, ktpImage];
}

class AuthRegisterWithKtp extends AuthEvent {
  final String email;
  final String password;
  final File ktpImage;
  final File selfieImage;
  final String nik;
  final String name;
  final String? birthPlace;
  final String? birthDate;
  final String gender;
  final String address;
  final String? rtRw;
  final String? village;
  final String? district;
  final String? city;
  final String? province;
  final String? religion;
  final String? maritalStatus;
  final String? occupation;
  final String? phone;

  AuthRegisterWithKtp({
    required this.email,
    required this.password,
    required this.ktpImage,
    required this.selfieImage,
    required this.nik,
    required this.name,
    this.birthPlace,
    this.birthDate,
    required this.gender,
    required this.address,
    this.rtRw,
    this.village,
    this.district,
    this.city,
    this.province,
    this.religion,
    this.maritalStatus,
    this.occupation,
    this.phone,
  });

  @override
  List<Object?> get props => [
        email, password, ktpImage, selfieImage, nik, name,
        birthPlace, birthDate, gender, address, rtRw,
        village, district, city, province, religion,
        maritalStatus, occupation, phone,
      ];
}

class AuthLogout extends AuthEvent {}

class AuthLoadProfile extends AuthEvent {}

class AuthUpdateProfile extends AuthEvent {
  final Map<String, dynamic> data;

  AuthUpdateProfile({required this.data});

  @override
  List<Object?> get props => [data];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final bool requiresProfileCompletion;

  AuthAuthenticated({
    required this.user,
    this.requiresProfileCompletion = false,
  });

  @override
  List<Object?> get props => [user, requiresProfileCompletion];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  final Map<String, List<String>>? errors;

  AuthError({required this.message, this.errors});

  @override
  List<Object?> get props => [message, errors];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthRegisterWithKtp>(_onRegisterWithKtp);
    on<AuthLogout>(_onLogout);
    on<AuthLoadProfile>(_onLoadProfile);
    on<AuthUpdateProfile>(_onUpdateProfile);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final hasToken = await _authRepository.hasToken();

      if (hasToken) {
        try {
          final user = await _authRepository.getCurrentUser();
          emit(AuthAuthenticated(
            user: user,
            requiresProfileCompletion: !(user.customer?.isProfileComplete ?? false),
          ));
        } catch (_) {
          // If network error occurred, try fallback to cached user
          final cachedUser = await _authRepository.getCachedUser();
          if (cachedUser != null) {
            emit(AuthAuthenticated(
              user: cachedUser,
              requiresProfileCompletion: !(cachedUser.customer?.isProfileComplete ?? false),
            ));
          } else {
            emit(AuthUnauthenticated());
          }
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLogin event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authRepository.login(
      email: event.email,
      password: event.password,
    );

    if (result.success && result.user != null) {
      emit(AuthAuthenticated(
        user: result.user!,
        requiresProfileCompletion: result.requiresProfileCompletion,
      ));
    } else {
      emit(AuthError(
        message: result.message,
        errors: result.errors,
      ));
    }
  }

  Future<void> _onRegister(
    AuthRegister event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authRepository.register(
      name: event.name,
      email: event.email,
      phone: event.phone,
      password: event.password,
      nik: event.nik,
      ktpImage: event.ktpImage,
    );

    if (result.success && result.user != null) {
      emit(AuthAuthenticated(
        user: result.user!,
        requiresProfileCompletion: true,
      ));
    } else {
      emit(AuthError(
        message: result.message,
        errors: result.errors,
      ));
    }
  }

  Future<void> _onRegisterWithKtp(
    AuthRegisterWithKtp event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authRepository.registerWithKtp(
      email: event.email,
      password: event.password,
      ktpImage: event.ktpImage,
      selfieImage: event.selfieImage,
      nik: event.nik,
      name: event.name,
      birthPlace: event.birthPlace ?? '',
      birthDate: event.birthDate ?? '',
      gender: event.gender,
      address: event.address,
      rt: event.rtRw?.split('/').firstOrNull ?? '',
      rw: event.rtRw?.split('/').lastOrNull ?? '',
      kelurahan: event.village ?? '',
      kecamatan: event.district ?? '',
      religion: event.religion,
      maritalStatus: event.maritalStatus,
      occupation: event.occupation,
      phone: event.phone,
    );

    if (result.success && result.user != null) {
      emit(AuthAuthenticated(
        user: result.user!,
        requiresProfileCompletion: false,
      ));
    } else {
      emit(AuthError(
        message: result.message,
        errors: result.errors,
      ));
    }
  }

  Future<void> _onLogout(
    AuthLogout event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoadProfile(
    AuthLoadProfile event,
    Emitter<AuthState> emit,
  ) async {
    // Don't emit loading state to avoid UI flicker
    try {
      // Use getCurrentUser which calls /me endpoint with customer data
      final user = await _authRepository.getCurrentUser();
      emit(AuthAuthenticated(
        user: user,
        requiresProfileCompletion: !(user.customer?.isProfileComplete ?? false),
      ));
    } catch (e) {
      // Keep current state if profile load fails
      // User can retry manually
    }
  }

  Future<void> _onUpdateProfile(
    AuthUpdateProfile event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await _authRepository.updateProfile(event.data);
      emit(AuthAuthenticated(
        user: user,
        requiresProfileCompletion: !(user.customer?.isProfileComplete ?? false),
      ));
    } catch (e) {
      final message = e is ServerException ? e.message : 'Gagal update profil';
      emit(AuthError(message: message));
    }
  }
}
