import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../features/session/presentation/models/conversation_entry.dart';

enum VoiceSessionStatus { disconnected, connecting, connected, error }

class OpenAiRealtimeVoiceService {
  final _logger = Logger();

  // WebSocket
  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSub;

  // Audio output — gapless streaming via ConcatenatingAudioSource
  final AudioPlayer _audioPlayer = AudioPlayer();
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final List<int> _audioOutputBuffer = [];
  int _chunkIndex = 0;
  Timer? _audioFlushTimer;
  bool _playerStarted = false;
  final List<String> _tempFiles = [];
  StreamSubscription? _playerStateSubscription;
  Timer? _speakingEndTimer;
  bool _aiSpeaking = false;

  // State
  VoiceSessionStatus _status = VoiceSessionStatus.disconnected;

  // Stream controllers
  final _statusController = StreamController<VoiceSessionStatus>.broadcast();
  final _toolCallController = StreamController<ToolCallRequest>.broadcast();
  final _userTranscriptController = StreamController<String>.broadcast();
  final _aiTranscriptController = StreamController<String>.broadcast();
  final _aiSpeakingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Function call accumulation
  String? _currentFunctionCallId;
  String? _currentFunctionName;
  final StringBuffer _functionCallArgs = StringBuffer();

  // Public streams
  Stream<VoiceSessionStatus> get statusStream => _statusController.stream;
  Stream<ToolCallRequest> get toolCallStream => _toolCallController.stream;
  Stream<String> get userTranscriptStream => _userTranscriptController.stream;
  Stream<String> get aiTranscriptStream => _aiTranscriptController.stream;
  Stream<bool> get aiSpeakingStream => _aiSpeakingController.stream;
  Stream<String> get errorStream => _errorController.stream;
  VoiceSessionStatus get status => _status;
  bool get isConnected => _status == VoiceSessionStatus.connected;
  bool get isAiSpeaking => _aiSpeaking;

  static const int outputSampleRate = 24000;

