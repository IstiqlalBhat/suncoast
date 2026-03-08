import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

enum SessionMode {
  @JsonValue('passive')
  passive,
  @JsonValue('chat')
  chat,
  @JsonValue('media')
  media,
}

enum SessionStatus {
  @JsonValue('active')
  active,
  @JsonValue('ended')
  ended,
  @JsonValue('processing')
  processing,
  @JsonValue('failed')
  failed,
}

@freezed
abstract class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String id,
    @JsonKey(name: 'activity_id') required String activityId,
    @JsonKey(name: 'user_id') required String userId,
    required SessionMode mode,
    @Default(SessionStatus.active) SessionStatus status,
    @JsonKey(name: 'started_at') required DateTime startedAt,
    @JsonKey(name: 'ended_at') DateTime? endedAt,
    @JsonKey(name: 'ended_reason') String? endedReason,
    @JsonKey(name: 'processing_error') String? processingError,
    String? transcript,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}
