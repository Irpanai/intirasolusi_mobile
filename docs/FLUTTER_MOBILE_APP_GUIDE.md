# 📱 Intira Customer Mobile App - Flutter Development Guide

Panduan lengkap untuk pengembangan aplikasi Flutter Customer Intira yang terintegrasi dengan sistem backend Laravel.

---

## 📋 Daftar Isi

1. [Informasi Umum](#informasi-umum)
2. [Tech Stack & Dependencies](#tech-stack--dependencies)
3. [Project Structure](#project-structure)
4. [Architecture Pattern](#architecture-pattern)
5. [Screens & Navigation](#screens--navigation)
6. [API Integration](#api-integration)
7. [Authentication Flow](#authentication-flow)
8. [State Management](#state-management)
9. [UI/UX Guidelines](#uiux-guidelines)
10. [Implementasi Lengkap](#implementasi-lengkap)
11. [Testing](#testing)
12. [Build & Deployment](#build--deployment)

---

## 🌐 Informasi Umum

| Item | Keterangan |
|------|------------|
| **Nama Aplikasi** | Intira Mobile |
| **Platform** | Android & iOS |
| **Min SDK Android** | 21 (Android 5.0) |
| **Min iOS Version** | 12.0 |
| **Flutter Version** | ^3.19.0 |
| **Dart Version** | ^3.3.0 |
| **API Base URL (Dev)** | `http://intira.test/api` |
| **API Base URL (Prod)** | `https://intirasolusi.id/api` |

---

## 📦 Tech Stack & Dependencies

### pubspec.yaml

```yaml
name: intira_customer
description: Intira Customer Mobile App - Aplikasi Gadai Online

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Core
  cupertino_icons: ^1.0.6
  
  # State Management
  flutter_bloc: ^8.1.5
  equatable: ^2.0.5
  
  # Network & API
  dio: ^5.4.1
  retrofit: ^4.1.0
  json_annotation: ^4.8.1
  connectivity_plus: ^6.0.2
  
  # Local Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # UI Components
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_spinkit: ^5.2.1
  
  # Forms & Validation
  flutter_form_builder: ^9.2.1
  form_builder_validators: ^9.1.0
  
  # Image & Camera
  image_picker: ^1.0.7
  image_cropper: ^5.0.1
  photo_view: ^0.14.0
  
  # Location
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  
  # Utilities
  intl: ^0.19.0
  url_launcher: ^6.2.5
  package_info_plus: ^5.0.1
  device_info_plus: ^10.1.0
  permission_handler: ^11.3.0
  
  # Notifications
  flutter_local_notifications: ^17.0.0
  firebase_core: ^2.27.1
  firebase_messaging: ^14.7.20
  
  # Analytics
  firebase_analytics: ^10.8.10

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  
  # Code Generation
  build_runner: ^2.4.9
  retrofit_generator: ^8.1.0
  json_serializable: ^6.7.1
  hive_generator: ^2.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
    
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
        - asset: assets/fonts/Poppins-Medium.ttf
          weight: 500
        - asset: assets/fonts/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── app.dart
├── injection.dart
│
├── config/
│   ├── app_config.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   └── routes/
│       ├── app_routes.dart
│       └── route_generator.dart
│
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart
│   │   ├── app_constants.dart
│   │   └── storage_keys.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_interceptor.dart
│   │   └── network_info.dart
│   ├── utils/
│   │   ├── formatters.dart
│   │   ├── validators.dart
│   │   └── helpers.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── loading_widget.dart
│       └── error_widget.dart
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── customer_model.dart
│   │   ├── transaction_model.dart
│   │   ├── pawn_request_model.dart
│   │   ├── branch_model.dart
│   │   ├── product_model.dart
│   │   └── location_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── profile_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── pawn_request_repository.dart
│   │   └── branch_repository.dart
│   └── datasources/
│       ├── remote/
│       │   ├── auth_remote_datasource.dart
│       │   ├── profile_remote_datasource.dart
│       │   └── transaction_remote_datasource.dart
│       └── local/
│           ├── auth_local_datasource.dart
│           └── cache_datasource.dart
│
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   ├── customer.dart
│   │   └── transaction.dart
│   ├── repositories/
│   │   ├── i_auth_repository.dart
│   │   └── i_transaction_repository.dart
│   └── usecases/
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   ├── register_usecase.dart
│       │   └── logout_usecase.dart
│       └── transaction/
│           ├── get_transactions_usecase.dart
│           └── get_transaction_detail_usecase.dart
│
├── presentation/
│   ├── blocs/
│   │   ├── auth/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_bloc.dart
│   │   ├── transaction/
│   │   │   └── transaction_bloc.dart
│   │   └── pawn_request/
│   │       └── pawn_request_bloc.dart
│   │
│   └── screens/
│       ├── splash/
│       │   └── splash_screen.dart
│       ├── auth/
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   └── complete_profile_screen.dart
│       ├── dashboard/
│       │   └── dashboard_screen.dart
│       ├── transaction/
│       │   ├── transaction_list_screen.dart
│       │   └── transaction_detail_screen.dart
│       ├── pawn_request/
│       │   ├── pawn_request_list_screen.dart
│       │   ├── pawn_request_create_screen.dart
│       │   └── pawn_request_detail_screen.dart
│       ├── calculator/
│       │   └── calculator_screen.dart
│       ├── branch/
│       │   ├── branch_list_screen.dart
│       │   └── branch_detail_screen.dart
│       └── profile/
│           ├── profile_screen.dart
│           └── edit_profile_screen.dart
│
└── l10n/
    ├── app_id.arb
    └── app_en.arb
```

---

## 🏗️ Architecture Pattern

Aplikasi menggunakan **Clean Architecture** dengan **BLoC Pattern** untuk state management.

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐ │
│  │   Screens   │ ◄──│    BLoCs    │ ◄──│     Use Cases       │ │
│  │   (Views)   │    │   (State)   │    │  (Business Logic)   │ │
│  └─────────────┘    └─────────────┘    └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                               │
│  ┌─────────────────────┐    ┌───────────────────────────────┐  │
│  │      Entities       │    │     Repository Interfaces     │  │
│  │  (Business Models)  │    │        (Contracts)            │  │
│  └─────────────────────┘    └───────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │     Models      │  │  Repositories   │  │   DataSources   │ │
│  │  (API Models)   │  │ (Implementation)│  │  (Remote/Local) │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📱 Screens & Navigation

### Daftar Screen

| No | Screen | Route | Auth Required | Description |
|----|--------|-------|---------------|-------------|
| 1 | Splash | `/` | ❌ | Loading awal, check auth status |
| 2 | Welcome | `/welcome` | ❌ | Halaman selamat datang |
| 3 | Login | `/login` | ❌ | Login dengan email & password |
| 4 | Register | `/register` | ❌ | Registrasi akun baru |
| 5 | Complete Profile | `/complete-profile` | ✅ | Lengkapi data profil |
| 6 | Dashboard | `/dashboard` | ✅ | Halaman utama |
| 7 | Calculator | `/calculator` | ❌ | Kalkulator pinjaman |
| 8 | Pawn Request List | `/pawn-requests` | ✅ | Daftar pengajuan |
| 9 | Create Pawn Request | `/pawn-requests/create` | ✅ | Buat pengajuan baru |
| 10 | Pawn Request Detail | `/pawn-requests/:code` | ✅ | Detail pengajuan |
| 11 | Transaction List | `/transactions` | ✅ | Daftar transaksi |
| 12 | Transaction Detail | `/transactions/:code` | ✅ | Detail transaksi |
| 13 | Branch List | `/branches` | ❌ | Daftar cabang |
| 14 | Branch Detail | `/branches/:code` | ❌ | Detail cabang |
| 15 | Profile | `/profile` | ✅ | Profil customer |
| 16 | Edit Profile | `/profile/edit` | ✅ | Edit profil |

### Navigation Flow

```
                    ┌─────────────┐
                    │   Splash    │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
       Token Exists?            No Token
              │                         │
              ▼                         ▼
       ┌─────────────┐         ┌─────────────┐
       │   Dashboard │         │   Welcome   │
       └─────────────┘         └──────┬──────┘
                                      │
                          ┌───────────┴───────────┐
                          │                       │
                          ▼                       ▼
                   ┌─────────────┐         ┌─────────────┐
                   │    Login    │         │  Register   │
                   └──────┬──────┘         └──────┬──────┘
                          │                       │
                          │              ┌────────┴────────┐
                          │              │                 │
                          │              ▼                 │
                          │     ┌────────────────┐        │
                          │     │ Complete       │        │
                          │     │ Profile        │        │
                          │     └───────┬────────┘        │
                          │             │                 │
                          └─────────────┼─────────────────┘
                                        │
                                        ▼
                               ┌─────────────┐
                               │  Dashboard  │
                               └─────────────┘
```

---

## 🔌 API Integration

### 1. API Client Setup

**lib/core/network/api_client.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';
import '../constants/storage_keys.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add token to protected routes
        final token = await _storage.read(key: StorageKeys.authToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired - clear storage and redirect to login
          await _storage.deleteAll();
          // Navigate to login (use navigation service)
        }
        return handler.next(error);
      },
    ));
    
    // Add logging in debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
  
  Dio get dio => _dio;
  
  // Helper methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get(path, queryParameters: queryParams);
  }
  
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }
  
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }
  
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
  
  // Multipart upload
  Future<Response> uploadFiles(String path, {
    required List<File> files,
    required String fieldName,
    Map<String, dynamic>? extraData,
  }) async {
    final formData = FormData();
    
    for (var file in files) {
      formData.files.add(MapEntry(
        fieldName,
        await MultipartFile.fromFile(file.path),
      ));
    }
    
    if (extraData != null) {
      extraData.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }
    
    return _dio.post(path, data: formData);
  }
}
```

### 2. API Endpoints Constants

**lib/core/constants/api_endpoints.dart**

```dart
class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'http://intira.test/api';
  // static const String baseUrl = 'https://intirasolusi.id/api'; // Production
  
  // Auth
  static const String register = '/register';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
  
  // Dashboard
  static const String dashboard = '/dashboard';
  
  // Profile
  static const String profile = '/profile';
  
  // Calculator
  static const String calculatorProducts = '/calculator/products';
  static String calculatorTiers(int productId) => '/calculator/products/$productId/tiers';
  static const String calculatorCalculate = '/calculator/calculate';
  static const String collateralCategories = '/calculator/collateral-categories';
  static const String productCategories = '/calculator/product-categories';
  
  // Branches
  static const String branches = '/branches';
  static const String branchesCities = '/branches/cities';
  static const String branchesProvinces = '/branches/provinces';
  static String branchDetail(String code) => '/branches/$code';
  static const String branchesNearby = '/branches/nearby';
  
  // Locations
  static const String provinces = '/locations/provinces';
  static String cities(String provinceCode) => '/locations/cities/$provinceCode';
  static String districts(String cityCode) => '/locations/districts/$cityCode';
  static String villages(String districtCode) => '/locations/villages/$districtCode';
  
  // Pawn Requests
  static const String pawnRequests = '/pawn-requests';
  static String pawnRequestDetail(String code) => '/pawn-requests/$code';
  static String pawnRequestCancel(String code) => '/pawn-requests/$code/cancel';
  static String pawnRequestPhotos(String code) => '/pawn-requests/$code/photos';
  
  // Transactions
  static const String transactions = '/transactions';
  static String transactionDetail(String code) => '/transactions/$code';
  static String transactionHistory(String code) => '/transactions/$code/history';
}
```

---

## 🔐 Authentication Flow

### Auth BLoC

**lib/presentation/blocs/auth/auth_bloc.dart**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

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
  
  AuthRegister({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
  
  @override
  List<Object?> get props => [name, email, phone, password];
}

class AuthLogout extends AuthEvent {}

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
  
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
  }
  
  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final hasToken = await _authRepository.hasToken();
      
      if (hasToken) {
        final user = await _authRepository.getCurrentUser();
        emit(AuthAuthenticated(
          user: user,
          requiresProfileCompletion: !user.customer!.isProfileComplete,
        ));
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
    
    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      
      if (response.success) {
        emit(AuthAuthenticated(
          user: response.data!.user,
          requiresProfileCompletion: response.data!.requiresProfileCompletion,
        ));
      } else {
        emit(AuthError(message: response.message));
      }
    } catch (e) {
      emit(AuthError(message: 'Login gagal. Silakan coba lagi.'));
    }
  }
  
  Future<void> _onRegister(
    AuthRegister event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final response = await _authRepository.register(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
      );
      
      if (response.success) {
        emit(AuthAuthenticated(
          user: response.data!.user,
          requiresProfileCompletion: true,
        ));
      } else {
        emit(AuthError(
          message: response.message,
          errors: response.errors,
        ));
      }
    } catch (e) {
      emit(AuthError(message: 'Registrasi gagal. Silakan coba lagi.'));
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
}
```

---

## 📊 State Management

### Dashboard BLoC

**lib/presentation/blocs/dashboard/dashboard_bloc.dart**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/dashboard_repository.dart';

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

// Data Model
class DashboardData {
  final CustomerInfo customer;
  final DashboardStats stats;
  final List<RecentRequest> recentRequests;
  final List<ActiveTransaction> activeTransactions;
  final List<DashboardAlert> alerts;
  
  DashboardData({
    required this.customer,
    required this.stats,
    required this.recentRequests,
    required this.activeTransactions,
    required this.alerts,
  });
  
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      customer: CustomerInfo.fromJson(json['customer']),
      stats: DashboardStats.fromJson(json['stats']),
      recentRequests: (json['recent_requests'] as List)
          .map((e) => RecentRequest.fromJson(e))
          .toList(),
      activeTransactions: (json['active_transactions'] as List)
          .map((e) => ActiveTransaction.fromJson(e))
          .toList(),
      alerts: (json['alerts'] as List)
          .map((e) => DashboardAlert.fromJson(e))
          .toList(),
    );
  }
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;
  
  DashboardBloc({required DashboardRepository repository})
      : _repository = repository,
        super(DashboardInitial()) {
    on<DashboardLoad>(_onLoad);
    on<DashboardRefresh>(_onRefresh);
  }
  
  Future<void> _onLoad(
    DashboardLoad event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    await _loadDashboard(emit);
  }
  
  Future<void> _onRefresh(
    DashboardRefresh event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadDashboard(emit);
  }
  
  Future<void> _loadDashboard(Emitter<DashboardState> emit) async {
    try {
      final data = await _repository.getDashboard();
      emit(DashboardLoaded(data: data));
    } catch (e) {
      emit(DashboardError(message: 'Gagal memuat dashboard'));
    }
  }
}
```

---

## 🎨 UI/UX Guidelines

### Theme Configuration

**lib/config/theme/app_colors.dart**

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  
  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  
  // Transaction Status Colors
  static const Color statusActive = Color(0xFF22C55E);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusExtended = Color(0xFF3B82F6);
  static const Color statusCompleted = Color(0xFF8B5CF6);
  static const Color statusPending = Color(0xFFF59E0B);
}
```

**lib/config/theme/app_theme.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../documentations/app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      
      // Text Theme
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
```

---

## 💻 Implementasi Lengkap

### 1. Login Screen

**lib/presentation/screens/auth/login_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthLogin(
        email: _emailController.text,
        password: _passwordController.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.requiresProfileCompletion) {
              Navigator.pushReplacementNamed(context, '/complete-profile');
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'Selamat Datang!',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk ke akun Anda untuk melanjutkan',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Email Field
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Masukkan email Anda',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Email wajib diisi';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Masukkan password Anda',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Password wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Login Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return AppButton(
                        onPressed: state is AuthLoading ? null : _onSubmit,
                        isLoading: state is AuthLoading,
                        text: 'Masuk',
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Daftar',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 2. Dashboard Screen

**lib/presentation/screens/dashboard/dashboard_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../documentations/widgets/stats_card.dart';
import '../documentations/widgets/recent_request_card.dart';
import '../documentations/widgets/active_transaction_card.dart';
import '../documentations/widgets/alert_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoad());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<DashboardBloc>().add(DashboardLoad()),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          
          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(DashboardRefresh());
              },
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${state.data.customer.name}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Selamat datang kembali!',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_outline),
                        onPressed: () => Navigator.pushNamed(context, '/profile'),
                      ),
                    ],
                  ),
                  
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Profile Incomplete Banner
                        if (!state.data.customer.isProfileComplete)
                          _buildProfileBanner(context),
                        
                        // Alerts
                        ...state.data.alerts.map((alert) => AlertBanner(alert: alert)),
                        
                        // Stats
                        const SizedBox(height: 16),
                        Text(
                          'Ringkasan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildStatsGrid(state.data.stats),
                        
                        // Quick Actions
                        const SizedBox(height: 24),
                        Text(
                          'Menu Cepat',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActions(context),
                        
                        // Active Transactions
                        if (state.data.activeTransactions.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            context,
                            'Transaksi Aktif',
                            () => Navigator.pushNamed(context, '/transactions'),
                          ),
                          const SizedBox(height: 12),
                          ...state.data.activeTransactions.map(
                            (tx) => ActiveTransactionCard(transaction: tx),
                          ),
                        ],
                        
                        // Recent Requests
                        if (state.data.recentRequests.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            context,
                            'Pengajuan Terbaru',
                            () => Navigator.pushNamed(context, '/pawn-requests'),
                          ),
                          const SizedBox(height: 12),
                          ...state.data.recentRequests.map(
                            (req) => RecentRequestCard(request: req),
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
      
      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Kalkulator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Ajukan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Cabang',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushNamed(context, '/calculator');
              break;
            case 2:
              Navigator.pushNamed(context, '/pawn-requests/create');
              break;
            case 3:
              Navigator.pushNamed(context, '/transactions');
              break;
            case 4:
              Navigator.pushNamed(context, '/branches');
              break;
          }
        },
      ),
    );
  }
  
  Widget _buildProfileBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil Belum Lengkap',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Lengkapi profil untuk mengajukan gadai',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/complete-profile'),
            child: const Text('Lengkapi'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsGrid(DashboardStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatsCard(
          icon: Icons.receipt_long,
          label: 'Transaksi Aktif',
          value: stats.activeTransactions.toString(),
          color: AppColors.primary,
        ),
        StatsCard(
          icon: Icons.pending_actions,
          label: 'Pengajuan Pending',
          value: stats.pendingRequests.toString(),
          color: AppColors.warning,
        ),
        StatsCard(
          icon: Icons.account_balance_wallet,
          label: 'Total Pinjaman',
          value: stats.totalLoanFormatted,
          color: AppColors.success,
        ),
        StatsCard(
          icon: Icons.warning,
          label: 'Jatuh Tempo',
          value: stats.overdueTransactions.toString(),
          color: AppColors.error,
        ),
      ],
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.calculate,
            label: 'Hitung\nPinjaman',
            onTap: () => Navigator.pushNamed(context, '/calculator'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_box,
            label: 'Ajukan\nGadai',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/pawn-requests/create'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.location_on,
            label: 'Cari\nCabang',
            onTap: () => Navigator.pushNamed(context, '/branches'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onViewAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton(
          onPressed: onViewAll,
          child: const Text('Lihat Semua'),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Create Pawn Request Screen

**lib/presentation/screens/pawn_request/pawn_request_create_screen.dart**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/pawn_request/pawn_request_bloc.dart';
import '../../../config/theme/app_colors.dart';

class PawnRequestCreateScreen extends StatefulWidget {
  const PawnRequestCreateScreen({super.key});

  @override
  State<PawnRequestCreateScreen> createState() => _PawnRequestCreateScreenState();
}

class _PawnRequestCreateScreenState extends State<PawnRequestCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _collateralNameController = TextEditingController();
  final _collateralDescController = TextEditingController();
  final _estimatedValueController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _notesController = TextEditingController();
  
  int? _selectedProductId;
  int? _selectedCategoryId;
  int? _selectedBranchId;
  List<File> _photos = [];
  
  final _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    context.read<PawnRequestBloc>().add(LoadFormData());
  }
  
  Future<void> _pickImage() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 foto')),
      );
      return;
    }
    
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _photos.add(File(image.path));
      });
    }
  }
  
  Future<void> _pickFromGallery() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 foto')),
      );
      return;
    }
    
    final images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    final remaining = 5 - _photos.length;
    final toAdd = images.take(remaining).map((e) => File(e.path)).toList();
    
    setState(() {
      _photos.addAll(toAdd);
    });
  }
  
  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }
  
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 1 foto barang jaminan')),
      );
      return;
    }
    
    context.read<PawnRequestBloc>().add(SubmitPawnRequest(
      productId: _selectedProductId!,
      categoryId: _selectedCategoryId,
      collateralName: _collateralNameController.text,
      collateralDescription: _collateralDescController.text,
      estimatedValue: double.tryParse(_estimatedValueController.text.replaceAll(RegExp(r'[^\d]'), '')),
      loanAmount: double.parse(_loanAmountController.text.replaceAll(RegExp(r'[^\d]'), '')),
      preferredBranchId: _selectedBranchId,
      notes: _notesController.text,
      photos: _photos,
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajukan Gadai Online'),
      ),
      body: BlocConsumer<PawnRequestBloc, PawnRequestState>(
        listener: (context, state) {
          if (state is PawnRequestSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pengajuan berhasil dibuat!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              '/pawn-requests/${state.requestCode}',
            );
          } else if (state is PawnRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PawnRequestFormLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo Section
                  _buildPhotoSection(),
                  const SizedBox(height: 24),
                  
                  // Product Selection
                  _buildProductDropdown(state),
                  const SizedBox(height: 16),
                  
                  // Category Selection
                  _buildCategoryDropdown(state),
                  const SizedBox(height: 16),
                  
                  // Collateral Name
                  TextFormField(
                    controller: _collateralNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Barang Jaminan *',
                      hintText: 'Contoh: Laptop ASUS ROG',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Nama barang wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _collateralDescController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Barang',
                      hintText: 'Kondisi, kelengkapan, dll',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Estimated Value
                  TextFormField(
                    controller: _estimatedValueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Estimasi Nilai Barang',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Loan Amount
                  TextFormField(
                    controller: _loanAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Pinjaman yang Diinginkan *',
                      prefixText: 'Rp ',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Jumlah pinjaman wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Preferred Branch
                  _buildBranchDropdown(state),
                  const SizedBox(height: 16),
                  
                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Tambahan',
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: state is PawnRequestSubmitting ? null : _submit,
                    child: state is PawnRequestSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Ajukan Sekarang'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Barang Jaminan *',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Min. 1 foto, maks. 5 foto (JPEG/PNG, maks. 5MB)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add Photo Button
              InkWell(
                onTap: () => _showPhotoOptions(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Photos
              ..._photos.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          entry.value,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removePhoto(entry.key),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
  
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductDropdown(PawnRequestState state) {
    final products = state is PawnRequestFormLoaded ? state.products : [];
    
    return DropdownButtonFormField<int>(
      value: _selectedProductId,
      decoration: const InputDecoration(
        labelText: 'Produk Pinjaman *',
      ),
      items: products.map((product) {
        return DropdownMenuItem(
          value: product.id,
          child: Text(product.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedProductId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Pilih produk pinjaman';
        }
        return null;
      },
    );
  }
  
  Widget _buildCategoryDropdown(PawnRequestState state) {
    final categories = state is PawnRequestFormLoaded ? state.categories : [];
    
    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Kategori Barang *',
      ),
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category.id,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Pilih kategori barang';
        }
        return null;
      },
    );
  }
  
  Widget _buildBranchDropdown(PawnRequestState state) {
    final branches = state is PawnRequestFormLoaded ? state.branches : [];
    
    return DropdownButtonFormField<int>(
      value: _selectedBranchId,
      decoration: const InputDecoration(
        labelText: 'Pilih Cabang (Opsional)',
      ),
      items: branches.map((branch) {
        return DropdownMenuItem(
          value: branch.id,
          child: Text(branch.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBranchId = value;
        });
      },
    );
  }
}
```

---

## 🧪 Testing

### Unit Test Example

**test/blocs/auth_bloc_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intira_customer/presentation/blocs/auth/auth_bloc.dart';
import 'package:intira_customer/data/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => LoginResponse(
          success: true,
          message: 'Login berhasil',
          data: LoginData(
            user: UserModel(id: 1, name: 'Test', email: 'test@test.com'),
            requiresProfileCompletion: false,
          ),
        ));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogin(
        email: 'test@test.com',
        password: 'password',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => LoginResponse(
          success: false,
          message: 'Email atau password salah',
        ));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogin(
        email: 'test@test.com',
        password: 'wrong',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );
  });
}
```

---

## 📦 Build & Deployment

### Android Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (untuk Play Store)
flutter build appbundle --release
```

