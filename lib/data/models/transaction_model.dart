import '../../core/utils/image_utils.dart';

class TransactionProductModel {
  final int? id;
  final String? name;
  final bool? isSharia;

  TransactionProductModel({this.id, this.name, this.isSharia});

  factory TransactionProductModel.fromJson(Map<String, dynamic> json) {
    return TransactionProductModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      isSharia: json['is_sharia'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_sharia': isSharia,
      };
}

class TransactionBranchModel {
  final int? id;
  final String? name;

  TransactionBranchModel({this.id, this.name});

  factory TransactionBranchModel.fromJson(Map<String, dynamic> json) {
    return TransactionBranchModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class TransactionModel {
  final int id;
  final String transactionCode;
  final String status;
  final String? statusLabel;
  final String? statusColor;
  final TransactionProductModel? product;
  final TransactionBranchModel? branch;
  final String collateralName;
  final double loanAmount;
  final String? loanAmountFormatted;
  final String? transactionDate;
  final String? transactionDateFormatted;
  final String? dueDate;
  final String? dueDateFormatted;
  final int? daysUntilDue;
  final bool isOverdue;
  final int extensionCount;
  final String? akadNumber;
  final String? akadType;
  final bool? isSharia;
  final int? daysOverdue;
  final bool isDueSoonH3;
  final String? auctionDate;
  final String? auctionDateFormatted;
  final bool isAuctionReady;
  final bool isAuctioned;
  final String? photoUrl;
  final String? photoThumbUrl;

  TransactionModel({
    required this.id,
    required this.transactionCode,
    required this.status,
    this.statusLabel,
    this.statusColor,
    this.product,
    this.branch,
    required this.collateralName,
    required this.loanAmount,
    this.loanAmountFormatted,
    this.transactionDate,
    this.transactionDateFormatted,
    this.dueDate,
    this.dueDateFormatted,
    this.daysUntilDue,
    this.isOverdue = false,
    this.extensionCount = 0,
    this.akadNumber,
    this.akadType,
    this.isSharia,
    this.daysOverdue,
    this.isDueSoonH3 = false,
    this.auctionDate,
    this.auctionDateFormatted,
    this.isAuctionReady = false,
    this.isAuctioned = false,
    this.photoUrl,
    this.photoThumbUrl,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Defensive parsing with null safety
    final id = json['id'];
    final transactionCode = json['transaction_code'];
    final status = json['status'];
    
    // Handle product with alternative field names (product or loan_product)
    final productData = json['product'] ?? json['loan_product'];
    
    // Handle collateral name with alternative field names
    final collateralName = json['collateral_name'] ?? json['collateral']?['name'];
    
    // Handle start date with alternative field names
    final transactionDate = json['transaction_date'] ?? json['start_date'];
    final transactionDateFormatted = json['transaction_date_formatted'] ?? json['start_date_formatted'];
    
    return TransactionModel(
      id: id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0),
      transactionCode: transactionCode?.toString() ?? '',
      status: status?.toString() ?? 'unknown',
      statusLabel: json['status_label']?.toString(),
      statusColor: json['status_color']?.toString(),
      product: productData != null && productData is Map<String, dynamic>
          ? TransactionProductModel.fromJson(productData)
          : null,
      branch: json['branch'] != null && json['branch'] is Map<String, dynamic>
          ? TransactionBranchModel.fromJson(json['branch'] as Map<String, dynamic>)
          : null,
      collateralName: collateralName?.toString() ?? '',
      loanAmount: _parseDouble(json['loan_amount']),
      loanAmountFormatted: json['loan_amount_formatted']?.toString(),
      transactionDate: transactionDate?.toString(),
      transactionDateFormatted: transactionDateFormatted?.toString(),
      dueDate: json['due_date']?.toString(),
      dueDateFormatted: json['due_date_formatted']?.toString(),
      daysUntilDue: _parseInt(json['days_until_due']),
      isOverdue: json['is_overdue'] == true || json['status']?.toString().toUpperCase() == 'OVERDUE',
      extensionCount: _parseInt(json['extension_count']) ?? 0,
      akadNumber: (json['akad_number']?.toString().replaceFirst(RegExp(r'^SBG-'), '')) ?? json['transaction_code']?.toString(),
      akadType: json['akad_type']?.toString(),
      isSharia: json['is_sharia'] == true || json['product']?['is_sharia'] == true,
      daysOverdue: _parseInt(json['days_overdue']),
      isDueSoonH3: json['is_due_soon_h3'] == true ||
          (_parseInt(json['days_until_due']) != null &&
              _parseInt(json['days_until_due'])! <= 3 &&
              _parseInt(json['days_until_due'])! >= 0),
      auctionDate: json['auction_date']?.toString(),
      auctionDateFormatted: json['auction_date_formatted']?.toString(),
      isAuctionReady: json['is_auction_ready'] == true ||
          json['status']?.toString().toUpperCase() == 'AUCTION_READY',
      isAuctioned: json['is_auctioned'] == true ||
          json['status']?.toString().toUpperCase() == 'AUCTIONED',
      photoUrl: ImageUtils.resolveImageUrl(json['photo_url']?.toString() ?? json['collateral_photo']?.toString()),
      photoThumbUrl: ImageUtils.resolveImageUrl(json['photo_thumb_url']?.toString() ?? json['thumb_url']?.toString()),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? double.tryParse(value.toString())?.toInt();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_code': transactionCode,
      'status': status,
      'status_label': statusLabel,
      'status_color': statusColor,
      'product': product?.toJson(),
      'branch': branch?.toJson(),
      'collateral_name': collateralName,
      'loan_amount': loanAmount,
      'loan_amount_formatted': loanAmountFormatted,
      'transaction_date': transactionDate,
      'transaction_date_formatted': transactionDateFormatted,
      'due_date': dueDate,
      'due_date_formatted': dueDateFormatted,
      'days_until_due': daysUntilDue,
      'is_overdue': isOverdue,
      'extension_count': extensionCount,
    };
  }

  // Convenience getters for backward compatibility
  String get code => transactionCode;
  String? get productName => product?.name;
  String? get branchName => branch?.name;
  String? get startDate => transactionDate;

  String get displayStatusLabel {
    if (statusLabel != null) return statusLabel!;
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'extended':
        return 'Diperpanjang';
      case 'overdue':
        return 'Jatuh Tempo';
      case 'completed':
        return 'Selesai';
      case 'auction':
        return 'Lelang';
      default:
        return status;
    }
  }
}

class CollateralPhotoModel {
  final int id;
  final String url;
  final String? thumbUrl;

