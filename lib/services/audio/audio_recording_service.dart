import 'dart:async';
import 'package:logger/logger.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final _logger = Logger();
  final _amplitudeController = StreamController<double>.broadcast();
  Timer? _amplitudeTimer;
  bool _isRecording = false;

  Stream<double> get amplitudeStream => _amplitudeController.stream;
  bool get isRecording => _isRecording;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> start() async {
    try {
      if (!await hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: '', // Empty path for stream recording
      );

      _isRecording = true;
      _startAmplitudeMonitor();
      _logger.i('Audio recording started');
    } catch (e) {
      _logger.e('Failed to start recording: $e');
      rethrow;
    }
  }

  Stream<List<int>> startStream() async* {
    try {
      if (!await hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _isRecording = true;
      _startAmplitudeMonitor();
      _logger.i('Audio stream started');

      await for (final chunk in stream) {
        yield chunk;
      }
    } catch (e) {
      _logger.e('Failed to start stream: $e');
      rethrow;
    }
  }

  Future<String?> stop() async {
    _amplitudeTimer?.cancel();
    _isRecording = false;

    try {
      final path = await _recorder.stop();
      _logger.i('Audio recording stopped');
      return path;
    } catch (e) {
      _logger.e('Failed to stop recording: $e');
      return null;
    }
  }

  void _startAmplitudeMonitor() {
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) async {
        try {
          final amplitude = await _recorder.getAmplitude();
          // Normalize dBFS to 0-1 range (-160 to 0 dBFS)
          final normalized = ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
          _amplitudeController.add(normalized);
        } catch (_) {}
      },
    );
  }

  Future<void> dispose() async {
    _amplitudeTimer?.cancel();
    await _amplitudeController.close();
    await _recorder.dispose();
  }
}
