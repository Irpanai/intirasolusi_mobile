import '../constants/app_constants.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    if (!AppConstants.emailRegex.hasMatch(value)) {
      return 'Email tidak valid';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password minimal ${AppConstants.minPasswordLength} karakter';
    }
    return null;
  }

  // Password confirmation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon wajib diisi';
    }
    if (!AppConstants.phoneRegex.hasMatch(value)) {
      return 'Nomor telepon tidak valid';
    }
    return null;
  }

  // NIK validation
  static String? validateNIK(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIK wajib diisi';
    }
    if (!AppConstants.nikRegex.hasMatch(value)) {
      return 'NIK harus 16 digit';
    }
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field ini'} wajib diisi';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama wajib diisi';
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  // Amount validation
  static String? validateAmount(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Jumlah wajib diisi';
    }

    final numValue = double.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
    if (numValue == null) {
      return 'Jumlah tidak valid';
    }

    if (min != null && numValue < min) {
      return 'Jumlah minimal Rp $min';
    }

    if (max != null && numValue > max) {
      return 'Jumlah maksimal Rp $max';
    }

    return null;
  }
}
