import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _emailKey = 'user_email';
  static const _passwordKey = 'user_password';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _skipBiometricPromptOnceKey = 'skip_biometric_prompt_once';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  Future<String?> getEmail() => _storage.read(key: _emailKey);

  /// Save credentials for Face ID re-authentication
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await Future.wait([
      _storage.write(key: _emailKey, value: email),
      _storage.write(key: _passwordKey, value: password),
    ]);
  }

  Future<String?> getPassword() => _storage.read(key: _passwordKey);

  Future<bool> hasSavedCredentials() async {
    final email = await getEmail();
    final password = await getPassword();
    return email != null && password != null;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> clearSessionTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<void> suppressNextBiometricPrompt() async {
    await _storage.write(key: _skipBiometricPromptOnceKey, value: 'true');
  }

  Future<bool> consumeBiometricPromptSuppression() async {
    final value = await _storage.read(key: _skipBiometricPromptOnceKey);
    if (value != 'true') {
      return false;
    }

    await _storage.delete(key: _skipBiometricPromptOnceKey);
    return true;
  }

  Future<void> clearSavedPassword() => _storage.delete(key: _passwordKey);

  Future<void> clearBiometricPreference() async {
    await Future.wait([
      _storage.delete(key: _biometricEnabledKey),
      _storage.delete(key: _skipBiometricPromptOnceKey),
    ]);
  }

  Future<void> clearBiometricLoginData() async {
    await Future.wait([
      clearSavedPassword(),
      clearBiometricPreference(),
    ]);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
