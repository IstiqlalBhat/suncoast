import '../../../../core/utils/result.dart';
import '../../../../shared/models/session_model.dart';
import '../../../../shared/models/ai_event_model.dart';
import '../../../../shared/models/media_attachment_model.dart';
import '../datasources/session_remote_datasource.dart';

class SessionRepository {
  final SessionRemoteDatasource _remoteDatasource;

  const SessionRepository({required SessionRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  Future<Result<SessionModel>> createSession({
    required String activityId,
    required String userId,
    required SessionMode mode,
  }) async {
    try {
      final session = await _remoteDatasource.createSession(
        activityId: activityId,
        userId: userId,
        mode: mode,
      );
      return Result.success(session);
    } catch (e) {
      return Result.failure('Failed to create session: $e');
    }
  }

  Future<Result<SessionModel>> endSession(String sessionId) async {
    try {
      final session = await _remoteDatasource.endSession(sessionId);
      return Result.success(session);
    } catch (e) {
      return Result.failure('Failed to end session: $e');
    }
  }

  Future<Result<SessionModel>> getSession(String sessionId) async {
    try {
      final session = await _remoteDatasource.getSession(sessionId);
      return Result.success(session);
    } catch (e) {
      return Result.failure('Failed to fetch session: $e');
    }
  }

  Future<Result<SessionModel>> updateSession(
    String sessionId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final session = await _remoteDatasource.updateSession(sessionId, fields);
      return Result.success(session);
    } catch (e) {
      return Result.failure('Failed to update session: $e');
    }
  }

  Future<Result<void>> deleteSession(String sessionId) async {
    try {
      await _remoteDatasource.deleteSession(sessionId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Failed to delete session: $e');
    }
  }

  Future<Result<SessionModel?>> getLatestCompletedSessionForActivity({
    required String activityId,
    required String userId,
  }) async {
    try {
      final session = await _remoteDatasource
          .getLatestCompletedSessionForActivity(activityId, userId);
      return Result.success(session);
    } catch (e) {
      return Result.failure('Failed to load latest completed session: $e');
    }
  }

  Future<Result<void>> updateTranscript(
    String sessionId,
    String transcript,
  ) async {
    try {
      await _remoteDatasource.updateTranscript(sessionId, transcript);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Failed to update transcript: $e');
    }
  }

  Stream<List<AiEventModel>> subscribeToEvents(String sessionId) {
    return _remoteDatasource.subscribeToEvents(sessionId);
  }

  Future<Result<AiEventModel>> updateAiEvent(
    String eventId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final event = await _remoteDatasource.updateAiEvent(eventId, fields);
      return Result.success(event);
    } catch (e) {
      return Result.failure('Failed to update AI event: $e');
    }
  }

  Future<Result<AiEventModel>> createAiEvent({
    required String sessionId,
    required AiEventType type,
    required String content,
    String source = 'ai',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final event = await _remoteDatasource.createAiEvent(
        sessionId: sessionId,
        type: type,
        content: content,
        source: source,
        metadata: metadata,
      );
      return Result.success(event);
    } catch (e) {
      return Result.failure('Failed to create AI event: $e');
    }
  }

  Future<Result<void>> deleteAiEvent(String eventId) async {
    try {
      await _remoteDatasource.deleteAiEvent(eventId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Failed to delete AI event: $e');
    }
  }

  Future<Result<List<AiEventModel>>> getSessionEvents(String sessionId) async {
    try {
      final events = await _remoteDatasource.getSessionEvents(sessionId);
      return Result.success(events);
    } catch (e) {
      return Result.failure('Failed to fetch events: $e');
    }
  }

  Future<Result<MediaAttachmentModel>> createMediaAttachment({
    required String sessionId,
    required MediaType type,
    required String storagePath,
    String? mimeType,
    int? fileSizeBytes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final attachment = await _remoteDatasource.createMediaAttachment(
        sessionId: sessionId,
        type: type,
        storagePath: storagePath,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        metadata: metadata,
      );
      return Result.success(attachment);
    } catch (e) {
      return Result.failure('Failed to create media attachment: $e');
    }
  }

  Future<Result<MediaAttachmentModel>> updateMediaAttachment(
    String attachmentId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final attachment = await _remoteDatasource.updateMediaAttachment(
        attachmentId,
        fields,
      );
      return Result.success(attachment);
    } catch (e) {
      return Result.failure('Failed to update media attachment: $e');
    }
  }

  Future<Result<List<MediaAttachmentModel>>> getMediaAttachments(
    String sessionId,
  ) async {
    try {
      final attachments = await _remoteDatasource.getMediaAttachments(
        sessionId,
      );
      return Result.success(attachments);
    } catch (e) {
      return Result.failure('Failed to fetch media attachments: $e');
    }
  }
}
