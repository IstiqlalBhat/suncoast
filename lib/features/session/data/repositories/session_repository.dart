import '../../../../core/utils/result.dart';
import '../../../../shared/models/session_model.dart';
import '../../../../shared/models/ai_event_model.dart';
import '../datasources/session_remote_datasource.dart';

class SessionRepository {
  final SessionRemoteDatasource _remoteDatasource;

  const SessionRepository({
    required SessionRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

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

  Future<Result<void>> updateTranscript(String sessionId, String transcript) async {
    try {
      await _remoteDatasource.updateTranscript(sessionId, transcript);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to update transcript: $e');
    }
  }

  Stream<List<AiEventModel>> subscribeToEvents(String sessionId) {
    return _remoteDatasource.subscribeToEvents(sessionId);
  }

  Future<Result<List<AiEventModel>>> getSessionEvents(String sessionId) async {
    try {
      final events = await _remoteDatasource.getSessionEvents(sessionId);
      return Result.success(events);
    } catch (e) {
      return Result.failure('Failed to fetch events: $e');
    }
  }
}
