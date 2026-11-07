/// Model untuk kategori jaminan (collateral category)
class CollateralCategoryModel {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;

  CollateralCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.isActive = true,
  });

  factory CollateralCategoryModel.fromJson(Map<String, dynamic> json) {
    return CollateralCategoryModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Model untuk kategori produk
class ProductCategoryModel {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  ProductCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Model untuk produk kalkulator
class CalculatorProductModel {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final double? minAmount;
  final double? maxAmount;
  final double? interestRate;  // Interest rate bulanan (%)
  final double? adminFeePercent;
  final double? adminFeeFixed;
  final int? defaultTenor;  // dalam hari
  final int? minTenor;
  final int? maxTenor;
  final int? dueDateDays;  // Jatuh tempo dalam hari
  final bool isSharia;  // Produk syariah
  final bool hasTiers;  // Memiliki tier (untuk syariah)
  final bool isActive;
  final List<CalculatorTierModel>? tiers;

  CalculatorProductModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.categoryId,
    this.categoryName,
    this.minAmount,
    this.maxAmount,
    this.interestRate,
    this.adminFeePercent,
    this.adminFeeFixed,
    this.defaultTenor,
    this.minTenor,
    this.maxTenor,
    this.dueDateDays,
    this.isSharia = false,
    this.hasTiers = false,
    this.isActive = true,
    this.tiers,
  });

  factory CalculatorProductModel.fromJson(Map<String, dynamic> json) {
    return CalculatorProductModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
      categoryId: json['category_id'] is String 
          ? int.parse(json['category_id']) 
          : json['category_id'] as int?,
      // Handle both 'category_name' and 'category' (string or object)
      categoryName: json['category_name'] as String? 
          ?? (json['category'] is String ? json['category'] as String : null)
          ?? (json['category'] is Map ? json['category']['name'] as String? : null),
      // Handle both 'min_amount' and 'loan_min'
      minAmount: (json['min_amount'] as num?)?.toDouble() 
          ?? (json['loan_min'] as num?)?.toDouble(),
      // Handle both 'max_amount' and 'loan_max'
      maxAmount: (json['max_amount'] as num?)?.toDouble() 
          ?? (json['loan_max'] as num?)?.toDouble(),
      interestRate: (json['interest_rate'] as num?)?.toDouble(),
      adminFeePercent: (json['admin_fee_percent'] as num?)?.toDouble(),
      adminFeeFixed: (json['admin_fee_fixed'] as num?)?.toDouble(),
      // Handle both 'default_tenor' and 'initial_tenor_days'
      defaultTenor: _parseIntOrNull(json['default_tenor']) 
          ?? _parseIntOrNull(json['initial_tenor_days']),
      minTenor: _parseIntOrNull(json['min_tenor']),
      maxTenor: _parseIntOrNull(json['max_tenor']),
      dueDateDays: _parseIntOrNull(json['due_date_days']),
      isSharia: json['is_sharia'] as bool? ?? false,
      hasTiers: json['has_tiers'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      tiers: json['tiers'] != null
          ? (json['tiers'] as List)
              .map((t) => CalculatorTierModel.fromJson(t))
              .toList()
          : null,
    );
  }
  
  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Get interest rate untuk amount tertentu (jika ada tiers)
  /// Untuk syariah: tidak menggunakan interest rate (return 0)
  double getInterestRateForAmount(double amount) {
    if (isSharia) return 0; // Syariah tidak pakai bunga
    
    if (tiers != null && tiers!.isNotEmpty) {
      for (final tier in tiers!) {
        if (tier.minAmount != null && tier.maxAmount != null) {
          if (amount >= tier.minAmount! && amount <= tier.maxAmount!) {
            return tier.interestRate ?? interestRate ?? 0;
          }
        }
      }
    }
    return interestRate ?? 0;
  }

  /// Get admin fee percent untuk amount tertentu
  /// Untuk syariah dengan tiers: fee didapat dari tier yang dipilih
  double getAdminFeePercentForAmount(double amount) {
    if (isSharia) return 0; // Syariah pakai nominal fee bukan persen
    
    if (tiers != null && tiers!.isNotEmpty) {
      for (final tier in tiers!) {
        if (tier.minAmount != null && tier.maxAmount != null) {
          if (amount >= tier.minAmount! && amount <= tier.maxAmount!) {
            return tier.adminFeePercent ?? adminFeePercent ?? 0;
          }
        }
      }
    }
    return adminFeePercent ?? 0;
  }

  /// Get tier by amount - mencari tier yang cocok atau terdekat
  /// Untuk syariah: cari tier dengan loanAmount terdekat yang <= amount
  /// Untuk non-syariah: cari tier dengan range yang mencakup amount
  CalculatorTierModel? getTierForAmount(double amount) {
    if (tiers == null || tiers!.isEmpty) return null;
    
    // Pertama, coba cari exact match atau range match
    for (final tier in tiers!) {
      // Untuk syariah: cek loanAmount exact match
      if (tier.loanAmount != null && tier.loanAmount == amount) {
        return tier;
      }
      // Untuk tier dengan range: cek apakah amount dalam range
      if (tier.minAmount != null && tier.maxAmount != null) {
        if (amount >= tier.minAmount! && amount <= tier.maxAmount!) {
          return tier;
        }
      }
    }
    
    // Jika tidak ada exact match, cari tier terdekat yang <= amount
    CalculatorTierModel? closestTier;
    double closestDiff = double.infinity;
    
    for (final tier in tiers!) {
      if (tier.loanAmount != null) {
        // Untuk tier dengan loanAmount spesifik
        if (tier.loanAmount! <= amount) {
          final diff = amount - tier.loanAmount!;
          if (diff < closestDiff) {
            closestDiff = diff;
            closestTier = tier;
          }
        }
      } else if (tier.maxAmount != null) {
        // Untuk tier dengan range, gunakan maxAmount
        if (tier.maxAmount! <= amount) {
          final diff = amount - tier.maxAmount!;
          if (diff < closestDiff) {
            closestDiff = diff;
            closestTier = tier;
          }
        }
      }
    }
    
    return closestTier;
  }
}

