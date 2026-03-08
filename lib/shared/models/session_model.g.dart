// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionModel _$SessionModelFromJson(Map<String, dynamic> json) =>
    _SessionModel(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      userId: json['user_id'] as String,
      mode: $enumDecode(_$SessionModeEnumMap, json['mode']),
      status:
          $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.active,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      endedReason: json['ended_reason'] as String?,
      processingError: json['processing_error'] as String?,
      transcript: json['transcript'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$SessionModelToJson(_SessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'activity_id': instance.activityId,
      'user_id': instance.userId,
      'mode': _$SessionModeEnumMap[instance.mode]!,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'started_at': instance.startedAt.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'ended_reason': instance.endedReason,
      'processing_error': instance.processingError,
      'transcript': instance.transcript,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$SessionModeEnumMap = {
  SessionMode.passive: 'passive',
  SessionMode.chat: 'chat',
  SessionMode.media: 'media',
};

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.ended: 'ended',
  SessionStatus.processing: 'processing',
  SessionStatus.failed: 'failed',
};
