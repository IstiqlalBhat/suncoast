import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_summary_model.freezed.dart';
part 'session_summary_model.g.dart';

@freezed
abstract class SessionSummaryModel with _$SessionSummaryModel {
  const factory SessionSummaryModel({
    required String id,
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'observation_summary')
    @Default('')
    String observationSummary,
    @JsonKey(name: 'key_observations') required List<String> keyObservations,
    @JsonKey(name: 'actions_taken') required List<String> actionsTaken,
    @JsonKey(name: 'follow_ups') required List<FollowUpModel> followUps,
    @JsonKey(name: 'action_statuses')
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> actionStatuses,
    @JsonKey(name: 'external_records')
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> externalRecords,
    @JsonKey(name: 'duration_seconds') int? durationSeconds,
    @JsonKey(name: 'confirmed_at') DateTime? confirmedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SessionSummaryModel;

  factory SessionSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryModelFromJson(json);
}

@freezed
abstract class FollowUpModel with _$FollowUpModel {
  const factory FollowUpModel({
    required String description,
    @Default('medium') String priority,
    @JsonKey(name: 'due_date') DateTime? dueDate,
  }) = _FollowUpModel;

  factory FollowUpModel.fromJson(Map<String, dynamic> json) =>
      _$FollowUpModelFromJson(json);
}
