import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings_model.freezed.dart';
part 'user_settings_model.g.dart';

enum ConfirmationMode {
  @JsonValue('always')
  always,
  @JsonValue('smart')
  smart,
  @JsonValue('off')
  off,
}

enum SttEngine {
  @JsonValue('device')
  device,
  @JsonValue('cloud')
  cloud,
}

@freezed
abstract class UserSettingsModel with _$UserSettingsModel {
  const factory UserSettingsModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'face_id_enabled') @Default(false) bool faceIdEnabled,
    @JsonKey(name: 'voice_output_enabled') @Default(true) bool voiceOutputEnabled,
    @JsonKey(name: 'voice_id') String? voiceId,
    @JsonKey(name: 'voice_speed') @Default(1.0) double voiceSpeed,
    @JsonKey(name: 'confirmation_mode') @Default(ConfirmationMode.smart) ConfirmationMode confirmationMode,
    @Default('en') String language,
    @JsonKey(name: 'use_premium_tts') @Default(true) bool usePremiumTts,
    @JsonKey(name: 'stt_engine') @Default(SttEngine.cloud) SttEngine sttEngine,
  }) = _UserSettingsModel;

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsModelFromJson(json);
}
