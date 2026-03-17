import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class AppleSttService {
  static const _methodChannel = MethodChannel('com.myea/apple_stt');
  static const _eventChannel = EventChannel('com.myea/apple_stt_events');
  final _logger = Logger();

  final _transcriptController = StreamController<String>.broadcast();
  final _soundLevelController = StreamController<double>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  StreamSubscription? _eventSub;

  // Accumulates partial results; emits new words as they arrive
  String _partialTranscript = '';
  int _lastEmittedLength = 0;
  String? _lastError;

  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;
  Stream<String> get statusStream => _statusController.stream;

  /// Returns null on success, or an error message string on failure.
  Future<String?> initialize() async {
    try {
      _listenToEvents();
      _lastError = null;
      final result = await _methodChannel.invokeMethod<bool>('initialize');
      if (result == true) return null;
      // Return specific error if native side reported one
      if (_lastError == 'permission_denied') {
        return 'Speech Recognition permission denied. '
            'Go to Settings > myEA > Speech Recognition and enable it.';
      }
      if (_lastError == 'permission_restricted') {
        return 'Speech Recognition is restricted on this device.';
      }
      return 'Speech Recognition permission not granted.';
    } catch (e) {
      _logger.e('Failed to initialize Apple STT: $e');
      return 'Failed to initialize speech recognition: $e';
    }
  }

  void _listenToEvents() {
    _eventSub?.cancel();
    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;
        final data = Map<String, dynamic>.from(event);
        final type = data['type'] as String?;

        switch (type) {
          case 'transcript':
            _handleTranscript(data);
          case 'soundLevel':
            final level = (data['level'] as num?)?.toDouble() ?? 0.0;
            _soundLevelController.add(level);
          case 'status':
            final state = data['state'] as String? ?? 'unknown';
            _statusController.add(state);
          case 'error':
            final message = data['message'] as String? ?? 'Unknown error';
            _lastError = message;
            _logger.e('Apple STT error: $message');
            _statusController.add('error');
          case 'debug':
            final message = data['message'] as String? ?? '';
            _logger.i('Apple STT debug: $message');
            _statusController.add('debug: $message');
        }
      },
      onError: (error) {
        _logger.e('Apple STT event stream error: $error');
      },
    );
  }

  void _handleTranscript(Map<String, dynamic> data) {
    final text = (data['text'] as String? ?? '').trim();
    final isFinal = data['isFinal'] as bool? ?? false;

    if (text.isEmpty) return;

    if (isFinal) {
      // Emit the full final transcript, then reset for next recognition task
      _transcriptController.add(text);
      _partialTranscript = '';
      _lastEmittedLength = 0;
    } else {
      // SFSpeechRecognizer sends cumulative partial results (full text so far).
      // Emit only the new portion since our last emission.
      if (text.length > _lastEmittedLength) {
        final newPortion = text.substring(_lastEmittedLength).trim();
        if (newPortion.isNotEmpty) {
          _transcriptController.add(newPortion);
          _lastEmittedLength = text.length;
        }
      }
      _partialTranscript = text;
    }
  }

  Future<void> startListening({String locale = 'en-US'}) async {
    try {
      _partialTranscript = '';
      _lastEmittedLength = 0;
      await _methodChannel.invokeMethod('start', {'locale': locale});
    } catch (e) {
      _logger.e('Failed to start Apple STT: $e');
      rethrow;
    }
  }

  Future<void> stopListening() async {
    try {
      // Emit any remaining partial transcript before stopping
      if (_partialTranscript.isNotEmpty) {
        _transcriptController.add(_partialTranscript);
        _partialTranscript = '';
      }
      await _methodChannel.invokeMethod('stop');
    } catch (e) {
      _logger.e('Failed to stop Apple STT: $e');
    }
  }

  Future<void> dispose() async {
    await stopListening();
    await _eventSub?.cancel();
    await _transcriptController.close();
    await _soundLevelController.close();
    await _statusController.close();
    try {
      await _methodChannel.invokeMethod('dispose');
    } catch (_) {}
  }
}
