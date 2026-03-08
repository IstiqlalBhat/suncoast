import '../../shared/models/ai_event_model.dart';
import '../../shared/models/media_attachment_model.dart';
import '../../shared/models/session_summary_model.dart';

class AiChatResponse {
  final String message;
  final List<AiEventModel> events;
  final List<Map<String, dynamic>> referenceCards;

  const AiChatResponse({
    required this.message,
    this.events = const [],
    this.referenceCards = const [],
  });
}

class AiVisionResult {
  final String analysis;
  final AiEventModel? event;

  const AiVisionResult({
    required this.analysis,
    this.event,
  });
}

abstract class AiService {
  Stream<String> streamTranscription(Stream<List<int>> audio);

  Future<List<AiEventModel>> processPassiveSession(
    String transcript,
    String activityContext,
  );

  Future<AiChatResponse> chat(
    String userMessage,
    String sessionContext,
  );

  Future<AiVisionResult> analyzeImage(
    List<int> imageBytes,
    String context,
  );

  Future<SessionSummaryModel> generateSummary(
    String sessionId,
    List<AiEventModel> events,
    List<MediaAttachmentModel> attachments,
  );
}
