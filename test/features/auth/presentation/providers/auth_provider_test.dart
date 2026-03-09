import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:field_flow/core/utils/result.dart';
import 'package:field_flow/features/auth/data/repositories/auth_repository.dart';
import 'package:field_flow/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_flow/features/settings/data/repositories/settings_repository.dart';
import 'package:field_flow/services/biometric/biometric_service.dart';
import 'package:field_flow/services/storage/secure_storage_service.dart';
import 'package:field_flow/shared/models/user_settings_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockBiometricService extends Mock implements BiometricService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const UserSettingsModel(id: '', userId: ''));
  });

  late MockAuthRepository authRepository;
  late MockSettingsRepository settingsRepository;
  late MockBiometricService biometricService;
  late MockSecureStorageService secureStorage;
  late LoginNotifier notifier;

  setUp(() {
    authRepository = MockAuthRepository();
    settingsRepository = MockSettingsRepository();
    biometricService = MockBiometricService();
    secureStorage = MockSecureStorageService();
    notifier = LoginNotifier(
      authRepository: authRepository,
      settingsRepository: settingsRepository,
      biometricService: biometricService,
      secureStorage: secureStorage,
    );
  });

  User buildUser() {
    return const User(
      id: 'user-1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-03-09T00:00:00.000Z',
    );
  }

  test('maybeAutoSignInWithBiometrics skips when biometrics are disabled', () async {
    when(() => secureStorage.isBiometricEnabled()).thenAnswer((_) async => false);

    await notifier.maybeAutoSignInWithBiometrics();

    expect(notifier.state.isAuthenticated, isFalse);
    verifyNever(
      () => authRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('signInWithBiometrics authenticates with saved credentials', () async {
    when(() => secureStorage.isBiometricEnabled()).thenAnswer((_) async => true);
    when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
    when(() => secureStorage.getEmail()).thenAnswer((_) async => 'user@example.com');
    when(() => secureStorage.getPassword()).thenAnswer((_) async => 'secret123');
    when(
      () => biometricService.authenticate(reason: any(named: 'reason')),
    ).thenAnswer((_) async => true);
    when(
      () => authRepository.signIn(
        email: 'user@example.com',
        password: 'secret123',
      ),
    ).thenAnswer((_) async => Result.success(AuthResponse()));

    await notifier.signInWithBiometrics();

    expect(notifier.state.isAuthenticated, isTrue);
    expect(notifier.state.error, isNull);
  });

  test('signIn disables biometric login when checkbox is off', () async {
    when(
      () => authRepository.signIn(
        email: 'user@example.com',
        password: 'secret123',
      ),
    ).thenAnswer(
      (_) async => Result.success(AuthResponse(user: buildUser())),
    );
    when(() => secureStorage.clearBiometricLoginData()).thenAnswer((_) async {});
    when(
      () => settingsRepository.getSettings('user-1'),
    ).thenAnswer(
      (_) async => const Result.success(UserSettingsModel(id: '', userId: 'user-1')),
    );
    when(
      () => settingsRepository.saveSettings(any()),
    ).thenAnswer(
      (_) async => const Result.success(UserSettingsModel(id: '', userId: 'user-1')),
    );

    await notifier.signIn(
      email: 'user@example.com',
      password: 'secret123',
      enableBiometric: false,
    );

    expect(notifier.state.isAuthenticated, isTrue);
    verify(() => secureStorage.clearBiometricLoginData()).called(1);
    verify(
      () => settingsRepository.saveSettings(
        any(
          that: isA<UserSettingsModel>().having(
            (settings) => settings.faceIdEnabled,
            'faceIdEnabled',
            false,
          ),
        ),
      ),
    ).called(1);
  });

  test('signInWithBiometrics clears biometric data when saved credentials fail', () async {
    when(() => secureStorage.isBiometricEnabled()).thenAnswer((_) async => true);
    when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
    when(() => secureStorage.getEmail()).thenAnswer((_) async => 'user@example.com');
    when(() => secureStorage.getPassword()).thenAnswer((_) async => 'stale-secret');
    when(
      () => biometricService.authenticate(reason: any(named: 'reason')),
    ).thenAnswer((_) async => true);
    when(
      () => authRepository.signIn(
        email: 'user@example.com',
        password: 'stale-secret',
      ),
    ).thenAnswer((_) async => const Result.failure('expired'));
    when(() => secureStorage.clearBiometricLoginData()).thenAnswer((_) async {});

    await notifier.signInWithBiometrics();

    expect(notifier.state.isAuthenticated, isFalse);
    expect(
      notifier.state.error,
      'Saved credentials expired. Please sign in with email.',
    );
    verify(() => secureStorage.clearBiometricLoginData()).called(1);
  });

  test('enableBiometricLogin requires saved credentials', () async {
    when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
    when(() => secureStorage.hasSavedCredentials()).thenAnswer((_) async => false);

    final result = await notifier.enableBiometricLogin();

    expect(result.isFailure, isTrue);
    expect(
      result.when(
        success: (_) => null,
        failure: (message, _) => message,
      ),
      'Please sign in with email first to enable Face ID',
    );
    verifyNever(() => secureStorage.setBiometricEnabled(any()));
  });

  test('signIn persists Face ID setting when checkbox is on', () async {
    when(
      () => authRepository.signIn(
        email: 'user@example.com',
        password: 'secret123',
      ),
    ).thenAnswer(
      (_) async => Result.success(AuthResponse(user: buildUser())),
    );
    when(() => secureStorage.isBiometricEnabled()).thenAnswer((_) async => true);
    when(
      () => settingsRepository.getSettings('user-1'),
    ).thenAnswer(
      (_) async => const Result.success(UserSettingsModel(id: '', userId: 'user-1')),
    );
    when(
      () => settingsRepository.saveSettings(any()),
    ).thenAnswer(
      (_) async => const Result.success(
        UserSettingsModel(id: '', userId: 'user-1', faceIdEnabled: true),
      ),
    );

    await notifier.signIn(
      email: 'user@example.com',
      password: 'secret123',
      enableBiometric: true,
    );

    verify(
      () => settingsRepository.saveSettings(
        any(
          that: isA<UserSettingsModel>().having(
            (settings) => settings.faceIdEnabled,
            'faceIdEnabled',
            true,
          ),
        ),
      ),
    ).called(1);
  });
}
