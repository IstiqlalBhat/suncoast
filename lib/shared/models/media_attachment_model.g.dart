// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_attachment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaAttachmentModel _$MediaAttachmentModelFromJson(
  Map<String, dynamic> json,
) => _MediaAttachmentModel(
  id: json['id'] as String,
  sessionId: json['session_id'] as String,
  type: $enumDecode(_$MediaTypeEnumMap, json['type']),
  storagePath: json['storage_path'] as String,
  thumbnailPath: json['thumbnail_path'] as String?,
  aiAnalysis: json['ai_analysis'] as String?,
  mimeType: json['mime_type'] as String?,
  fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
  analysisStatus: json['analysis_status'] as String? ?? 'pending',
  metadata:
      json['metadata'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  uploadedAt: json['uploaded_at'] == null
      ? null
      : DateTime.parse(json['uploaded_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MediaAttachmentModelToJson(
  _MediaAttachmentModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'session_id': instance.sessionId,
  'type': _$MediaTypeEnumMap[instance.type]!,
  'storage_path': instance.storagePath,
  'thumbnail_path': instance.thumbnailPath,
  'ai_analysis': instance.aiAnalysis,
  'mime_type': instance.mimeType,
  'file_size_bytes': instance.fileSizeBytes,
  'analysis_status': instance.analysisStatus,
  'metadata': instance.metadata,
  'uploaded_at': instance.uploadedAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$MediaTypeEnumMap = {
  MediaType.photo: 'photo',
  MediaType.video: 'video',
  MediaType.file: 'file',
};