### iOS Build

```bash
# Debug
flutter build ios --debug

# Release (memerlukan Apple Developer account)
flutter build ios --release
flutter build ipa --release
```

### Environment Configuration

**lib/config/app_config.dart**

```dart
enum Environment { development, staging, production }

class AppConfig {
  static Environment environment = Environment.development;
  
  static String get baseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://intira.test/api';
      case Environment.staging:
        return 'https://testing.intirasolusi.id/api';
      case Environment.production:
        return 'https://intirasolusi.id/api';
    }
  }
  
  static void setEnvironment(Environment env) {
    environment = env;
  }
}
```

### Build Commands per Environment

```bash
# Development
flutter run --dart-define=ENV=development

# Staging
flutter build apk --release --dart-define=ENV=staging

# Production
flutter build apk --release --dart-define=ENV=production
flutter build appbundle --release --dart-define=ENV=production
```

---

## 📞 Support

Jika ada pertanyaan atau kendala:
- Email: developer@intira.co.id
- WhatsApp: 08xxxxxxxxxx

---

## 🔄 Changelog

### v1.0.0 (Februari 2026)
- Initial release
- Authentication (Login, Register, Complete Profile)
- Dashboard dengan statistik
- Kalkulator pinjaman
- Pengajuan gadai online
- Lihat transaksi dan riwayat
- Cari cabang terdekat
- Push notifications

---

**Dokumen ini dipelihara oleh Tim Pengembangan Intira**
