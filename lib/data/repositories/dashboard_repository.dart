import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../../core/services/cache_service.dart';

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
      customer: CustomerInfo.fromJson(json['customer'] ?? {}),
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      recentRequests: (json['recent_requests'] as List? ?? [])
          .map((e) => RecentRequest.fromJson(e))
          .toList(),
      activeTransactions: (json['active_transactions'] as List? ?? [])
          .map((e) => ActiveTransaction.fromJson(e))
          .toList(),
      alerts: (json['alerts'] as List? ?? [])
          .map((e) => DashboardAlert.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer': customer.toJson(),
      'stats': stats.toJson(),
      'recent_requests': recentRequests.map((e) => e.toJson()).toList(),
      'active_transactions': activeTransactions.map((e) => e.toJson()).toList(),
      'alerts': alerts.map((e) => e.toJson()).toList(),
    };
  }
}

class CustomerInfo {
  final String name;
  final String? code;
  final bool isProfileComplete;

  CustomerInfo({
    required this.name,
    this.code,
    this.isProfileComplete = false,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name'] ?? '',
      code: json['request_code'],
      isProfileComplete: json['is_profile_complete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'request_code': code,
      'is_profile_complete': isProfileComplete,
    };
  }
}

class DashboardStats {
  final int activeTransactions;
  final int pendingRequests;
  final double totalLoan;
  final int overdueTransactions;

  DashboardStats({
    required this.activeTransactions,
    required this.pendingRequests,
    required this.totalLoan,
    required this.overdueTransactions,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // Safely parse numeric values
    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    double parseDoubleSafe(dynamic value) {
      if (value == null) return 0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }
    
    // Handle nested structure from Laravel API: stats.requests and stats.transactions
    final requests = json['requests'] as Map<String, dynamic>? ?? {};
    final transactions = json['transactions'] as Map<String, dynamic>? ?? {};
    
    return DashboardStats(
      // From transactions nested object
      activeTransactions: parseIntSafe(transactions['active'] ?? json['active_transactions']),
      overdueTransactions: parseIntSafe(transactions['overdue'] ?? json['overdue_transactions']),
      totalLoan: parseDoubleSafe(transactions['total_active_loan'] ?? json['total_loan']),
      // From requests nested object
      pendingRequests: parseIntSafe(requests['pending'] ?? json['pending_requests']),
    );
  }

  String get totalLoanFormatted {
    // if (totalLoan >= 1000000000) {
    //   return 'Rp ${(totalLoan / 1000000000).toStringAsFixed(1)} M';
    // } else if (totalLoan >= 1000000) {
    //   return 'Rp ${(totalLoan / 1000000).toStringAsFixed(1)} Juta';
    // } else if (totalLoan >= 1000) {
    //   return 'Rp ${(totalLoan / 1000).toStringAsFixed(0)} Ribu';
    // }
    // parse to currency format with no decimal places
    return 'Rp ${totalLoan.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'requests': {
        'pending': pendingRequests,
      },
      'transactions': {
        'active': activeTransactions,
        'overdue': overdueTransactions,
        'total_active_loan': totalLoan,
      },
    };
  }
}

class RecentRequest {
  final String code;
  final String collateralName;
  final double loanAmount;
  final String loanAmountFormatted;
  final String status;
  final DateTime? createdAt;

  RecentRequest({
    required this.code,
    required this.collateralName,
    required this.loanAmount,
    this.loanAmountFormatted = '',
    required this.status,
    this.createdAt,
  });