  CollateralPhotoModel({
    required this.id,
    required this.url,
    this.thumbUrl,
  });

  factory CollateralPhotoModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final rawUrl = json['url']?.toString() ?? json['photo_url']?.toString() ?? '';
    final rawThumb = json['thumb_url']?.toString() ?? json['photo_thumb_url']?.toString() ?? rawUrl;
    return CollateralPhotoModel(
      id: id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0),
      url: ImageUtils.resolveImageUrl(rawUrl) ?? rawUrl,
      thumbUrl: ImageUtils.resolveImageUrl(rawThumb) ?? ImageUtils.resolveImageUrl(rawUrl),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'thumb_url': thumbUrl,
      };
}

class TransactionDetailModel extends TransactionModel {
  final String? collateralDescription;
  final double? appraisedValue;
  final String? appraisedValueFormatted;
  final double? adminFee;
  final String? adminFeeFormatted;
  final double? initialFee;
  final String? initialFeeFormatted;
  final double? cashDisbursed;
  final String? cashDisbursedFormatted;
  final String? initialDueDate;
  final String? initialDueDateFormatted;
  final int? maxExtensions;
  final bool canExtend;
  final String? barcode;
  final String? notes;
  final String? customerName;
  final String? customerNik;
  final String? customerCode;
  final List<String>? akadClauses;
  final List<CollateralPhotoModel>? collateralPhotos;
  final List<TransactionHistoryModel>? history;
  final String? customerPhotoUrl;
  final String? idCardPhotoUrl;

