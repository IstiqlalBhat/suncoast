import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';

enum TtsEngine { device, elevenLabs }

class AudioPlaybackService {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ApiClient? _apiClient;
  final _logger = Logger();
  TtsEngine _currentEngine = TtsEngine.device;

  AudioPlaybackService({ApiClient? apiClient}) : _apiClient = apiClient;

  TtsEngine get currentEngine => _currentEngine;

  Future<void> initialize() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void setEngine(TtsEngine engine) {
    _currentEngine = engine;
  }

  Future<void> setSpeed(double speed) async {
    await _flutterTts.setSpeechRate(speed);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    try {
      if (_currentEngine == TtsEngine.device) {
        await _flutterTts.speak(text);
      } else {
        await _speakWithElevenLabs(text);
      }
    } catch (e) {
      _logger.e('TTS failed: $e');
      // Fallback to device TTS
      await _flutterTts.speak(text);
    }
  }

  Future<void> _speakWithElevenLabs(String text) async {
    if (_apiClient == null) {
      _logger.w('No API client for ElevenLabs, falling back to device TTS');
      await _flutterTts.speak(text);
      return;
    }

    try {
      final response = await _apiClient!.callFunction(
        ApiEndpoints.elevenLabsTts,
        data: {'text': text},
      );

      final audioBase64 = response['audio'] as String?;
      if (audioBase64 == null) {
        throw Exception('No audio in response');
      }

      // Decode and play audio
      final audioBytes = Uint8List.fromList(
        audioBase64.codeUnits, // In practice, use base64Decode
      );

      await _audioPlayer.setAudioSource(
        _BytesAudioSource(audioBytes),
      );
      await _audioPlayer.play();
    } catch (e) {
      _logger.e('ElevenLabs TTS failed: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
    await _audioPlayer.dispose();
  }
}

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