/// Model untuk tier/tingkatan produk berdasarkan jumlah pinjaman
/// Untuk produk syariah, tier berisi loan_amount, initial_fee, admin_fee
class CalculatorTierModel {
  final int id;
  final int productId;
  final double? minAmount;  // Untuk tier range
  final double? maxAmount;  // Untuk tier range
  final double? loanAmount;  // Untuk syariah - nominal pinjaman spesifik
  final double? interestRate;  // Untuk non-syariah
  final double? initialFee;  // Untuk syariah - biaya awal
  final double? adminFee;  // Untuk syariah - biaya admin
  final double? adminFeePercent;  // Untuk non-syariah persentase
  final int? tenor;
  final String? label;  // Label tier untuk display

  CalculatorTierModel({
    required this.id,
    required this.productId,
    this.minAmount,
    this.maxAmount,
    this.loanAmount,
    this.interestRate,
    this.initialFee,
    this.adminFee,
    this.adminFeePercent,
    this.tenor,
    this.label,
  });

  /// Display label untuk dropdown
  String get displayLabel {
    if (label != null) return label!;
    if (loanAmount != null) return 'Rp ${_formatNumber(loanAmount!.toInt())}';
    if (minAmount != null && maxAmount != null) {
      return 'Rp ${_formatNumber(minAmount!.toInt())} - ${_formatNumber(maxAmount!.toInt())}';
    }
    return 'Tier $id';
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  factory CalculatorTierModel.fromJson(Map<String, dynamic> json) {
    return CalculatorTierModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      productId: json['product_id'] is String 
          ? int.parse(json['product_id']) 
          : (json['product_id'] as int?) ?? (json['loan_product_id'] is String 
              ? int.parse(json['loan_product_id']) 
              : json['loan_product_id'] as int? ?? 0),
      minAmount: (json['min_amount'] as num?)?.toDouble(),
      maxAmount: (json['max_amount'] as num?)?.toDouble(),
      loanAmount: (json['loan_amount'] as num?)?.toDouble(),
      interestRate: (json['interest_rate'] as num?)?.toDouble(),
      initialFee: (json['initial_fee'] as num?)?.toDouble(),
      adminFee: (json['admin_fee'] as num?)?.toDouble(),
      adminFeePercent: (json['admin_fee_percent'] as num?)?.toDouble(),
      tenor: json['tenor'] is String ? int.parse(json['tenor']) : json['tenor'] as int?,
      label: json['label'] as String?,
    );
  }
}

