import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_settings_model.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository.dart';

final settingsRemoteDatasourceProvider = Provider<SettingsRemoteDatasource>((ref) {
  return SettingsRemoteDatasource(ref.watch(supabaseClientProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    remoteDatasource: ref.watch(settingsRemoteDatasourceProvider),
  );
});

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, UserSettingsModel>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<UserSettingsModel> {
  @override
  Future<UserSettingsModel> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userId = user.id;
    final repo = ref.read(settingsRepositoryProvider);
    final secureStorage = ref.read(secureStorageServiceProvider);
    final faceIdEnabled = await secureStorage.isBiometricEnabled();
    final result = await repo.getSettings(userId);
    return result.when(
      success: (data) => data.copyWith(faceIdEnabled: faceIdEnabled),
      failure: (message, _) => throw Exception(message),
    );
  }

  Future<String?> updateFaceId(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return 'Settings not loaded yet';

    final loginNotifier = ref.read(loginProvider.notifier);
    final secureStorage = ref.read(secureStorageServiceProvider);

    if (enabled) {
      final setupResult = await loginNotifier.enableBiometricLogin();
      final setupError = setupResult.when(
        success: (_) => null,
        failure: (message, _) => message,
      );
      if (setupError != null) return setupError;

      final saveError = await _save(current.copyWith(faceIdEnabled: true));
      if (saveError != null) {
        await secureStorage.setBiometricEnabled(false);
      }
      return saveError;
    }

    await loginNotifier.disableBiometricLogin();
    final saveError = await _save(current.copyWith(faceIdEnabled: false));
    if (saveError != null) {
      await secureStorage.setBiometricEnabled(true);
      return saveError;
    }
    return null;
  }

  Future<String?> updateVoiceOutput(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return 'Settings not loaded yet';
    return _save(current.copyWith(voiceOutputEnabled: enabled));
  }

  Future<String?> updatePremiumTts(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return 'Settings not loaded yet';
    return _save(current.copyWith(usePremiumTts: enabled));
  }

  Future<String?> updateVoiceSpeed(double speed) async {
    final current = state.valueOrNull;
    if (current == null) return 'Settings not loaded yet';
    return _save(current.copyWith(voiceSpeed: speed));
  }

  Future<String?> updateConfirmationMode(ConfirmationMode mode) async {
    final current = state.valueOrNull;
    if (current == null) return 'Settings not loaded yet';
    return _save(current.copyWith(confirmationMode: mode));
  }

  Future<String?> updateLanguage(String language) async {
    final current = state.valueOrNull;
    if (current == null) return 'Settings not loaded yet';
    return _save(current.copyWith(language: language));
  }

  Future<String?> _save(UserSettingsModel settings) async {
    final previous = state.valueOrNull;
    state = AsyncValue.data(settings);
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveSettings(settings);
    return result.when(
      success: (saved) {
        state = AsyncValue.data(saved);
        return null;
      },
      failure: (message, _) {
        if (previous != null) {
          state = AsyncValue.data(previous);
        }
        return message;
      },
    );
  }
}
