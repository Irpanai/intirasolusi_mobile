class BranchModel {
  final int id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? city;
  final String? province;
  final double? latitude;
  final double? longitude;
  final String? operatingHours;
  final bool isActive;
  final double? distance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BranchModel({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.city,
    this.province,
    this.latitude,
    this.longitude,
    this.operatingHours,
    this.isActive = true,
    this.distance,
    this.createdAt,
    this.updatedAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      operatingHours: json['operating_hours'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      distance: (json['distance'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'city': city,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
      'operating_hours': operatingHours,
      'is_active': isActive,
      'distance': distance,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get distanceText {
    if (distance == null) return '';
    if (distance! < 1) {
      return '${(distance! * 1000).toStringAsFixed(0)} m';
    }
    return '${distance!.toStringAsFixed(1)} km';
  }
}