  factory RecentRequest.fromJson(Map<String, dynamic> json) {
    // Safely parse numeric value
    double parseDoubleSafe(dynamic value) {
      if (value == null) return 0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }
    
    double amount = parseDoubleSafe(json['requested_loan_amount']) > 0
        ? parseDoubleSafe(json['requested_loan_amount'])
        : parseDoubleSafe(json['loan_amount']);
    
    // Get formatted string (fallback to empty)
    String formatted = json['requested_amount_formatted'] ?? json['loan_amount_formatted'] ?? '';
    
    return RecentRequest(
      code: json['request_code'] ?? json['code'] ?? '',
      collateralName: json['collateral_name'] ?? '',
      loanAmount: amount,
      loanAmountFormatted: formatted,
      status: json['status'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'collateral_name': collateralName,
      'requested_loan_amount': loanAmount,
      'requested_amount_formatted': loanAmountFormatted,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ActiveTransaction {
  final String code;
  final String collateralName;
  final double loanAmount;
  final String loanAmountFormatted;
  final String? dueDate;
  final int? daysUntilDue;
  final bool isOverdue;

  ActiveTransaction({
    required this.code,
    required this.collateralName,
    required this.loanAmount,
    this.loanAmountFormatted = '',
    this.dueDate,
    this.daysUntilDue,
    this.isOverdue = false,
  });

  factory ActiveTransaction.fromJson(Map<String, dynamic> json) {
    // Safely parse numeric value
    double parseDoubleSafe(dynamic value) {
      if (value == null) return 0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }
    
    double amount = parseDoubleSafe(json['loan_amount']) > 0
        ? parseDoubleSafe(json['loan_amount'])
        : parseDoubleSafe(json['requested_loan_amount']);
    
    // Get formatted string
    String formatted = json['loan_amount_formatted'] ?? '';
    
    return ActiveTransaction(
      code: json['transaction_code'] ?? json['request_code'] ?? '',
      collateralName: json['collateral_name'] ?? '',
      loanAmount: amount,
      loanAmountFormatted: formatted,
      dueDate: json['due_date']?.toString(),
      daysUntilDue: json['days_until_due'] is int ? json['days_until_due'] : null,
      isOverdue: json['is_overdue'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_code': code,
      'collateral_name': collateralName,
      'loan_amount': loanAmount,
      'loan_amount_formatted': loanAmountFormatted,
      'due_date': dueDate,
      'days_until_due': daysUntilDue,
      'is_overdue': isOverdue,
    };
  }
}

class DashboardAlert {
  final String type;
  final String message;
  final String? actionUrl;

  DashboardAlert({
    required this.type,
    required this.message,
    this.actionUrl,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> json) {
    return DashboardAlert(
      type: json['type'] ?? 'info',
      message: json['message'] ?? '',
      actionUrl: json['action_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'action_url': actionUrl,
    };
  }
}

class DashboardRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService = CacheService.instance;

  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get dashboard data with caching (5 minutes)
  Future<DashboardData> getDashboard({bool forceRefresh = false}) async {
    // Clear cache if forcing refresh
    if (forceRefresh) {
      await clearCache();
    }
    
    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      try {
        final cachedData = await _cacheService.getRawCache(CacheKeys.dashboard);
        if (cachedData != null) {
          return DashboardData.fromJson(cachedData as Map<String, dynamic>);
        }
      } catch (_) {
        // Ignore cache errors, proceed to fetch
      }
    }

    // Fetch from API
    try {
      final response = await _apiClient.get(ApiEndpoints.dashboard);

      if (response.statusCode == 200) {
        // Handle different response structures
        final responseData = response.data;
        Map<String, dynamic> dashboardJson;
        
        if (responseData is Map<String, dynamic>) {
          // Check if data is wrapped in 'data' key
          if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
            dashboardJson = responseData['data'];
          } else {
            // Data is at root level
            dashboardJson = responseData;
          }
        } else {
          throw ServerException(message: 'Invalid response format');
        }
        
        try {
          final data = DashboardData.fromJson(dashboardJson);
          
          // Cache the data for 5 minutes
          await _cacheService.setCache(
            key: CacheKeys.dashboard,
            data: data.toJson(),
            expiration: CacheDurations.dashboard,
          );
          
          return data;
        } catch (parseError) {
          throw ServerException(message: 'Parse error: $parseError');
        }
      } else {
        throw ServerException(
          message: 'Gagal memuat dashboard',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // On error, try to return cached data even if expired
      try {
        final cachedData = await _cacheService.getRawCache(CacheKeys.dashboard);
        if (cachedData != null) {
          return DashboardData.fromJson(cachedData as Map<String, dynamic>);
        }
      } catch (_) {}
      
      if (e is ServerException) rethrow;
      
      // Handle Dio errors specifically
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.message ?? 'Network error';
        throw ServerException(message: message, statusCode: statusCode);
      }
      
      throw ServerException(message: 'Error: ${e.toString()}');
    }
  }

  /// Clear dashboard cache
  Future<void> clearCache() async {
    await _cacheService.removeCache(CacheKeys.dashboard);
  }
}
