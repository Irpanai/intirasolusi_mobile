import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ServerFailure({
    required super.message,
    this.statusCode,
    this.errors,
  });

  @override
  List<Object?> get props => [message, statusCode, errors];
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Tidak ada koneksi internet'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Sesi telah berakhir. Silakan login kembali.'});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure({required super.message, this.errors});

  @override
  List<Object?> get props => [message, errors];
}
