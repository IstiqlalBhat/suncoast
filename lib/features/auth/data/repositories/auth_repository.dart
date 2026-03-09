import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, AuthResponse, Session;
import '../../../../core/utils/result.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final SecureStorageService _secureStorage;

  const AuthRepository({
    required AuthRemoteDatasource remoteDatasource,
    required SecureStorageService secureStorage,
  })  : _remoteDatasource = remoteDatasource,
        _secureStorage = secureStorage;

  Future<Result<AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDatasource.signIn(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await _secureStorage.saveTokens(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken ?? '',
        );
        // Save credentials for Face ID re-authentication
        await _secureStorage.saveCredentials(email: email, password: password);
      }

      return Result.success(response);
    } on AuthException catch (e) {
      return Result.failure(e.message, code: e.code);
    } catch (e) {
      return Result.failure('Sign in failed: $e');
    }
  }

  Future<Result<AuthResponse>> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _remoteDatasource.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (response.session != null) {
        await _secureStorage.saveTokens(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken ?? '',
        );
        // Save credentials for Face ID re-authentication
        await _secureStorage.saveCredentials(email: email, password: password);
      }

      return Result.success(response);
    } on AuthException catch (e) {
      return Result.failure(e.message, code: e.code);
    } catch (e) {
      return Result.failure('Sign up failed: $e');
    }
  }

  Future<Result<void>> signOut() async {
    try {
      final biometricEnabled = await _secureStorage.isBiometricEnabled();
      await _remoteDatasource.signOut();
      if (biometricEnabled) {
        await _secureStorage.clearSessionTokens();
        await _secureStorage.suppressNextBiometricPrompt();
      } else {
        await _secureStorage.clearAll();
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Sign out failed: $e');
    }
  }

  Future<String?> getSavedEmail() => _secureStorage.getEmail();

  Session? get currentSession => _remoteDatasource.currentSession;
}
