// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserSettingsModel _$UserSettingsModelFromJson(Map<String, dynamic> json) =>
    _UserSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      faceIdEnabled: json['face_id_enabled'] as bool? ?? false,
      voiceOutputEnabled: json['voice_output_enabled'] as bool? ?? true,
      voiceId: json['voice_id'] as String?,
      voiceSpeed: (json['voice_speed'] as num?)?.toDouble() ?? 1.0,
      confirmationMode:
          $enumDecodeNullable(
            _$ConfirmationModeEnumMap,
            json['confirmation_mode'],
          ) ??
          ConfirmationMode.smart,
      language: json['language'] as String? ?? 'en',
      usePremiumTts: json['use_premium_tts'] as bool? ?? true,
      elevenlabsEnabled: json['elevenlabs_enabled'] as bool? ?? true,
      sttEngine:
          $enumDecodeNullable(_$SttEngineEnumMap, json['stt_engine']) ??
          SttEngine.cloud,
    );

Map<String, dynamic> _$UserSettingsModelToJson(
  _UserSettingsModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'face_id_enabled': instance.faceIdEnabled,
  'voice_output_enabled': instance.voiceOutputEnabled,
  'voice_id': instance.voiceId,
  'voice_speed': instance.voiceSpeed,
  'confirmation_mode': _$ConfirmationModeEnumMap[instance.confirmationMode]!,
  'language': instance.language,
  'use_premium_tts': instance.usePremiumTts,
  'elevenlabs_enabled': instance.elevenlabsEnabled,
  'stt_engine': _$SttEngineEnumMap[instance.sttEngine]!,
};

const _$ConfirmationModeEnumMap = {
  ConfirmationMode.always: 'always',
  ConfirmationMode.smart: 'smart',
  ConfirmationMode.off: 'off',
};

const _$SttEngineEnumMap = {
  SttEngine.device: 'device',
  SttEngine.cloud: 'cloud',
};
