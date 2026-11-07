class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, List<String>>? errors;
  final MetaData? meta;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'] != null
          ? (json['errors'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>()),
            )
          : null,
      meta: json['meta'] != null
          ? MetaData.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'success': success,
      'message': message,
      'data': data != null ? toJsonT(data as T) : null,
      'errors': errors,
      'meta': meta?.toJson(),
    };
  }
}

class MetaData {
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  MetaData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      currentPage: json['current_page'] as int?,
      lastPage: json['last_page'] as int?,
      perPage: json['per_page'] as int?,
      total: json['total'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
  }

  bool get hasNextPage =>
      currentPage != null && lastPage != null && currentPage! < lastPage!;
}

class AuthResponseData {
  final UserData user;
  final String token;
  final bool requiresProfileCompletion;

  AuthResponseData({
    required this.user,
    required this.token,
    this.requiresProfileCompletion = false,
  });

  factory AuthResponseData.fromJson(Map<String, dynamic> json) {
    return AuthResponseData(
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      requiresProfileCompletion:
          json['requires_profile_completion'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'requires_profile_completion': requiresProfileCompletion,
    };
  }
}

class UserData {
  final int id;
  final String name;
  final String email;
  final String? phone;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}
