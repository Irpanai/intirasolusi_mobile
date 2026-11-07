class PawnRequestModel {
  final int id;
  final String code;
  final int? productId;
  final String? productName;
  final bool? isSharia;
  final int? categoryId;
  final String? categoryName;
  final String collateralName;
  final String? collateralDescription;
  final double? estimatedValue;
  final double loanAmount;
  final double? estimatedCashReceived;
  final int? preferredBranchId;
  final String? branchName;
  final String? notes;
  final String status;
  final String? statusLabel;
  final String? adminNotes;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? photos;

  PawnRequestModel({
    required this.id,
    required this.code,
    this.productId,
    this.productName,
    this.isSharia,
    this.categoryId,
    this.categoryName,
    required this.collateralName,
    this.collateralDescription,
    this.estimatedValue,
    required this.loanAmount,
    this.estimatedCashReceived,
    this.preferredBranchId,
    this.branchName,
    this.notes,
    required this.status,
    this.statusLabel,
    this.adminNotes,
    this.rejectionReason,
    this.approvedAt,
    this.rejectedAt,
    this.createdAt,
    this.updatedAt,
    this.photos,
  });

  factory PawnRequestModel.fromJson(Map<String, dynamic> json) {
    // Handle product as object or separate fields
    int? productId;
    String? productName;
    bool? isSharia;
    
    if (json['product'] != null && json['product'] is Map) {
      final product = json['product'] as Map<String, dynamic>;
      productId = product['id'] as int?;
      productName = product['name'] as String?;
      isSharia = product['is_sharia'] as bool?;
    } else {
      productId = json['product_id'] as int?;
      productName = json['product_name'] as String?;
      isSharia = json['is_sharia'] as bool?;
    }

    // Handle category as object or separate fields
    // API returns 'collateral_category' as string in detailed view
    int? categoryId;
    String? categoryName;
    
    if (json['category'] != null && json['category'] is Map) {
      final category = json['category'] as Map<String, dynamic>;
      categoryId = category['id'] as int?;
      categoryName = category['name'] as String?;
    } else {
      categoryId = json['category_id'] as int?;
      // Support 'collateral_category' from detailed response
      categoryName = json['category_name'] ?? json['collateral_category'] as String?;
    }

    // Handle branch as object or separate fields
    // API returns 'preferred_branch' object
    int? branchId;
    String? branchName;
    
    if (json['preferred_branch'] != null && json['preferred_branch'] is Map) {
      final branch = json['preferred_branch'] as Map<String, dynamic>;
      branchId = branch['id'] as int?;
      branchName = branch['name'] as String?;
    } else if (json['branch'] != null && json['branch'] is Map) {
      final branch = json['branch'] as Map<String, dynamic>;
      branchId = branch['id'] as int?;
      branchName = branch['name'] as String?;
    } else {
      branchId = json['preferred_branch_id'] as int?;
      branchName = json['branch_name'] ?? json['preferred_city'] as String?;
    }

    return PawnRequestModel(
      id: json['id'] as int,
      // Support both 'request_code' and 'code'
      code: (json['request_code'] ?? json['code']) as String,
      productId: productId,
      productName: productName,
      isSharia: isSharia,
      categoryId: categoryId,
      categoryName: categoryName,
      collateralName: json['collateral_name'] as String,
      collateralDescription: json['collateral_description'] as String?,
      estimatedValue: (json['estimated_value'] as num?)?.toDouble(),
      // Support both 'requested_loan_amount' and 'loan_amount'
      loanAmount: ((json['requested_loan_amount'] ?? json['loan_amount']) as num).toDouble(),
      estimatedCashReceived: (json['estimated_cash_received'] as num?)?.toDouble(),
      preferredBranchId: branchId,
      branchName: branchName,
      // Support both 'notes' and 'customer_notes' from API
      notes: (json['customer_notes'] ?? json['notes']) as String?,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String?,
      adminNotes: json['admin_notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      photos: (json['photos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_code': code,
      'product_id': productId,
      'product_name': productName,
      'is_sharia': isSharia,
      'category_id': categoryId,
      'category_name': categoryName,
      'collateral_name': collateralName,
      'collateral_description': collateralDescription,
      'estimated_value': estimatedValue,
      'requested_loan_amount': loanAmount,
      'estimated_cash_received': estimatedCashReceived,
      'preferred_branch_id': preferredBranchId,
      'branch_name': branchName,
      'notes': notes,
      'status': status,
      'status_label': statusLabel,
      'admin_notes': adminNotes,
      'rejection_reason': rejectionReason,
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'photos': photos,
    };
  }

  String get displayStatusLabel {
    // Use backend status_label if available, otherwise derive from status
    if (statusLabel != null && statusLabel!.isNotEmpty) {
      return statusLabel!;
    }
    // Handle uppercase status from backend
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu';
      case 'REVIEWING':
      case 'UNDER_REVIEW':
        return 'Direview';
      case 'DOCUMENT_REQUIRED':
        return 'Dokumen Diperlukan';
      case 'APPROVED':
        return 'Disetujui';
      case 'REJECTED':
        return 'Ditolak';
      case 'CANCELLED':
        return 'Dibatalkan';
      case 'CONVERTED':
        return 'Dikonversi';
      case 'COMPLETED':
        return 'Selesai';
      default:
        return status;
    }
  }

  bool get canCancel => status.toUpperCase() == 'PENDING';
}
