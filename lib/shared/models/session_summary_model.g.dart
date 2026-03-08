// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionSummaryModel _$SessionSummaryModelFromJson(Map<String, dynamic> json) =>
    _SessionSummaryModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      observationSummary: json['observation_summary'] as String? ?? '',
      keyObservations: (json['key_observations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      actionsTaken: (json['actions_taken'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      followUps: (json['follow_ups'] as List<dynamic>)
          .map((e) => FollowUpModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      actionStatuses:
          (json['action_statuses'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const <Map<String, dynamic>>[],
      externalRecords:
          (json['external_records'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const <Map<String, dynamic>>[],
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SessionSummaryModelToJson(
  _SessionSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'session_id': instance.sessionId,
  'observation_summary': instance.observationSummary,
  'key_observations': instance.keyObservations,
  'actions_taken': instance.actionsTaken,
  'follow_ups': instance.followUps,
  'action_statuses': instance.actionStatuses,
  'external_records': instance.externalRecords,
  'duration_seconds': instance.durationSeconds,
  'confirmed_at': instance.confirmedAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
};

_FollowUpModel _$FollowUpModelFromJson(Map<String, dynamic> json) =>
    _FollowUpModel(
      description: json['description'] as String,
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
    );

Map<String, dynamic> _$FollowUpModelToJson(_FollowUpModel instance) =>
    <String, dynamic>{
      'description': instance.description,
      'priority': instance.priority,
      'due_date': instance.dueDate?.toIso8601String(),
    };
