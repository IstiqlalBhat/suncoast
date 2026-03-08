// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityModel _$ActivityModelFromJson(Map<String, dynamic> json) =>
    _ActivityModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
      status:
          $enumDecodeNullable(_$ActivityStatusEnumMap, json['status']) ??
          ActivityStatus.pending,
      location: json['location'] as String?,
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.parse(json['scheduled_at'] as String),
      assignedTo: json['assigned_to'] as String?,
      orgId: json['org_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ActivityModelToJson(_ActivityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$ActivityTypeEnumMap[instance.type]!,
      'status': _$ActivityStatusEnumMap[instance.status]!,
      'location': instance.location,
      'scheduled_at': instance.scheduledAt?.toIso8601String(),
      'assigned_to': instance.assignedTo,
      'org_id': instance.orgId,
      'metadata': instance.metadata,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$ActivityTypeEnumMap = {
  ActivityType.passive: 'passive',
  ActivityType.twoway: 'twoway',
  ActivityType.media: 'media',
};

const _$ActivityStatusEnumMap = {
  ActivityStatus.pending: 'pending',
  ActivityStatus.inProgress: 'in_progress',
  ActivityStatus.completed: 'completed',
  ActivityStatus.cancelled: 'cancelled',
};
