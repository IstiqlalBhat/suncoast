import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/user_settings_model.dart';

class SettingsRemoteDatasource {
  final SupabaseClient _supabase;

  const SettingsRemoteDatasource(this._supabase);

  Future<UserSettingsModel?> getSettings(String userId) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.userSettingsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserSettingsModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch settings: $e');
    }
  }

  Future<UserSettingsModel> upsertSettings(UserSettingsModel settings) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.userSettingsTable)
          .upsert(settings.toJson())
          .select()
          .single();

      return UserSettingsModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to save settings: $e');
    }
  }
}
