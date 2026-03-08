import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_attachment_model.freezed.dart';
part 'media_attachment_model.g.dart';

enum MediaType {
  @JsonValue('photo')
  photo,
  @JsonValue('video')
  video,
  @JsonValue('file')
  file,
}

@freezed
abstract class MediaAttachmentModel with _$MediaAttachmentModel {
  const factory MediaAttachmentModel({
    required String id,
    @JsonKey(name: 'session_id') required String sessionId,
    required MediaType type,
    @JsonKey(name: 'storage_path') required String storagePath,
    @JsonKey(name: 'thumbnail_path') String? thumbnailPath,
    @JsonKey(name: 'ai_analysis') String? aiAnalysis,
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'file_size_bytes') int? fileSizeBytes,
    @JsonKey(name: 'analysis_status') @Default('pending') String analysisStatus,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
    @JsonKey(name: 'uploaded_at') DateTime? uploadedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _MediaAttachmentModel;

  factory MediaAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$MediaAttachmentModelFromJson(json);
}
