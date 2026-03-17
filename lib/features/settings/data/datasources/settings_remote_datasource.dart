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
      final payload = {
        'user_id': settings.userId,
        'face_id_enabled': settings.faceIdEnabled,
        'voice_output_enabled': settings.voiceOutputEnabled,
        'voice_id': settings.voiceId,
        'voice_speed': settings.voiceSpeed,
        'confirmation_mode': settings.confirmationMode.name,
        'language': settings.language,
        'use_premium_tts': settings.usePremiumTts,
        'elevenlabs_enabled': settings.elevenlabsEnabled,
        'stt_engine': settings.sttEngine.name,
      };

      final response = await _supabase
          .from(ApiEndpoints.userSettingsTable)
          .upsert(payload, onConflict: 'user_id')
          .select()
          .single();

      return UserSettingsModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to save settings: $e');
    }
  }
}