  Future<void> connect({
    required String clientSecret,
    required String model,
    required String instructions,
  }) async {
    if (isConnected) return;

    _updateStatus(VoiceSessionStatus.connecting);

    try {
      _setupPlayerListener();

      final socket = await WebSocket.connect(
        'wss://api.openai.com/v1/realtime?model=${Uri.encodeQueryComponent(model)}',
        headers: {
          'Authorization': 'Bearer $clientSecret',
          'OpenAI-Beta': 'realtime=v1',
        },
      );

      _socket = socket;
      _socketSub = socket.listen(
        _handleMessage,
        onDone: _handleClosed,
        onError: _handleError,
        cancelOnError: false,
      );

      // Send session.update to configure the session
      _sendEvent({
        'type': 'session.update',
        'session': {
          'modalities': ['text', 'audio'],
          'instructions': instructions,
          'input_audio_format': 'pcm16',
          'output_audio_format': 'pcm16',
          'turn_detection': {
            'type': 'server_vad',
            'threshold': 0.5,
            'prefix_padding_ms': 300,
            'silence_duration_ms': 500,
          },
          'tools': [
            {
              'type': 'function',
              'name': 'request_image',
              'description': 'Request the user to take or upload a photo.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'reason': {
                    'type': 'string',
                    'description': 'Why you need an image',
                  },
                },
                'required': ['reason'],
              },
            },
            {
              'type': 'function',
              'name': 'request_pdf',
              'description': 'Request the user to upload a PDF document.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'reason': {
                    'type': 'string',
                    'description': 'Why you need a PDF',
                  },
                },
                'required': ['reason'],
              },
            },
          ],
          'input_audio_transcription': {
            'model': 'whisper-1',
          },
          'max_response_output_tokens': 4096,
        },
      });

      _updateStatus(VoiceSessionStatus.connected);
      _logger.i('OpenAI realtime voice session connected with model=$model');
    } catch (e) {
      _logger.e('Failed to connect OpenAI realtime voice: $e');
      _updateStatus(VoiceSessionStatus.error);
      _errorController.add('Failed to connect: $e');
      rethrow;
    }
  }

  void sendAudioChunk(List<int> pcm16Bytes) {
    if (!isConnected || _socket == null) return;

    try {
      final base64Audio = base64Encode(pcm16Bytes);
      _sendEvent({
        'type': 'input_audio_buffer.append',
        'audio': base64Audio,
      });
    } catch (e) {
      _logger.e('Failed to send audio chunk: $e');
    }
  }

  void sendMediaContext({String? textContent}) {
    if (!isConnected || _socket == null || textContent == null) return;

    // Cancel any in-progress response first
    _sendEvent({'type': 'response.cancel'});

    _sendEvent({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {
            'type': 'input_text',
            'text': textContent,
          },
        ],
      },
    });

    // Trigger a response after injecting context
    _sendEvent({
      'type': 'response.create',
    });
  }

  void submitToolResult(String callId, String result) {
    if (!isConnected || _socket == null) return;

    _sendEvent({
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': callId,
        'output': result,
      },
    });

    _sendEvent({'type': 'response.create'});
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final event = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = event['type'] as String? ?? '';

      switch (type) {
        case 'session.created':
        case 'session.updated':
          _logger.i('Session event: $type');
          break;

        case 'response.audio.delta':
          final delta = event['delta'] as String?;
          if (delta != null) {
            _handleAudioChunk(delta);
          }
          break;

        case 'response.audio.done':
          // Flush remaining audio
          _audioFlushTimer?.cancel();
          _flushAudioToQueue();
          break;

        case 'response.audio_transcript.delta':
          final delta = event['delta'] as String? ?? '';
          if (delta.isNotEmpty) {
            _aiTranscriptController.add(delta);
          }
          break;

        case 'response.audio_transcript.done':
          final transcript = event['transcript'] as String? ?? '';
          if (transcript.isNotEmpty) {
            _aiTranscriptController.add(transcript);
          }
          break;

        case 'conversation.item.input_audio_transcription.completed':
          final transcript = event['transcript'] as String? ?? '';
          if (transcript.trim().isNotEmpty) {
            _userTranscriptController.add(transcript.trim());
          }
          break;

        case 'input_audio_buffer.speech_started':
          _handleInterruption();
          break;

        case 'input_audio_buffer.speech_stopped':
          break;

        case 'response.function_call_arguments.delta':
          final callId = event['call_id'] as String?;
          final name = event['name'] as String?;
          final delta = event['delta'] as String? ?? '';
          if (callId != null && _currentFunctionCallId == null) {
            _currentFunctionCallId = callId;
            _currentFunctionName = name;
            _functionCallArgs.clear();
          }
          _functionCallArgs.write(delta);
          break;

        case 'response.function_call_arguments.done':
          final callId = event['call_id'] as String? ?? _currentFunctionCallId;
          final name = event['name'] as String? ?? _currentFunctionName;
          final argsJson = event['arguments'] as String? ?? _functionCallArgs.toString();

          if (callId != null && name != null) {
            _handleFunctionCall(callId, name, argsJson);
          }
          _currentFunctionCallId = null;
          _currentFunctionName = null;
          _functionCallArgs.clear();
          break;

        case 'response.done':
          break;

        case 'error':
          final errorObj = event['error'];
          String message = 'Unknown error';
          if (errorObj is Map<String, dynamic>) {
            message = errorObj['message'] as String? ?? message;
          }
          _logger.e('OpenAI realtime error: $message');
          _errorController.add(message);
          break;

        default:
          break;
      }
    } catch (e) {
      _logger.e('Failed to process realtime voice event: $e');
    }
  }

  void _handleFunctionCall(String callId, String name, String argsJson) {
    try {
      final args = jsonDecode(argsJson) as Map<String, dynamic>;
      final reason = args['reason'] as String? ?? '';

      _toolCallController.add(ToolCallRequest(
        callId: callId,
        toolName: name,
        reason: reason,
      ));
    } catch (e) {
      _logger.e('Failed to parse function call: $e');
      // Submit error result so AI can continue
      submitToolResult(callId, '{"error": "Failed to process request"}');
    }
  }

  // ── Audio output pipeline (same pattern as ElevenLabs) ──────────

  void _setupPlayerListener() {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && _aiSpeaking) {
        _speakingEndTimer?.cancel();
        _speakingEndTimer = Timer(const Duration(milliseconds: 800), () {
          if (_audioPlayer.processingState == ProcessingState.completed) {
            _setAiSpeaking(false);
            _resetPlaylist();
            _cleanupTempFiles();
          }
        });
      }
    });
  }

  void _handleAudioChunk(String base64Audio) {
    final bytes = base64Decode(base64Audio);
    _audioOutputBuffer.addAll(bytes);

    if (!_aiSpeaking) {
      _setAiSpeaking(true);
    }

    // Flush when we have ~1.5 seconds of audio
    final flushThreshold = (outputSampleRate * 1.5 * 2).toInt();
    if (_audioOutputBuffer.length >= flushThreshold) {
      _flushAudioToQueue();
    }

    _audioFlushTimer?.cancel();
    _audioFlushTimer = Timer(
      const Duration(milliseconds: 400),
      _flushAudioToQueue,
    );
  }

  Future<void> _flushAudioToQueue() async {
    if (_audioOutputBuffer.isEmpty) return;

    final pcm = Uint8List.fromList(_audioOutputBuffer);
    _audioOutputBuffer.clear();

    final wav = _wrapPcmAsWav(pcm, sampleRate: outputSampleRate);

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/oai_voice_chunk_${_chunkIndex++}.wav';
      await File(filePath).writeAsBytes(wav, flush: true);
      _tempFiles.add(filePath);

      _speakingEndTimer?.cancel();

      await _playlist.add(AudioSource.file(filePath));

      if (!_playerStarted) {
        _playerStarted = true;
        await _audioPlayer.setAudioSource(_playlist, initialIndex: 0);
        await _audioPlayer.setVolume(1.0);
        _audioPlayer.play();
      } else if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero, index: _playlist.length - 1);
        _audioPlayer.play();
      }
    } catch (e) {
      _logger.e('Failed to flush audio: $e');
    }
  }

  void _handleInterruption() {
    _audioOutputBuffer.clear();
    _audioFlushTimer?.cancel();
    _speakingEndTimer?.cancel();
    _audioPlayer.stop();
    _resetPlaylist();
    _cleanupTempFiles();
    _setAiSpeaking(false);
  }

  void _resetPlaylist() {
    _playerStarted = false;
    _playlist = ConcatenatingAudioSource(children: []);
    _chunkIndex = 0;
  }

  void _cleanupTempFiles() {
    for (final path in _tempFiles) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    _tempFiles.clear();
  }

  // ── Helpers ──────────────────────────────────────────────────────

  void _updateStatus(VoiceSessionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void _setAiSpeaking(bool speaking) {
    if (_aiSpeaking != speaking) {
      _aiSpeaking = speaking;
      _aiSpeakingController.add(speaking);
    }
  }

  void _sendEvent(Map<String, dynamic> event) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return;
    socket.add(jsonEncode(event));
  }

  void _handleClosed() {
    _logger.w('OpenAI realtime voice socket closed');
    _updateStatus(VoiceSessionStatus.disconnected);
  }

  void _handleError(Object error) {
    _logger.e('OpenAI realtime voice socket error: $error');
    _updateStatus(VoiceSessionStatus.error);
    _errorController.add('Connection error');
  }

  Future<void> stop() async {
    _audioFlushTimer?.cancel();
    _speakingEndTimer?.cancel();
    _playerStateSubscription?.cancel();
    await _socketSub?.cancel();
    _socketSub = null;

    await _audioPlayer.stop();
    _audioOutputBuffer.clear();
    _resetPlaylist();
    _cleanupTempFiles();

    final socket = _socket;
    _socket = null;
    if (socket != null) {
      await socket.close();
    }

    _updateStatus(VoiceSessionStatus.disconnected);
    _logger.i('OpenAI realtime voice session stopped');
  }

  Future<void> dispose() async {
    await stop();
    await _statusController.close();
    await _toolCallController.close();
    await _userTranscriptController.close();
    await _aiTranscriptController.close();
    await _aiSpeakingController.close();
    await _errorController.close();
    await _audioPlayer.dispose();
  }

  static Uint8List _wrapPcmAsWav(Uint8List pcmData, {int sampleRate = 24000}) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final wav = Uint8List(44 + dataSize);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + dataSize, pcmData);
    return wav;
  }
}
