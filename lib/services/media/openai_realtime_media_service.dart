import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

import '../../core/network/api_client.dart';

class RealtimeMediaAnalysisResult {
  final String analysis;

  const RealtimeMediaAnalysisResult({required this.analysis});
}

class _PendingRealtimeAnalysis {
  final void Function(String partialText) onPartial;
  final Completer<RealtimeMediaAnalysisResult> completer =
      Completer<RealtimeMediaAnalysisResult>();
  final StringBuffer buffer = StringBuffer();

  _PendingRealtimeAnalysis({required this.onPartial});

  String get currentText => buffer.toString().trim();

  void append(String chunk) {
    final trimmedChunk = chunk.trim();
    if (trimmedChunk.isEmpty) {
      return;
    }

    buffer.write(chunk);
    onPartial(buffer.toString().trim());
  }

  void complete([String? fallbackText]) {
    if (completer.isCompleted) {
      return;
    }

    final resolved = currentText.isNotEmpty
        ? currentText
        : (fallbackText ?? '').trim();

    if (resolved.isEmpty) {
      completer.completeError(
        StateError('Realtime analysis completed without any text'),
      );
      return;
    }

    completer.complete(RealtimeMediaAnalysisResult(analysis: resolved));
  }

  void fail(Object error, [StackTrace? stackTrace]) {
    if (completer.isCompleted) {
      return;
    }

    completer.completeError(error, stackTrace);
  }
}

class OpenAiRealtimeMediaService {
  final ApiClient _apiClient;
  final _logger = Logger();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSub;
  Completer<void>? _connectCompleter;
  _PendingRealtimeAnalysis? _pendingAnalysis;
  Future<void> _analysisQueue = Future<void>.value();
  String? _connectedSessionId;

  OpenAiRealtimeMediaService({required ApiClient apiClient})
    : _apiClient = apiClient;

  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;

  Future<void> connect({
    required String sessionId,
    required String activityContext,
  }) async {
    if (isConnected && _connectedSessionId == sessionId) {
      return;
    }

    if (_connectCompleter != null) {
      return _connectCompleter!.future;
    }

    final completer = Completer<void>();
    _connectCompleter = completer;

    try {
      await disconnect();

      final response = await _apiClient.callFunction(
        'createRealtimeMediaSession',
        data: {'sessionId': sessionId, 'activityContext': activityContext},
      );

      final clientSecret = (response['clientSecret'] as String? ?? '').trim();
      final model = (response['model'] as String? ?? 'gpt-realtime').trim();
      final instructions = (response['instructions'] as String? ?? '').trim();

      if (clientSecret.isEmpty) {
        throw StateError(
          'Realtime media session did not return a client secret',
        );
      }

      final socket = await WebSocket.connect(
        'wss://api.openai.com/v1/realtime?model=${Uri.encodeQueryComponent(model)}',
        headers: {'Authorization': 'Bearer $clientSecret'},
      );

      _socket = socket;
      _connectedSessionId = sessionId;
      _socketSub = socket.listen(
        _handleSocketMessage,
        onDone: _handleSocketClosed,
        onError: _handleSocketError,
        cancelOnError: true,
      );

      if (instructions.isNotEmpty) {
        _sendEvent({
          'type': 'session.update',
          'session': {
            'modalities': ['text'],
            'instructions': instructions,
          },
        });
      }

      completer.complete();
      _logger.i('OpenAI realtime media session connected with model=$model');
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      _logger.e('Failed to connect OpenAI realtime media session: $error');
      rethrow;
    } finally {
      _connectCompleter = null;
    }
  }

  Future<RealtimeMediaAnalysisResult> analyzeImage({
    required String sessionId,
    required String activityContext,
    required List<int> imageBytes,
    required String mimeType,
    required String promptContext,
    required void Function(String partialText) onPartial,
  }) {
    final completer = Completer<RealtimeMediaAnalysisResult>();

    _analysisQueue = _analysisQueue.then((_) async {
      try {
        final result = await _runAnalysis(
          sessionId: sessionId,
          activityContext: activityContext,
          imageBytes: imageBytes,
          mimeType: mimeType,
          promptContext: promptContext,
          onPartial: onPartial,
        );
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    });

    return completer.future;
  }

  Future<RealtimeMediaAnalysisResult> _runAnalysis({
    required String sessionId,
    required String activityContext,
    required List<int> imageBytes,
    required String mimeType,
    required String promptContext,
    required void Function(String partialText) onPartial,
  }) async {
    await connect(sessionId: sessionId, activityContext: activityContext);

    if (!isConnected || _socket == null) {
      throw StateError('Realtime media socket is not connected');
    }

    if (_pendingAnalysis != null) {
      throw StateError('Realtime media service already has a pending request');
    }

    final pending = _PendingRealtimeAnalysis(onPartial: onPartial);
    _pendingAnalysis = pending;
    final imageDataUrl = 'data:$mimeType;base64,${base64Encode(imageBytes)}';

    _sendEvent({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {
            'type': 'input_text',
            'text': [
              'Analyze this image for the field worker.',
              'Describe what is visible and how it relates to the field context.',
              'If the image is unclear, ask for one specific follow-up image.',
              '',
              'Field context:',
              promptContext.trim().isEmpty
                  ? activityContext
                  : promptContext.trim(),
            ].join('\n'),
          },
          {'type': 'input_image', 'image_url': imageDataUrl},
        ],
      },
    });

