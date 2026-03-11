import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/ai_event_model.dart';
import '../../../../shared/models/media_attachment_model.dart';
import '../../../../shared/models/session_model.dart';

class SessionRemoteDatasource {
  final SupabaseClient _supabase;

  const SessionRemoteDatasource(this._supabase);

  Future<SessionModel> createSession({
    required String activityId,
    required String userId,
    required SessionMode mode,
  }) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.sessionsTable)
          .insert({
            'activity_id': activityId,
            'user_id': userId,
            'mode': mode.name,
            'started_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return SessionModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create session: $e');
    }
  }

  Future<SessionModel> endSession(String sessionId) async {
    try {
      return updateSession(sessionId, {
        'ended_at': DateTime.now().toIso8601String(),
        'status': 'ended',
        'ended_reason': 'user_completed',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerException('Failed to end session: $e');
    }
  }

  Future<SessionModel> getSession(String sessionId) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.sessionsTable)
          .select()
          .eq('id', sessionId)
          .single();

      return SessionModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch session: $e');
    }
  }

  Future<SessionModel> updateSession(
    String sessionId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.sessionsTable)
          .update(fields)
          .eq('id', sessionId)
          .select()
          .single();

      return SessionModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update session: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabase
          .from(ApiEndpoints.sessionsTable)
          .delete()
          .eq('id', sessionId);
    } catch (e) {
      throw ServerException('Failed to delete session: $e');
    }
  }

  Future<SessionModel?> getLatestCompletedSessionForActivity(
    String activityId,
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.sessionsTable)
          .select()
          .eq('activity_id', activityId)
          .eq('user_id', userId)
          .not('ended_at', 'is', null)
          .order('ended_at', ascending: false)
          .limit(1);

      final rows = List<Map<String, dynamic>>.from(response as List);
      if (rows.isEmpty) {
        return null;
      }

      return SessionModel.fromJson(rows.first);
    } catch (e) {
      throw ServerException('Failed to fetch latest completed session: $e');
    }
  }

  Future<void> updateTranscript(String sessionId, String transcript) async {
    try {
      await _supabase
          .from(ApiEndpoints.sessionsTable)
          .update({
            'transcript': transcript,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e) {
      throw ServerException('Failed to update transcript: $e');
    }
  }

  Stream<List<AiEventModel>> subscribeToEvents(String sessionId) {
    return _supabase
        .from(ApiEndpoints.aiEventsTable)
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .order('created_at')
        .map(
          (data) => data.map((json) => AiEventModel.fromJson(json)).toList(),
        );
  }

  Future<AiEventModel> updateAiEvent(
    String eventId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.aiEventsTable)
          .update(fields)
          .eq('id', eventId)
          .select()
          .single();

      return AiEventModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update AI event: $e');
    }
  }

  Future<AiEventModel> createAiEvent({
    required String sessionId,
    required AiEventType type,
    required String content,
    String source = 'ai',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.aiEventsTable)
          .insert({
            'session_id': sessionId,
            'type': type.name,
            'content': content,
            'source': source,
            'metadata': metadata,
          })
          .select()
          .single();

      return AiEventModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create AI event: $e');
    }
  }

  Future<void> deleteAiEvent(String eventId) async {
    try {
      await _supabase
          .from(ApiEndpoints.aiEventsTable)
          .delete()
          .eq('id', eventId);
    } catch (e) {
      throw ServerException('Failed to delete AI event: $e');
    }
  }

  Future<List<AiEventModel>> getSessionEvents(String sessionId) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.aiEventsTable)
          .select()
          .eq('session_id', sessionId)
          .order('created_at');

      return (response as List)
          .map((json) => AiEventModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch session events: $e');
    }
  }

  Future<MediaAttachmentModel> createMediaAttachment({
    required String sessionId,
    required MediaType type,
    required String storagePath,
    String? mimeType,
    int? fileSizeBytes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.mediaAttachmentsTable)
          .insert({
            'session_id': sessionId,
            'type': type.name,
            'storage_path': storagePath,
            'mime_type': mimeType,
            'file_size_bytes': fileSizeBytes,
            'metadata': metadata ?? <String, dynamic>{},
          })
          .select()
          .single();

      return MediaAttachmentModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create media attachment: $e');
    }
  }

  Future<MediaAttachmentModel> updateMediaAttachment(
    String attachmentId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.mediaAttachmentsTable)
          .update(fields)
          .eq('id', attachmentId)
          .select()
          .single();

      return MediaAttachmentModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update media attachment: $e');
    }
  }

  Future<List<MediaAttachmentModel>> getMediaAttachments(
    String sessionId,
  ) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.mediaAttachmentsTable)
          .select()
          .eq('session_id', sessionId)
          .order('created_at');

      return (response as List)
          .map(
            (json) =>
                MediaAttachmentModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch media attachments: $e');
    }
  }
}