  TransactionDetailModel({
    required super.id,
    required super.transactionCode,
    required super.status,
    super.statusLabel,
    super.statusColor,
    super.product,
    super.branch,
    required super.collateralName,
    required super.loanAmount,
    super.loanAmountFormatted,
    super.transactionDate,
    super.transactionDateFormatted,
    super.dueDate,
    super.dueDateFormatted,
    super.daysUntilDue,
    super.isOverdue,
    super.extensionCount,
    super.akadNumber,
    super.akadType,
    super.isSharia,
    super.daysOverdue,
    super.isDueSoonH3,
    super.auctionDate,
    super.auctionDateFormatted,
    super.isAuctionReady,
    super.isAuctioned,
    super.photoUrl,
    super.photoThumbUrl,
    this.collateralDescription,
    this.appraisedValue,
    this.appraisedValueFormatted,
    this.adminFee,
    this.adminFeeFormatted,
    this.initialFee,
    this.initialFeeFormatted,
    this.cashDisbursed,
    this.cashDisbursedFormatted,
    this.initialDueDate,
    this.initialDueDateFormatted,
    this.maxExtensions,
    this.canExtend = false,
    this.barcode,
    this.notes,
    this.customerName,
    this.customerNik,
    this.customerCode,
    this.customerPhotoUrl,
    this.idCardPhotoUrl,
    this.akadClauses,
    this.collateralPhotos,
    this.history,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final transactionCode = json['transaction_code'];
    final status = json['status'];
    
    // Handle product with alternative field names (product or loan_product)
    final productData = json['product'] ?? json['loan_product'];
    
    // Handle collateral name with alternative field names
    final collateralName = json['collateral_name'] ?? json['collateral']?['name'];
    
    // Handle appraisal value with alternative field names
    final appraisedValue = json['appraised_value'] ?? json['appraisal_value'];
    final appraisedValueFormatted = json['appraised_value_formatted'] ?? json['appraisal_value_formatted'];
    
    // Handle start date with alternative field names
    final transactionDate = json['transaction_date'] ?? json['start_date'];
    final transactionDateFormatted = json['transaction_date_formatted'] ?? json['start_date_formatted'];
    
    return TransactionDetailModel(
      id: id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0),
      transactionCode: transactionCode?.toString() ?? '',
      status: status?.toString() ?? 'unknown',
      statusLabel: json['status_label']?.toString(),
      statusColor: json['status_color']?.toString(),
      product: productData != null && productData is Map<String, dynamic>
          ? TransactionProductModel.fromJson(productData)
          : null,
      branch: json['branch'] != null && json['branch'] is Map<String, dynamic>
          ? TransactionBranchModel.fromJson(json['branch'] as Map<String, dynamic>)
          : null,
      collateralName: collateralName?.toString() ?? '',
      loanAmount: TransactionModel._parseDouble(json['loan_amount']),
      loanAmountFormatted: json['loan_amount_formatted']?.toString(),
      transactionDate: transactionDate?.toString(),
      transactionDateFormatted: transactionDateFormatted?.toString(),
      dueDate: json['due_date']?.toString(),
      dueDateFormatted: json['due_date_formatted']?.toString(),
      daysUntilDue: TransactionModel._parseInt(json['days_until_due']),
      isOverdue: json['is_overdue'] == true || json['status']?.toString().toUpperCase() == 'OVERDUE',
      extensionCount: TransactionModel._parseInt(json['extension_count']) ?? 0,
      akadNumber: (json['akad_number']?.toString().replaceFirst(RegExp(r'^SBG-'), '')) ?? json['transaction_code']?.toString(),
      akadType: json['akad_type']?.toString(),
      isSharia: json['is_sharia'] == true || json['product']?['is_sharia'] == true,
      daysOverdue: TransactionModel._parseInt(json['days_overdue']),
      isDueSoonH3: json['is_due_soon_h3'] == true ||
          (TransactionModel._parseInt(json['days_until_due']) != null &&
              TransactionModel._parseInt(json['days_until_due'])! <= 3 &&
              TransactionModel._parseInt(json['days_until_due'])! >= 0),
      auctionDate: json['auction_date']?.toString(),
      auctionDateFormatted: json['auction_date_formatted']?.toString(),
      isAuctionReady: json['is_auction_ready'] == true ||
          json['status']?.toString().toUpperCase() == 'AUCTION_READY',
      isAuctioned: json['is_auctioned'] == true ||
          json['status']?.toString().toUpperCase() == 'AUCTIONED',
      photoUrl: ImageUtils.resolveImageUrl(json['photo_url']?.toString() ?? json['collateral_photo']?.toString()),
      photoThumbUrl: ImageUtils.resolveImageUrl(json['photo_thumb_url']?.toString() ?? json['thumb_url']?.toString()),
      collateralDescription: (json['collateral_description'] ?? json['collateral']?['description'])?.toString(),
      appraisedValue: TransactionModel._parseDouble(appraisedValue),
      appraisedValueFormatted: appraisedValueFormatted?.toString(),
      adminFee: TransactionModel._parseDouble(json['admin_fee']),
      adminFeeFormatted: json['admin_fee_formatted']?.toString(),
      initialFee: TransactionModel._parseDouble(json['initial_fee']),
      initialFeeFormatted: json['initial_fee_formatted']?.toString(),
      cashDisbursed: TransactionModel._parseDouble(json['cash_disbursed']),
      cashDisbursedFormatted: json['cash_disbursed_formatted']?.toString(),
      initialDueDate: json['initial_due_date']?.toString(),
      initialDueDateFormatted: json['initial_due_date_formatted']?.toString(),
      maxExtensions: TransactionModel._parseInt(json['max_extensions']),
      canExtend: json['can_extend'] == true,
      barcode: json['barcode']?.toString(),
      notes: json['notes']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerNik: json['customer_nik']?.toString(),
      customerCode: json['customer_code']?.toString(),
      customerPhotoUrl: ImageUtils.resolveImageUrl(json['customer_photo_url']?.toString() ?? json['customer_photo']?.toString()),
      idCardPhotoUrl: ImageUtils.resolveImageUrl(json['id_card_photo_url']?.toString() ?? json['id_card_photo']?.toString()),
      akadClauses: _parseClauses(json['akad_clauses']),
      collateralPhotos: _parsePhotos(json['collateral_photos'] ?? json['photos']) ??
          ((json['photo_url'] != null || json['photo_thumb_url'] != null)
              ? [
                  CollateralPhotoModel(
                    id: 0,
                    url: ImageUtils.resolveImageUrl(json['photo_url']?.toString()) ?? json['photo_url']?.toString() ?? '',
                    thumbUrl: ImageUtils.resolveImageUrl(json['photo_thumb_url']?.toString()) ?? ImageUtils.resolveImageUrl(json['photo_url']?.toString()),
                  )
                ]
              : null),
      history: _parseHistory(json['history']),
    );
  }

