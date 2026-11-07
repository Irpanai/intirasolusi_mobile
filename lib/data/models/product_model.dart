class ProductModel {
  final int id;
  final String name;
  final String? description;
  final double? minAmount;
  final double? maxAmount;
  final int? minTenor;
  final int? maxTenor;
  final double? interestRate;
  final double? adminFeePercentage;
  final bool isActive;
  final List<ProductTierModel>? tiers;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.minAmount,
    this.maxAmount,
    this.minTenor,
    this.maxTenor,
    this.interestRate,
    this.adminFeePercentage,
    this.isActive = true,
    this.tiers,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      minAmount: (json['min_amount'] as num?)?.toDouble(),
      maxAmount: (json['max_amount'] as num?)?.toDouble(),
      minTenor: json['min_tenor'] as int?,
      maxTenor: json['max_tenor'] as int?,
      interestRate: (json['interest_rate'] as num?)?.toDouble(),
      adminFeePercentage: (json['admin_fee_percentage'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      tiers: (json['tiers'] as List<dynamic>?)
          ?.map((e) => ProductTierModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'min_tenor': minTenor,
      'max_tenor': maxTenor,
      'interest_rate': interestRate,
      'admin_fee_percentage': adminFeePercentage,
      'is_active': isActive,
      'tiers': tiers?.map((e) => e.toJson()).toList(),
    };
  }
}

class ProductTierModel {
  final int id;
  final int productId;
  final double minAmount;
  final double maxAmount;
  final double interestRate;
  final double? adminFeePercentage;

  ProductTierModel({
    required this.id,
    required this.productId,
    required this.minAmount,
    required this.maxAmount,
    required this.interestRate,
    this.adminFeePercentage,
  });

  factory ProductTierModel.fromJson(Map<String, dynamic> json) {
    return ProductTierModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      minAmount: (json['min_amount'] as num).toDouble(),
      maxAmount: (json['max_amount'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      adminFeePercentage: (json['admin_fee_percentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'interest_rate': interestRate,
      'admin_fee_percentage': adminFeePercentage,
    };
  }
}

class CollateralCategoryModel {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  CollateralCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory CollateralCategoryModel.fromJson(Map<String, dynamic> json) {
    return CollateralCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}
