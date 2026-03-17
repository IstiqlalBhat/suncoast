import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final _logger = Logger();
  final _amplitudeController = StreamController<double>.broadcast();
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
      _logger.i('Audio recording started');
    } catch (e) {
      _logger.e('Failed to start recording: $e');
      rethrow;
    }
  }

  Stream<List<int>> startStream({
    int sampleRate = 16000,
    bool enableVoiceProcessing = false,
    bool preferSpeakerOutput = false,
  }) async* {
    try {
      if (!await hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      await _recorder.ios?.manageAudioSession(!enableVoiceProcessing);

      final stream = await _recorder.startStream(
        _buildStreamConfig(
          sampleRate: sampleRate,
          enableVoiceProcessing: enableVoiceProcessing,
          preferSpeakerOutput: preferSpeakerOutput,
        ),
      );

      _isRecording = true;
      _logger.i('Audio stream started');

      try {
        await for (final chunk in stream) {
          // Compute amplitude from PCM16 data
          _computeAmplitude(chunk);
          yield chunk;
        }
      } finally {
        _isRecording = false;
      }
    } catch (e) {
      _isRecording = false;
      _logger.e('Failed to start stream: $e');
      rethrow;
    }
  }

  RecordConfig _buildStreamConfig({
    required int sampleRate,
    required bool enableVoiceProcessing,
    required bool preferSpeakerOutput,
  }) {
    return RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      autoGain: enableVoiceProcessing,
      echoCancel: enableVoiceProcessing,
      noiseSuppress: enableVoiceProcessing,
      streamBufferSize: enableVoiceProcessing ? 2048 : null,
      androidConfig: enableVoiceProcessing
          ? AndroidRecordConfig(
              audioSource: AndroidAudioSource.voiceCommunication,
              audioManagerMode: AudioManagerMode.modeInCommunication,
              speakerphone: preferSpeakerOutput,
            )
          : const AndroidRecordConfig(),
    );
  }

  /// Compute RMS amplitude from PCM16 little-endian audio data.
  void _computeAmplitude(List<int> chunk) {
    if (chunk.length < 2) return;

    final bytes = Uint8List.fromList(chunk);
    final samples = bytes.buffer.asInt16List();
    if (samples.isEmpty) return;

    double sum = 0;
    for (final sample in samples) {
      final normalized = sample / 32768.0;
      sum += normalized * normalized;
    }
    final rms = math.sqrt(sum / samples.length);
    final level = (rms * 5.0).clamp(0.0, 1.0);
    _amplitudeController.add(level);
  }

  Future<String?> stop() async {
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

  Future<void> dispose() async {
    await _amplitudeController.close();
    await _recorder.dispose();
  }
}
