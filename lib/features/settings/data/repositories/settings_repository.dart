import '../../../../core/utils/result.dart';
import '../../../../shared/models/user_settings_model.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepository {
  final SettingsRemoteDatasource _remoteDatasource;

  const SettingsRepository({
    required SettingsRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  Future<Result<UserSettingsModel>> getSettings(String userId) async {
    try {
      final settings = await _remoteDatasource.getSettings(userId);
      if (settings == null) {
        // Return default settings
        return Result.success(UserSettingsModel(
          id: '',
          userId: userId,
        ));
      }
      return Result.success(settings);
    } catch (e) {
      return Result.failure('Failed to load settings: $e');
    }
  }

  Future<Result<UserSettingsModel>> saveSettings(
    UserSettingsModel settings,
  ) async {
    try {
      final saved = await _remoteDatasource.upsertSettings(settings);
      return Result.success(saved);
    } catch (e) {
      return Result.failure('Failed to save settings: $e');
    }
  }
}
