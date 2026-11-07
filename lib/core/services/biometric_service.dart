import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service untuk mengelola autentikasi biometrik (fingerprint/face)
class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage keys
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyBiometricEmail = 'biometric_email';
  static const _keyBiometricPassword = 'biometric_password';

  /// Cek apakah device mendukung biometric
  Future<bool> isAvailable() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Cek tipe biometric yang tersedia (fingerprint, face, iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Cek apakah device support fingerprint
  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong);
  }

  /// Cek apakah device support face recognition
  Future<bool> hasFaceId() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Authenticate dengan biometric
  /// Returns true jika berhasil, false jika gagal atau dibatalkan
  Future<bool> authenticate({
    String reason = 'Gunakan sidik jari untuk masuk ke aplikasi',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      // Handle specific errors
      if (e.code == 'NotAvailable') {
        // Biometric not available
        return false;
      } else if (e.code == 'NotEnrolled') {
        // No biometrics enrolled
        return false;
      } else if (e.code == 'LockedOut') {
        // Too many attempts
        return false;
      } else if (e.code == 'PermanentlyLockedOut') {
        // Device locked, need PIN/pattern
        return false;
      }
      return false;
    }
  }

  /// Simpan kredensial untuk biometric login
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _keyBiometricEmail, value: email);
    await _storage.write(key: _keyBiometricPassword, value: password);
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
  }

  /// Ambil kredensial yang tersimpan
  Future<BiometricCredentials?> getCredentials() async {
    final email = await _storage.read(key: _keyBiometricEmail);
    final password = await _storage.read(key: _keyBiometricPassword);

    if (email != null && password != null) {
      return BiometricCredentials(email: email, password: password);
    }
    return null;
  }

  /// Cek apakah biometric login sudah diaktifkan
  Future<bool> isEnabled() async {
    final enabled = await _storage.read(key: _keyBiometricEnabled);
    return enabled == 'true';
  }

  /// Cek apakah bisa menampilkan opsi biometric login
  /// (tersedia di device DAN sudah diaktifkan user)
  Future<bool> canUseBiometricLogin() async {
    final available = await isAvailable();
    final enabled = await isEnabled();
    return available && enabled;
  }

  /// Disable biometric login dan hapus kredensial
  Future<void> disable() async {
    await _storage.delete(key: _keyBiometricEnabled);
    await _storage.delete(key: _keyBiometricEmail);
    await _storage.delete(key: _keyBiometricPassword);
  }

  /// Update password tersimpan (jika user ganti password)
  Future<void> updatePassword(String newPassword) async {
    final isEnabled = await this.isEnabled();
    if (isEnabled) {
      await _storage.write(key: _keyBiometricPassword, value: newPassword);
    }
  }

  /// Nama tipe biometric untuk ditampilkan ke user
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong)) {
      return 'Sidik Jari';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometrik';
  }
}

/// Model untuk menyimpan kredensial biometric
class BiometricCredentials {
  final String email;
  final String password;

  BiometricCredentials({
    required this.email,
    required this.password,
  });
}
