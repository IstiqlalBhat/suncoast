import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/ai_event_model.dart';
import '../../shared/models/media_attachment_model.dart';
import '../../shared/models/session_summary_model.dart';
import 'ai_service.dart';

class AiServiceImpl implements AiService {
  final ApiClient _apiClient;
  final _logger = Logger();

  AiServiceImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  @override
  Stream<String> streamTranscription(Stream<List<int>> audio) async* {
    // Not used - transcription is handled in session_provider via REST chunking
    yield '';
  }

  @override
  Future<List<AiEventModel>> processPassiveSession(
    String transcript,
    String activityContext,
  ) async {
    try {
      final response = await _apiClient.callFunction(
        'processTranscript',
        data: {
          'transcript': transcript,
          'activityContext': activityContext,
        },
      );

      final events = (response['events'] as List?)
              ?.map((e) => AiEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return events;
    } catch (e) {
      _logger.e('Failed to process passive session: $e');
      rethrow;
    }
  }

  @override
  Future<AiChatResponse> chat(
    String userMessage,
    String sessionContext,
  ) async {
    try {
      final response = await _apiClient.callFunction(
        'chat',
        data: {
          'message': userMessage,
          'sessionContext': sessionContext,
        },
      );

      return AiChatResponse(
        message: response['message'] as String? ?? '',
        events: (response['events'] as List?)
                ?.map((e) => AiEventModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        referenceCards: (response['referenceCards'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
      );
    } catch (e) {
      _logger.e('Chat failed: $e');
      rethrow;
    }
  }

  @override
  Future<AiVisionResult> analyzeImage(
    List<int> imageBytes,
    String context,
  ) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final response = await _apiClient.callFunction(
        'analyzeImage',
        data: {
          'image': base64Image,
          'context': context,
        },
      );

      return AiVisionResult(
        analysis: response['analysis'] as String? ?? '',
        event: response['event'] != null
            ? AiEventModel.fromJson(response['event'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      _logger.e('Image analysis failed: $e');
      rethrow;
    }
  }

  @override
  Future<SessionSummaryModel> generateSummary(
    String sessionId,
    List<AiEventModel> events,
    List<MediaAttachmentModel> attachments,
  ) async {
    try {
      final response = await _apiClient.callFunction(
        'generateSummary',
        data: {
          'sessionId': sessionId,
        },
      );

      return SessionSummaryModel.fromJson(
        response['summary'] as Map<String, dynamic>,
      );
    } catch (e) {
      _logger.e('Summary generation failed: $e');
      rethrow;
    }
  }
}
