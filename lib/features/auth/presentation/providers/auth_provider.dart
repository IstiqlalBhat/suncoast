import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../../../../services/biometric/biometric_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository.dart';

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

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(
    authRepository: ref.watch(authRepositoryProvider),
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
  final BiometricService _biometricService;
  final SecureStorageService _secureStorage;

  LoginNotifier({
    required AuthRepository authRepository,
    required BiometricService biometricService,
    required SecureStorageService secureStorage,
  })  : _authRepository = authRepository,
        _biometricService = biometricService,
        _secureStorage = secureStorage,
        super(const LoginState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      },
      failure: (message, _) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authRepository.signUp(
      email: email,
      password: password,
      name: name,
    );

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      },
      failure: (message, _) {
        state = state.copyWith(isLoading: false, error: message);
      },
    );
  }

  Future<void> signInWithBiometrics() async {
    state = state.copyWith(isLoading: true, error: null);

    // Check if biometrics are available on this device
    final isAvailable = await _biometricService.isAvailable();
    if (!isAvailable) {
      state = state.copyWith(
        isLoading: false,
        error: 'Biometric authentication not available on this device',
      );
      return;
    }

    // Check if we have saved credentials from a previous login
    final savedEmail = await _secureStorage.getEmail();
    final savedPassword = await _secureStorage.getPassword();
    if (savedEmail == null || savedPassword == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please sign in with email first to enable Face ID',
      );
      return;
    }

    // Prompt biometric verification
    final authenticated = await _biometricService.authenticate(
      reason: 'Sign in to FieldFlow',
    );

    if (!authenticated) {
      state = state.copyWith(isLoading: false, error: 'Authentication cancelled');
      return;
    }

    // Biometric verified — now sign in with saved credentials
    final result = await _authRepository.signIn(
      email: savedEmail,
      password: savedPassword,
    );

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      },
      failure: (message, _) {
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
