class ProvinceModel {
  final String code;
  final String name;

  ProvinceModel({
    required this.code,
    required this.name,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }
}

class CityModel {
  final String code;
  final String name;
  final String provinceCode;

  CityModel({
    required this.code,
    required this.name,
    required this.provinceCode,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      code: json['code'] as String,
      name: json['name'] as String,
      provinceCode: json['province_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'province_code': provinceCode,
    };
  }
}

class DistrictModel {
  final String code;
  final String name;
  final String cityCode;

  DistrictModel({
    required this.code,
    required this.name,
    required this.cityCode,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      code: json['code'] as String,
      name: json['name'] as String,
      cityCode: json['city_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'city_code': cityCode,
    };
  }
}

class VillageModel {
  final String code;
  final String name;
  final String districtCode;

  VillageModel({
    required this.code,
    required this.name,
    required this.districtCode,
  });

  factory VillageModel.fromJson(Map<String, dynamic> json) {
    return VillageModel(
      code: json['code'] as String,
      name: json['name'] as String,
      districtCode: json['district_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'district_code': districtCode,
    };
  }
}
