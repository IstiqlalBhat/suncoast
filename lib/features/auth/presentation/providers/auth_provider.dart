import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../../../../services/biometric/biometric_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../settings/data/datasources/settings_remote_datasource.dart';
import '../../../settings/data/repositories/settings_repository.dart';
import '../../../../shared/models/user_settings_model.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.watch(supabaseClientProvider));
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remoteDatasource: ref.watch(authRemoteDatasourceProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

final authSettingsRemoteDatasourceProvider = Provider<SettingsRemoteDatasource>((
  ref,
) {
  return SettingsRemoteDatasource(ref.watch(supabaseClientProvider));
});

final authSettingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    remoteDatasource: ref.watch(authSettingsRemoteDatasourceProvider),
  );
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(
    authRepository: ref.watch(authRepositoryProvider),
    settingsRepository: ref.watch(authSettingsRepositoryProvider),
    biometricService: ref.watch(biometricServiceProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

class LoginState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const LoginState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;
  final BiometricService _biometricService;
  final SecureStorageService _secureStorage;

  LoginNotifier({
    required AuthRepository authRepository,
    required SettingsRepository settingsRepository,
    required BiometricService biometricService,
    required SecureStorageService secureStorage,
  })  : _authRepository = authRepository,
        _settingsRepository = settingsRepository,
        _biometricService = biometricService,
        _secureStorage = secureStorage,
        super(const LoginState());

  Future<void> signIn({
    required String email,
    required String password,
    bool enableBiometric = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    await result.when(
      success: (response) async {
        final biometricMessage = await _syncBiometricPreference(enableBiometric);
        await _persistFaceIdPreference(
          userId: response.user?.id,
          enabled: enableBiometric && biometricMessage == null,
        );
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          error: biometricMessage,
        );
      },
      failure: (message, _) async {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
    bool enableBiometric = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authRepository.signUp(
      email: email,
      password: password,
      name: name,
    );

    await result.when(
      success: (response) async {
        final biometricMessage = await _syncBiometricPreference(enableBiometric);
        await _persistFaceIdPreference(
          userId: response.user?.id,
          enabled: enableBiometric && biometricMessage == null,
        );
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          error: biometricMessage,
        );
      },
      failure: (message, _) async {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<void> signInWithBiometrics() async {
    await _signInWithBiometrics();
  }

  Future<void> maybeAutoSignInWithBiometrics() async {
    if (state.isLoading) return;

    final canAttempt = await canAttemptBiometricSignIn();
    if (!canAttempt) return;

    await _signInWithBiometrics(automatic: true);
  }

  Future<bool> canAttemptBiometricSignIn() async {
    final biometricEnabled = await _secureStorage.isBiometricEnabled();
    if (!biometricEnabled) return false;

    final hasCredentials = await _secureStorage.hasSavedCredentials();
    if (!hasCredentials) return false;

    return _biometricService.isAvailable();
  }

  Future<Result<void>> enableBiometricLogin() async {
    final isAvailable = await _biometricService.isAvailable();
    if (!isAvailable) {
      return const Result.failure(
        'Biometric authentication is not available on this device',
      );
    }

    final hasCredentials = await _secureStorage.hasSavedCredentials();
    if (!hasCredentials) {
      return const Result.failure(
        'Please sign in with email first to enable Face ID',
      );
    }

    final authenticated = await _biometricService.authenticate(
      reason: 'Enable Face ID for quick sign-in',
    );
    if (!authenticated) {
      return const Result.failure('Face ID setup cancelled');
    }

    await _secureStorage.setBiometricEnabled(true);
    return const Result.success(null);
  }

  Future<void> disableBiometricLogin() async {
    await _secureStorage.clearBiometricLoginData();
  }

  Future<String?> _syncBiometricPreference(bool enableBiometric) async {
    if (!enableBiometric) {
      await disableBiometricLogin();
      return null;
    }

    final isAlreadyEnabled = await _secureStorage.isBiometricEnabled();
    if (isAlreadyEnabled) {
      return null;
    }

    final result = await enableBiometricLogin();
    return result.when(
      success: (_) => null,
      failure: (message, _) => message,
    );
  }

  Future<void> _persistFaceIdPreference({
    required String? userId,
    required bool enabled,
  }) async {
    if (userId == null || userId.isEmpty) return;

    final current = await _settingsRepository.getSettings(userId);
    final settings = current.when(
      success: (data) => data.copyWith(faceIdEnabled: enabled),
      failure: (_, _) => UserSettingsModel(
        id: '',
        userId: userId,
        faceIdEnabled: enabled,
      ),
    );

    await _settingsRepository.saveSettings(settings);
  }

  Future<void> _signInWithBiometrics({bool automatic = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    final biometricEnabled = await _secureStorage.isBiometricEnabled();
    if (!biometricEnabled) {
      state = state.copyWith(isLoading: false, error: null);
      return;
    }

    // Check if biometrics are available on this device
    final isAvailable = await _biometricService.isAvailable();
    if (!isAvailable) {
      state = state.copyWith(
        isLoading: false,
        error: automatic
            ? null
            : 'Biometric authentication not available on this device',
      );
      return;
    }

    // Check if we have saved credentials from a previous login
    final savedEmail = await _secureStorage.getEmail();
    final savedPassword = await _secureStorage.getPassword();
    if (savedEmail == null || savedPassword == null) {
      await _secureStorage.clearBiometricLoginData();
      state = state.copyWith(
        isLoading: false,
        error:
            'Face ID is no longer available. Please sign in with email to re-enable it.',
      );
      return;
    }

    // Prompt biometric verification
    final authenticated = await _biometricService.authenticate(
      reason: 'Sign in to FieldFlow',
    );

    if (!authenticated) {
      state = state.copyWith(
        isLoading: false,
        error: automatic ? null : 'Authentication cancelled',
      );
      return;
    }

    // Biometric verified — now sign in with saved credentials
    final result = await _authRepository.signIn(
      email: savedEmail,
      password: savedPassword,
    );

    await result.when(
      success: (_) async {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      },
      failure: (message, _) async {
        await _secureStorage.clearBiometricLoginData();
        state = state.copyWith(
          isLoading: false,
          error: 'Saved credentials expired. Please sign in with email.',
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