/// Model untuk request perhitungan
class CalculateRequest {
  final int productId;
  final double amount;
  final int? tenor;
  final int? collateralCategoryId;

  CalculateRequest({
    required this.productId,
    required this.amount,
    this.tenor,
    this.collateralCategoryId,
  });

  /// Untuk produk dengan tier (syariah), API akan otomatis mencari tier yang cocok
  Map<String, dynamic> toJson() {
    return {
      'loan_product_id': productId,
      'loan_amount': amount,
      if (tenor != null) 'tenor': tenor,
      if (collateralCategoryId != null) 'collateral_category_id': collateralCategoryId,
    };
  }
}

/// Model untuk hasil perhitungan dari API
class CalculateResultModel {
  final double loanAmount;
  final double adminFee;
  final double adminFeePercent;
  final double interest;
  final double interestRate;
  final double totalDeduction;
  final double cashReceived;
  final int tenor;
  final DateTime dueDate;
  final String? productName;
  final String? note;

  CalculateResultModel({
    required this.loanAmount,
    required this.adminFee,
    required this.adminFeePercent,
    required this.interest,
    required this.interestRate,
    required this.totalDeduction,
    required this.cashReceived,
    required this.tenor,
    required this.dueDate,
    this.productName,
    this.note,
  });

  factory CalculateResultModel.fromJson(Map<String, dynamic> json) {
    // Parse with fallbacks for different API response formats
    final loanAmount = _parseDouble(json['loan_amount']) ?? _parseDouble(json['amount']) ?? 0;
    final adminFee = _parseDouble(json['admin_fee']) ?? _parseDouble(json['biaya_admin']) ?? 0;
    final adminFeePercent = _parseDouble(json['admin_fee_percent']) ?? 0;
    final interest = _parseDouble(json['interest']) ?? _parseDouble(json['bunga']) ?? 0;
    final interestRate = _parseDouble(json['interest_rate']) ?? 0;
    final totalDeduction = _parseDouble(json['total_deduction']) ?? (adminFee + interest);
    final cashReceived = _parseDouble(json['cash_received']) ?? _parseDouble(json['uang_diterima']) ?? (loanAmount - totalDeduction);
    final tenor = _parseInt(json['tenor']) ?? _parseInt(json['jangka_waktu']) ?? 0;
    
    // Parse due_date with multiple format support
    DateTime dueDate;
    if (json['due_date'] != null) {
      dueDate = DateTime.tryParse(json['due_date'].toString()) ?? DateTime.now().add(Duration(days: tenor));
    } else if (json['jatuh_tempo'] != null) {
      dueDate = DateTime.tryParse(json['jatuh_tempo'].toString()) ?? DateTime.now().add(Duration(days: tenor));
    } else {
      dueDate = DateTime.now().add(Duration(days: tenor));
    }
    
    return CalculateResultModel(
      loanAmount: loanAmount,
      adminFee: adminFee,
      adminFeePercent: adminFeePercent,
      interest: interest,
      interestRate: interestRate,
      totalDeduction: totalDeduction,
      cashReceived: cashReceived,
      tenor: tenor,
      dueDate: dueDate,
      productName: json['product_name'] as String? ?? json['nama_produk'] as String?,
      note: json['note'] as String? ?? json['catatan'] as String?,
    );
  }
  
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }
}
