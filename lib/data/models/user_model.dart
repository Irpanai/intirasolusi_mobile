class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CustomerModel? customer;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.customer,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'customer': customer?.toJson(),
    };
  }
}

class CustomerModel {
  final int id;
  final int userId;
  final String? code;
  final String? nik;
  final String? fullName;
  final String? birthPlace;
  final String? birthDate;
  final String? gender;
  final String? phone;
  final String? address;
  final String? provinceCode;
  final String? provinceName;
  final String? cityCode;
  final String? cityName;
  final String? districtCode;
  final String? districtName;
  final String? villageCode;
  final String? villageName;
  final String? postalCode;
  final String? occupation;
  final String? monthlyIncome;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? idCardPhoto;
  final String? selfiePhoto;
  final bool isProfileComplete;
  final DateTime? verifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerModel({
    required this.id,
    required this.userId,
    this.code,
    this.nik,
    this.fullName,
    this.birthPlace,
    this.birthDate,
    this.gender,
    this.phone,
    this.address,
    this.provinceCode,
    this.provinceName,
    this.cityCode,
    this.cityName,
    this.districtCode,
    this.districtName,
    this.villageCode,
    this.villageName,
    this.postalCode,
    this.occupation,
    this.monthlyIncome,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.idCardPhoto,
    this.selfiePhoto,
    this.isProfileComplete = false,
    this.verifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      code: json['code'] as String?,
      nik: json['nik'] as String?,
      fullName: json['full_name'] as String?,
      birthPlace: json['birth_place'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      provinceCode: json['province_code'] as String?,
      // API returns 'province' for name, fallback to 'province_name'
      provinceName: (json['province'] ?? json['province_name']) as String?,
      cityCode: json['city_code'] as String?,
      // API returns 'city' for name, fallback to 'city_name'
      cityName: (json['city'] ?? json['city_name']) as String?,
      districtCode: json['district_code'] as String?,
      // API returns 'district' for name, fallback to 'district_name'
      districtName: (json['district'] ?? json['district_name']) as String?,
      villageCode: json['village_code'] as String?,
      // API returns 'village' for name, fallback to 'village_name'
      villageName: (json['village'] ?? json['village_name']) as String?,
      postalCode: json['postal_code'] as String?,
      occupation: json['occupation'] as String?,
      monthlyIncome: json['monthly_income'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      emergencyContactRelation: json['emergency_contact_relation'] as String?,
      idCardPhoto: json['id_card_photo'] as String?,
      selfiePhoto: json['selfie_photo'] as String?,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
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
      'user_id': userId,
      'code': code,
      'nik': nik,
      'full_name': fullName,
      'birth_place': birthPlace,
      'birth_date': birthDate,
      'gender': gender,
      'phone': phone,
      'address': address,
      'province_code': provinceCode,
      'province_name': provinceName,
      'city_code': cityCode,
      'city_name': cityName,
      'district_code': districtCode,
      'district_name': districtName,
      'village_code': villageCode,
      'village_name': villageName,
      'postal_code': postalCode,
      'occupation': occupation,
      'monthly_income': monthlyIncome,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'id_card_photo': idCardPhoto,
      'selfie_photo': selfiePhoto,
      'is_profile_complete': isProfileComplete,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
