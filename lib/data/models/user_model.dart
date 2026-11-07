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
    // If json has nested 'user' key (e.g. from /me or /profile endpoint: {user: {...}, customer: {...}})
    Map<String, dynamic> userMap = json;
    dynamic customerData = json['customer'];
    if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
      userMap = json['user'] as Map<String, dynamic>;
      customerData = json['customer'] ?? userMap['customer'];
    }

    return UserModel(
      id: (userMap['id'] is num) ? (userMap['id'] as num).toInt() : (int.tryParse(userMap['id']?.toString() ?? '') ?? 0),
      name: (userMap['name'] ?? userMap['full_name'] ?? '')?.toString() ?? '',
      email: (userMap['email'] ?? '')?.toString() ?? '',
      phone: userMap['phone']?.toString(),
      emailVerifiedAt: userMap['email_verified_at'] != null
          ? DateTime.tryParse(userMap['email_verified_at'].toString())
          : null,
      createdAt: userMap['created_at'] != null
          ? DateTime.tryParse(userMap['created_at'].toString())
          : null,
      updatedAt: userMap['updated_at'] != null
          ? DateTime.tryParse(userMap['updated_at'].toString())
          : null,
      customer: customerData != null && customerData is Map<String, dynamic>
          ? CustomerModel.fromJson(customerData)
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
      id: (json['id'] is num) ? (json['id'] as num).toInt() : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      userId: (json['user_id'] is num) ? (json['user_id'] as num).toInt() : (int.tryParse(json['user_id']?.toString() ?? '') ?? 0),
      code: json['code']?.toString(),
      nik: json['nik']?.toString(),
      fullName: (json['full_name'] ?? json['name'])?.toString(),
      birthPlace: json['birth_place']?.toString(),
      birthDate: json['birth_date']?.toString(),
      gender: json['gender']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      provinceCode: json['province_code']?.toString(),
      provinceName: (json['province'] ?? json['province_name'])?.toString(),
      cityCode: json['city_code']?.toString(),
      cityName: (json['city'] ?? json['city_name'])?.toString(),
      districtCode: json['district_code']?.toString(),
      districtName: (json['district'] ?? json['district_name'])?.toString(),
      villageCode: json['village_code']?.toString(),
      villageName: (json['village'] ?? json['village_name'])?.toString(),
      postalCode: json['postal_code']?.toString(),
      occupation: json['occupation']?.toString(),
      monthlyIncome: json['monthly_income']?.toString(),
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactPhone: json['emergency_contact_phone']?.toString(),
      emergencyContactRelation: json['emergency_contact_relation']?.toString(),
      idCardPhoto: json['id_card_photo']?.toString(),
      selfiePhoto: json['selfie_photo']?.toString(),
      isProfileComplete: json['is_profile_complete'] == true || json['is_profile_complete'] == 1,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
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
