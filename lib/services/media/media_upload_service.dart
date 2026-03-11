import 'dart:io';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_endpoints.dart';

class MediaUploadService {
  final SupabaseClient _supabase;
  final _logger = Logger();
  final _uuid = const Uuid();

  MediaUploadService(this._supabase);

  Future<String?> uploadMedia({
    required File file,
    required String sessionId,
    required String type,
    String? contentType,
  }) async {
    try {
      final extension = file.path.split('.').last;
      final fileName = '${_uuid.v4()}.$extension';
      final storagePath = '$sessionId/$fileName';

      await _supabase.storage
          .from(ApiEndpoints.mediaAttachmentsBucket)
          .upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              contentType: contentType ?? _getContentType(type, extension),
            ),
          );

      _logger.i('Uploaded media to $storagePath');
      return storagePath;
    } catch (e) {
      _logger.e('Failed to upload media: $e');
      return null;
    }
  }

  Future<String?> createSignedUrl(
    String storagePath, {
    int expiresInSeconds = 3600,
  }) async {
    try {
      return await _supabase.storage
          .from(ApiEndpoints.mediaAttachmentsBucket)
          .createSignedUrl(storagePath, expiresInSeconds);
    } catch (e) {
      _logger.e('Failed to create signed URL: $e');
      return null;
    }
  }

  String _getContentType(String type, String extension) {
    return switch (type) {
      'photo' => 'image/${extension == 'jpg' ? 'jpeg' : extension}',
      'video' => 'video/$extension',
      _ => 'application/octet-stream',
    };
  }
}
