import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

enum ConversationStatus { disconnected, connecting, connected, error }

class AgentResponseCorrection {
  final String correctedAgentResponse;
  final String? originalAgentResponse;

  const AgentResponseCorrection({
    required this.correctedAgentResponse,
    this.originalAgentResponse,
  });
}

class ElevenLabsConversationService {
  final ApiClient _apiClient;
  final _logger = Logger();

  // WebSocket
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;

  // Audio output — gapless streaming via ConcatenatingAudioSource
  final AudioPlayer _audioPlayer = AudioPlayer();
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final List<int> _audioOutputBuffer = [];
  int _chunkIndex = 0;
  Timer? _audioFlushTimer;
  int _outputSampleRate = 16000;
  bool _playerStarted = false;
  final List<String> _tempFiles = [];
  StreamSubscription? _playerStateSubscription;
  Timer? _speakingEndTimer;

  // State
  ConversationStatus _status = ConversationStatus.disconnected;
  String? _conversationId;
  bool _agentSpeaking = false;

  // Stream controllers
  final _statusController = StreamController<ConversationStatus>.broadcast();
  final _userTranscriptController = StreamController<String>.broadcast();
  final _agentResponseController = StreamController<String>.broadcast();
  final _agentResponseCorrectionController =
      StreamController<AgentResponseCorrection>.broadcast();
  final _agentSpeakingController = StreamController<bool>.broadcast();
  final _playbackLevelController = StreamController<double>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Public streams
  Stream<ConversationStatus> get statusStream => _statusController.stream;
  Stream<String> get userTranscriptStream => _userTranscriptController.stream;
  Stream<String> get agentResponseStream => _agentResponseController.stream;
  Stream<AgentResponseCorrection> get agentResponseCorrectionStream =>
      _agentResponseCorrectionController.stream;
  Stream<bool> get agentSpeakingStream => _agentSpeakingController.stream;
  Stream<double> get playbackLevelStream => _playbackLevelController.stream;
  Stream<String> get errorStream => _errorController.stream;
  ConversationStatus get status => _status;
  bool get isConnected => _status == ConversationStatus.connected;
  bool get isAgentSpeaking => _agentSpeaking;

