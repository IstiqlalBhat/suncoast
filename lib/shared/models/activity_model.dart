import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_model.freezed.dart';
part 'activity_model.g.dart';

enum ActivityType {
  @JsonValue('passive')
  passive,
  @JsonValue('twoway')
  twoway,
  @JsonValue('media')
  media,
}

enum ActivityStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

@freezed
abstract class ActivityModel with _$ActivityModel {
  const factory ActivityModel({
    required String id,
    required String title,
    String? description,
    required ActivityType type,
    @Default(ActivityStatus.pending) ActivityStatus status,
    String? location,
    @JsonKey(name: 'scheduled_at') DateTime? scheduledAt,
    @JsonKey(name: 'assigned_to') String? assignedTo,
    @JsonKey(name: 'org_id') String? orgId,
    Map<String, dynamic>? metadata,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ActivityModel;

  factory ActivityModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityModelFromJson(json);
}

extension ActivityTypeX on ActivityType {
  String get routeSegment => switch (this) {
    ActivityType.passive => 'passive',
    ActivityType.twoway => 'chat',
    ActivityType.media => 'media',
  };

  String get displayName => switch (this) {
    ActivityType.passive => 'Passive Listen',
    ActivityType.twoway => 'Voice Chat',
    ActivityType.media => 'Media Capture',
  };
}
