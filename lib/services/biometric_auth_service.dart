import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthService {
  BiometricAuthService._();
  static final instance = BiometricAuthService._();

  final _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _kBiometricEnabledKey = 'biometric_enabled';
  static const _kLockEnabledKey = 'app_lock_enabled';

  Future<bool> isDeviceSupported() => _localAuth.isDeviceSupported();

  Future<bool> canCheckBiometrics() async {
    final can = await _localAuth.canCheckBiometrics;
    final supported = await isDeviceSupported();
    return can || supported;
  }

  Future<bool> authenticate({String reason = 'Confirma tu identidad'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // permite PIN/patrón/contraseña del dispositivo
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // Preferencias
  Future<void> setBiometricEnabled(bool value) async =>
      _storage.write(key: _kBiometricEnabledKey, value: value.toString());

  Future<bool> getBiometricEnabled() async =>
      (await _storage.read(key: _kBiometricEnabledKey)) == 'true';

  Future<void> setAppLockEnabled(bool value) async =>
      _storage.write(key: _kLockEnabledKey, value: value.toString());

  Future<bool> getAppLockEnabled() async =>
      (await _storage.read(key: _kLockEnabledKey)) == 'true';
}
