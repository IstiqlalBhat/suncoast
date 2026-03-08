import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_settings_model.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/providers/auth_providers.dart';
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
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.getSettings(userId);
    return result.when(
      success: (data) => data,
      failure: (message, _) => throw Exception(message),
    );
  }

  Future<void> updateFaceId(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(faceIdEnabled: enabled));
  }

  Future<void> updateVoiceOutput(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(voiceOutputEnabled: enabled));
  }

  Future<void> updatePremiumTts(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(usePremiumTts: enabled));
  }

  Future<void> updateVoiceSpeed(double speed) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(voiceSpeed: speed));
  }

  Future<void> updateConfirmationMode(ConfirmationMode mode) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(confirmationMode: mode));
  }

  Future<void> updateLanguage(String language) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _save(current.copyWith(language: language));
  }

  Future<void> _save(UserSettingsModel settings) async {
    state = AsyncValue.data(settings);
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveSettings(settings);
    result.when(
      success: (saved) => state = AsyncValue.data(saved),
      failure: (message, _) {
        // Revert on error
        state = AsyncValue.error(Exception(message), StackTrace.current);
      },
    );
  }
}
