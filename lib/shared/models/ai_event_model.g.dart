// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiEventModel _$AiEventModelFromJson(Map<String, dynamic> json) =>
    _AiEventModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      type: $enumDecode(_$AiEventTypeEnumMap, json['type']),
      content: json['content'] as String,
      source: json['source'] as String? ?? 'ai',
      status:
          $enumDecodeNullable(_$AiEventStatusEnumMap, json['status']) ??
          AiEventStatus.completed,
      requiresConfirmation: json['requires_confirmation'] as bool? ?? false,
      externalRecordId: json['external_record_id'] as String?,
      externalRecordUrl: json['external_record_url'] as String?,
      actionLabel: json['action_label'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AiEventModelToJson(_AiEventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'type': _$AiEventTypeEnumMap[instance.type]!,
      'content': instance.content,
      'source': instance.source,
      'status': _$AiEventStatusEnumMap[instance.status]!,
      'requires_confirmation': instance.requiresConfirmation,
      'external_record_id': instance.externalRecordId,
      'external_record_url': instance.externalRecordUrl,
      'action_label': instance.actionLabel,
      'metadata': instance.metadata,
      'confidence': instance.confidence,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$AiEventTypeEnumMap = {
  AiEventType.observation: 'observation',
  AiEventType.lookup: 'lookup',
  AiEventType.action: 'action',
};

const _$AiEventStatusEnumMap = {
  AiEventStatus.pending: 'pending',
  AiEventStatus.completed: 'completed',
  AiEventStatus.skipped: 'skipped',
  AiEventStatus.failed: 'failed',
};