    _sendEvent({
      'type': 'response.create',
      'response': {
        'modalities': ['text'],
        'instructions':
            'Respond with two short sections: "What I see:" and "How it relates:". Keep it concise and practical.',
      },
    });

    try {
      return await pending.completer.future.timeout(
        const Duration(seconds: 45),
      );
    } finally {
      if (identical(_pendingAnalysis, pending)) {
        _pendingAnalysis = null;
      }
    }
  }

  void _handleSocketMessage(dynamic rawMessage) {
    try {
      final event = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = event['type'] as String? ?? '';

      switch (type) {
        case 'response.output_text.delta':
        case 'response.text.delta':
          final delta = (event['delta'] as String? ?? '');
          _pendingAnalysis?.append(delta);
          return;
        case 'response.output_text.done':
        case 'response.text.done':
          final text = (event['text'] as String? ?? '').trim();
          if (text.isNotEmpty &&
              _pendingAnalysis?.currentText.isEmpty == true) {
            _pendingAnalysis?.append(text);
          }
          return;
        case 'response.done':
          final response = event['response'];
          final fallbackText = response is Map<String, dynamic>
              ? _extractResponseText(response)
              : '';
          _pendingAnalysis?.complete(fallbackText);
          _pendingAnalysis = null;
          return;
        case 'error':
          final message = _extractErrorMessage(event);
          _pendingAnalysis?.fail(StateError(message));
          _pendingAnalysis = null;
          return;
        default:
          return;
      }
    } catch (error, stackTrace) {
      _logger.e('Failed to process realtime media event: $error');
      _pendingAnalysis?.fail(error, stackTrace);
      _pendingAnalysis = null;
    }
  }

  String _extractErrorMessage(Map<String, dynamic> event) {
    final error = event['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return 'OpenAI realtime media analysis failed';
  }

  String _extractResponseText(Map<String, dynamic> response) {
    final parts = <String>[];
    final output = response['output'];

    if (output is List) {
      for (final item in output.whereType<Map>()) {
        final typedItem = Map<String, dynamic>.from(item);
        final itemText = typedItem['text'];
        if (itemText is String && itemText.trim().isNotEmpty) {
          parts.add(itemText.trim());
        }

        final content = typedItem['content'];
        if (content is List) {
          for (final part in content.whereType<Map>()) {
            final typedPart = Map<String, dynamic>.from(part);
            final text = typedPart['text'] ?? typedPart['transcript'];
            if (text is String && text.trim().isNotEmpty) {
              parts.add(text.trim());
            }
          }
        }
      }
    }

    final responseText = response['text'];
    if (responseText is String && responseText.trim().isNotEmpty) {
      parts.add(responseText.trim());
    }

    return parts.join('\n').trim();
  }

  void _handleSocketClosed() {
    _logger.w('OpenAI realtime media socket closed');
    _connectedSessionId = null;
    _socket = null;
    _pendingAnalysis?.fail(StateError('Realtime media connection closed'));
    _pendingAnalysis = null;
  }

  void _handleSocketError(Object error) {
    _logger.e('OpenAI realtime media socket error: $error');
    _pendingAnalysis?.fail(error);
    _pendingAnalysis = null;
  }

  void _sendEvent(Map<String, dynamic> event) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) {
      throw StateError('Realtime media socket is not connected');
    }

    socket.add(jsonEncode(event));
  }

  Future<void> disconnect() async {
    await _socketSub?.cancel();
    _socketSub = null;

    final socket = _socket;
    _socket = null;
    _connectedSessionId = null;

    if (socket != null) {
      await socket.close();
    }
  }

  Future<void> dispose() async {
    await disconnect();
  }
}
