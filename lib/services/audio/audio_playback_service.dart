import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';

enum TtsEngine { device, openai }

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
    await _flutterTts.awaitSpeakCompletion(true);
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
        await _speakWithOpenAI(text);
      }
    } catch (e) {
      _logger.e('TTS failed: $e');
      // Fallback to device TTS
      await _flutterTts.speak(text);
    }
  }

  Future<void> _speakWithOpenAI(String text) async {
    if (_apiClient == null) {
      _logger.w('No API client for OpenAI TTS, falling back to device TTS');
      await _flutterTts.speak(text);
      return;
    }

    try {
      final response = await _apiClient.callFunction(
        ApiEndpoints.openaiTts,
        data: {'text': text, 'voice': 'nova'},
      );

      final audioBase64 = response['audio'] as String?;
      if (audioBase64 == null) {
        throw Exception('No audio in response');
      }

      final audioBytes = Uint8List.fromList(base64Decode(audioBase64));
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/myea_tts.mp3');
      await audioFile.writeAsBytes(audioBytes, flush: true);
      await _audioPlayer.setFilePath(audioFile.path);
      await _audioPlayer.play();
      try {
        await audioFile.delete();
      } catch (_) {}
    } catch (e) {
      _logger.e('OpenAI TTS failed: $e');
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