  ElevenLabsConversationService({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<http.Response> _requestSignedUrl({bool forceRefresh = false}) async {
    final token = await _apiClient.getValidAccessToken(
      forceRefresh: forceRefresh,
    );
    return http.get(
      Uri.parse('${AppConfig.firebaseFunctionsUrl}/getSignedConversationUrl'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
  }

  /// Start a real-time conversation with the ElevenLabs agent.
  Future<void> start({
    required String sessionId,
    required String activityContext,
  }) async {
    _updateStatus(ConversationStatus.connecting);

    try {
      // Configure audio session for simultaneous recording + playback (iOS)
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
        ),
      );
      _logger.i('Audio session configured for playAndRecord');

      // Set up player completion listener for detecting end of speech
      _setupPlayerListener();

      // Get signed WebSocket URL via HTTP (onRequest function, not onCall)
      var signedUrlResponse = await _requestSignedUrl();
      if (signedUrlResponse.statusCode == 401) {
        signedUrlResponse = await _requestSignedUrl(forceRefresh: true);
      }
      if (signedUrlResponse.statusCode != 200) {
        throw Exception(
          'Failed to get signed URL: ${signedUrlResponse.statusCode} ${signedUrlResponse.body}',
        );
      }
      final response =
          jsonDecode(signedUrlResponse.body) as Map<String, dynamic>;
      final signedUrl = response['signed_url'] as String;
      _logger.i('Got signed conversation URL');

      // Connect WebSocket
      _channel = WebSocketChannel.connect(Uri.parse(signedUrl));
      await _channel!.ready;

      // Listen to WebSocket messages FIRST (before sending init data)
      _wsSubscription = _channel!.stream.listen(
        _onMessage,
        onError: (error) {
          _logger.e('WebSocket error: $error');
          _updateStatus(ConversationStatus.error);
          _errorController.add('Connection lost');
        },
        onDone: () {
          _logger.i('WebSocket closed');
          _updateStatus(ConversationStatus.disconnected);
        },
      );

      // Now send initial client data with session context and audio format
      _channel!.sink.add(
        jsonEncode({
          'type': 'conversation_initiation_client_data',
          'conversation_config_override': {
            'agent': {'prompt': {}, 'first_message': null, 'language': 'en'},
          },
          'dynamic_variables': {
            'session_id': sessionId,
            'activity_context': activityContext,
          },
        }),
      );
      _logger.i(
        'Sent conversation_initiation_client_data with session=$sessionId',
      );

      _updateStatus(ConversationStatus.connected);
      _logger.i('ElevenLabs conversation connected');
    } catch (e) {
      _logger.e('Failed to start conversation: $e');
      _updateStatus(ConversationStatus.error);
      _errorController.add('Failed to connect: $e');
      rethrow;
    }
  }

  /// Send a chunk of raw PCM16 audio from the microphone to the agent.
  void sendAudioChunk(List<int> pcmBytes) {
    if (_channel == null || _status != ConversationStatus.connected) return;

    try {
      final base64Audio = base64Encode(pcmBytes);
      _channel!.sink.add(jsonEncode({'user_audio_chunk': base64Audio}));
    } catch (e) {
      _logger.e('Failed to send audio chunk: $e');
    }
  }

  void sendUserActivity() {
    if (_channel == null || _status != ConversationStatus.connected) return;

    try {
      _channel!.sink.add(jsonEncode({'type': 'user_activity'}));
    } catch (e) {
      _logger.e('Failed to send user_activity: $e');
    }
  }

  void interruptPlayback() {
    _handleInterruption();
  }

  void _onMessage(dynamic rawMessage) {
    try {
      final data = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      _logger.i('WS received: $type');

      switch (type) {
        case 'conversation_initiation_metadata':
          final metadata =
              data['conversation_initiation_metadata_event']
                  as Map<String, dynamic>?;
          _conversationId = metadata?['conversation_id'] as String?;
          final audioFormat = metadata?['agent_output_audio_format'] as String?;
          if (audioFormat != null) {
            _outputSampleRate = _parseSampleRate(audioFormat);
          }
          _logger.i(
            'Conversation initialized: $_conversationId '
            '(audio: $audioFormat)',
          );

        case 'audio':
          final audioEvent = data['audio_event'] as Map<String, dynamic>?;
          final audioBase64 = audioEvent?['audio_base_64'] as String?;
          if (audioBase64 != null) {
            _handleAudioChunk(audioBase64);
          }

        case 'user_transcript':
          final event =
              data['user_transcription_event'] as Map<String, dynamic>?;
          final transcript = (event?['user_transcript'] as String? ?? '')
              .trim();
          if (transcript.isNotEmpty) {
            _userTranscriptController.add(transcript);
          }

        case 'agent_response':
          final event = data['agent_response_event'] as Map<String, dynamic>?;
          final response = (event?['agent_response'] as String? ?? '').trim();
          if (response.isNotEmpty) {
            _agentResponseController.add(response);
          }
          // Flush any remaining buffered audio
          _audioFlushTimer?.cancel();
          _flushAudioToQueue();

        case 'agent_response_correction':
          final event =
              data['agent_response_correction_event'] as Map<String, dynamic>?;
          final corrected =
              (event?['corrected_agent_response'] as String? ?? '').trim();
          final original = (event?['original_agent_response'] as String? ?? '')
              .trim();
          _agentResponseCorrectionController.add(
            AgentResponseCorrection(
              correctedAgentResponse: corrected,
              originalAgentResponse: original.isEmpty ? null : original,
            ),
          );

        case 'ping':
          final eventId =
              (data['ping_event'] as Map<String, dynamic>?)?['event_id'];
          if (eventId != null) {
            _channel?.sink.add(
              jsonEncode({'type': 'pong', 'event_id': eventId}),
            );
          }

        case 'interruption':
          _handleInterruption();

        case 'vad_score':
          final event = data['vad_score_event'] as Map<String, dynamic>?;
          final score = event?['vad_score'];
          if (score != null) {
            _logger.d('VAD score: $score');
          }

        default:
          _logger.d('Unhandled message type: $type');
      }
    } catch (e) {
      _logger.e('Failed to process WebSocket message: $e');
    }
  }

  // ── Audio output pipeline ──────────────────────────────────────────

  void _setupPlayerListener() {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          _agentSpeaking) {
        // Player finished all playlist items — wait briefly for more chunks
        _speakingEndTimer?.cancel();
        _speakingEndTimer = Timer(const Duration(milliseconds: 800), () {
          if (_audioPlayer.processingState == ProcessingState.completed) {
            _setAgentSpeaking(false);
            _resetPlaylist();
            _cleanupTempFiles();
          }
        });
      }
    });
  }

  void _handleAudioChunk(String base64Audio) {
    final bytes = base64Decode(base64Audio);
    _playbackLevelController.add(_computeLevel(bytes));
    _audioOutputBuffer.addAll(bytes);

    if (!_agentSpeaking) {
      _setAgentSpeaking(true);
    }

    // Flush when we have ~1.5 seconds of audio (larger chunks = fewer gaps)
    final flushThreshold = (_outputSampleRate * 1.5 * 2).toInt();
    if (_audioOutputBuffer.length >= flushThreshold) {
      _flushAudioToQueue();
    }

    // Timer to flush remaining audio after last chunk arrives
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

    final wav = _wrapPcmAsWav(pcm, sampleRate: _outputSampleRate);

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/el_chunk_${_chunkIndex++}.wav';
      await File(filePath).writeAsBytes(wav, flush: true);
      _tempFiles.add(filePath);

      // Cancel any pending "done speaking" timer since we have new audio
      _speakingEndTimer?.cancel();

      // Add to the gapless playlist
      await _playlist.add(AudioSource.file(filePath));

      if (!_playerStarted) {
        // First chunk of this response — set audio source and start playing
        _playerStarted = true;
        await _audioPlayer.setAudioSource(_playlist, initialIndex: 0);
        await _audioPlayer.setVolume(1.0);
        _audioPlayer.play(); // don't await — plays in background
      } else if (_audioPlayer.processingState == ProcessingState.completed) {
        // Player ran out of items before new audio arrived — resume at new item
        await _audioPlayer.seek(Duration.zero, index: _playlist.length - 1);
        _audioPlayer.play();
      }
      // Otherwise the player is still playing earlier items and will
      // automatically advance to this newly-added item (gapless).
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
    _setAgentSpeaking(false);
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

  // ── Helpers ────────────────────────────────────────────────────────

  int _parseSampleRate(String format) {
    // Formats: "pcm_16000", "pcm_22050", "pcm_24000", "pcm_44100"
    final parts = format.split('_');
    if (parts.length >= 2) {
      return int.tryParse(parts.last) ?? 16000;
    }
    return 16000;
  }

  void _updateStatus(ConversationStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void _setAgentSpeaking(bool speaking) {
    if (_agentSpeaking != speaking) {
      _agentSpeaking = speaking;
      _agentSpeakingController.add(speaking);
      if (!speaking) {
        _playbackLevelController.add(0.0);
      }
    }
  }

  /// Stop the conversation and clean up resources.
  Future<void> stop() async {
    _audioFlushTimer?.cancel();
    _speakingEndTimer?.cancel();
    _playerStateSubscription?.cancel();
    await _wsSubscription?.cancel();
    _wsSubscription = null;

    await _audioPlayer.stop();
    _audioOutputBuffer.clear();
    _resetPlaylist();
    _cleanupTempFiles();
    _setAgentSpeaking(false);

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    _updateStatus(ConversationStatus.disconnected);
    _logger.i('ElevenLabs conversation stopped');
  }

  /// Dispose all resources permanently.
  Future<void> dispose() async {
    await stop();
    await _statusController.close();
    await _userTranscriptController.close();
    await _agentResponseController.close();
    await _agentResponseCorrectionController.close();
    await _agentSpeakingController.close();
    await _playbackLevelController.close();
    await _errorController.close();
    await _audioPlayer.dispose();
  }

  static double _computeLevel(List<int> pcmBytes) {
    if (pcmBytes.length < 2) {
      return 0.0;
    }

    final bytes = Uint8List.fromList(pcmBytes);
    final samples = bytes.buffer.asInt16List();
    if (samples.isEmpty) {
      return 0.0;
    }

    var sum = 0.0;
    for (final sample in samples) {
      final normalized = sample / 32768.0;
      sum += normalized * normalized;
    }

    return math.sqrt(sum / samples.length).clamp(0.0, 1.0).toDouble();
  }

  /// Wrap raw PCM16 mono data in a WAV container.
  static Uint8List _wrapPcmAsWav(Uint8List pcmData, {int sampleRate = 16000}) {
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt sub-chunk
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
    // data sub-chunk
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
