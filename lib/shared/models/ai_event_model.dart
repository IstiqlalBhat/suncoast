import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_event_model.freezed.dart';
part 'ai_event_model.g.dart';

enum AiEventType {
  @JsonValue('observation')
  observation,
  @JsonValue('lookup')
  lookup,
  @JsonValue('action')
  action,
}

enum AiEventStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('skipped')
  skipped,
  @JsonValue('failed')
  failed,
}

@freezed
abstract class AiEventModel with _$AiEventModel {
  const factory AiEventModel({
    required String id,
    @JsonKey(name: 'session_id') required String sessionId,
    required AiEventType type,
    required String content,
    @Default('ai') String source,
    @Default(AiEventStatus.completed) AiEventStatus status,
    @JsonKey(name: 'requires_confirmation')
    @Default(false)
    bool requiresConfirmation,
    @JsonKey(name: 'external_record_id') String? externalRecordId,
    @JsonKey(name: 'external_record_url') String? externalRecordUrl,
    @JsonKey(name: 'action_label') String? actionLabel,
    Map<String, dynamic>? metadata,
    double? confidence,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _AiEventModel;

  factory AiEventModel.fromJson(Map<String, dynamic> json) =>
      _$AiEventModelFromJson(json);
}