  static List<String>? _parseClauses(dynamic value) {
    if (value == null || value is! List) return null;
    return value.map((e) => e.toString()).toList();
  }

  static List<CollateralPhotoModel>? _parsePhotos(dynamic value) {
    if (value == null || value is! List) return null;
    try {
      final List<CollateralPhotoModel> photos = [];
      for (int i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is Map) {
          photos.add(CollateralPhotoModel.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String && item.isNotEmpty) {
          photos.add(CollateralPhotoModel(
            id: i,
            url: ImageUtils.resolveImageUrl(item) ?? item,
            thumbUrl: ImageUtils.resolveImageUrl(item),
          ));
        }
      }
      return photos.isNotEmpty ? photos : null;
    } catch (e) {
      return null;
    }
  }

  static List<TransactionHistoryModel>? _parseHistory(dynamic value) {
    if (value == null || value is! List) return null;
    try {
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) => TransactionHistoryModel.fromJson(e))
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['collateral_description'] = collateralDescription;
    map['appraised_value'] = appraisedValue;
    map['appraised_value_formatted'] = appraisedValueFormatted;
    map['admin_fee'] = adminFee;
    map['admin_fee_formatted'] = adminFeeFormatted;
    map['initial_fee'] = initialFee;
    map['initial_fee_formatted'] = initialFeeFormatted;
    map['cash_disbursed'] = cashDisbursed;
    map['cash_disbursed_formatted'] = cashDisbursedFormatted;
    map['initial_due_date'] = initialDueDate;
    map['initial_due_date_formatted'] = initialDueDateFormatted;
    map['max_extensions'] = maxExtensions;
    map['can_extend'] = canExtend;
    map['barcode'] = barcode;
    map['notes'] = notes;
    map['collateral_photos'] = collateralPhotos?.map((e) => e.toJson()).toList();
    map['history'] = history?.map((e) => e.toJson()).toList();
    return map;
  }
}

class TransactionHistoryModel {
  final int id;
  final String type;
  final double? amount;
  final String? description;
  final DateTime? createdAt;

  TransactionHistoryModel({
    required this.id,
    required this.type,
    this.amount,
    this.description,
    this.createdAt,
  });

  factory TransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return TransactionHistoryModel(
      id: id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0),
      type: json['type']?.toString() ?? 'unknown',
      amount: TransactionModel._parseDouble(json['amount']),
      description: json['description']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
