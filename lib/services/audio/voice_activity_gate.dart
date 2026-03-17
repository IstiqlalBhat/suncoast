import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

class VoiceActivityGateDecision {
  final List<Uint8List> chunksToSend;
  final bool shouldInterruptPlayback;
  final bool userSpeechEnded;
  final double micLevel;

  const VoiceActivityGateDecision({
    this.chunksToSend = const [],
    this.shouldInterruptPlayback = false,
    this.userSpeechEnded = false,
    this.micLevel = 0.0,
  });
}

class VoiceActivityGate {
  static const _minimumSpeechLevel = 0.028;
  static const _minimumNoiseFloor = 0.003;
  static const _maximumNoiseFloor = 0.08;

  final int _preRollFrames;
  final int _speechFramesToOpen;
  final int _silenceFramesToClose;
  final Queue<Uint8List> _preRollBuffer = Queue<Uint8List>();

  double _noiseFloor = 0.010;
  double _playbackLevel = 0.0;
  bool _gateOpen = false;
  int _speechFrames = 0;
  int _silenceFrames = 0;

  VoiceActivityGate({
    int preRollFrames = 3,
    int speechFramesToOpen = 2,
    int silenceFramesToClose = 4,
  }) : _preRollFrames = preRollFrames,
       _speechFramesToOpen = speechFramesToOpen,
       _silenceFramesToClose = silenceFramesToClose;

  bool get isGateOpen => _gateOpen;

  void updatePlaybackLevel(double level) {
    _playbackLevel = level.clamp(0.0, 1.0).toDouble();
  }

  void reset({bool resetNoiseFloor = false}) {
    _gateOpen = false;
    _speechFrames = 0;
    _silenceFrames = 0;
    _playbackLevel = 0.0;
    _preRollBuffer.clear();
    if (resetNoiseFloor) {
      _noiseFloor = 0.010;
    }
  }

  VoiceActivityGateDecision process(
    List<int> chunk, {
    required bool aiSpeaking,
  }) {
    final pcmChunk = Uint8List.fromList(chunk);
    final micLevel = _computeLevel(pcmChunk);

    if (!aiSpeaking) {
      _adaptNoiseFloor(micLevel, aggressive: true);
      _gateOpen = false;
      _speechFrames = 0;
      _silenceFrames = 0;
      _preRollBuffer.clear();
      return VoiceActivityGateDecision(
        chunksToSend: [pcmChunk],
        micLevel: micLevel,
      );
    }

    if (!_gateOpen) {
      _bufferChunk(pcmChunk);
      final threshold = _interruptThreshold();
      final strongSpeech = micLevel >= threshold;
      final immediateSpeech = micLevel >= threshold * 1.35;

      if (strongSpeech) {
        _speechFrames += 1;
        _silenceFrames = 0;
      } else {
        _speechFrames = 0;
        _silenceFrames += 1;
        _adaptNoiseFloor(micLevel);
      }

      if (immediateSpeech || _speechFrames >= _speechFramesToOpen) {
        _gateOpen = true;
        _speechFrames = 0;
        _silenceFrames = 0;
        final bufferedChunks = List<Uint8List>.from(_preRollBuffer);
        _preRollBuffer.clear();
        return VoiceActivityGateDecision(
          chunksToSend: bufferedChunks,
          shouldInterruptPlayback: true,
          micLevel: micLevel,
        );
      }

      return VoiceActivityGateDecision(micLevel: micLevel);
    }

    final threshold = _interruptThreshold();
    final strongSpeech = micLevel >= threshold;

    if (strongSpeech) {
      _silenceFrames = 0;
    } else {
      _silenceFrames += 1;
    }

    if (strongSpeech || _silenceFrames < _silenceFramesToClose) {
      return VoiceActivityGateDecision(
        chunksToSend: [pcmChunk],
        micLevel: micLevel,
      );
    }

    _gateOpen = false;
    _speechFrames = 0;
    _silenceFrames = 0;
    _preRollBuffer.clear();
    _adaptNoiseFloor(micLevel, aggressive: true);

    return VoiceActivityGateDecision(userSpeechEnded: true, micLevel: micLevel);
  }

  void _bufferChunk(Uint8List chunk) {
    _preRollBuffer.add(chunk);
    while (_preRollBuffer.length > _preRollFrames) {
      _preRollBuffer.removeFirst();
    }
  }

  double _interruptThreshold() {
    final noiseThreshold = math.max(_minimumSpeechLevel, _noiseFloor * 3.0);
    final playbackThreshold = (_playbackLevel * 0.45 + 0.015)
        .clamp(0.0, 0.12)
        .toDouble();
    return math.max(noiseThreshold, playbackThreshold);
  }

  void _adaptNoiseFloor(double level, {bool aggressive = false}) {
    final quietCutoff = math.max(_minimumSpeechLevel, _noiseFloor * 1.8);
    if (!aggressive && level > quietCutoff) {
      return;
    }

    final weight = aggressive ? 0.18 : 0.08;
    final clampedLevel = level.clamp(_minimumNoiseFloor, _maximumNoiseFloor);
    _noiseFloor = (_noiseFloor * (1 - weight) + clampedLevel * weight)
        .clamp(_minimumNoiseFloor, _maximumNoiseFloor)
        .toDouble();
  }

  static double _computeLevel(Uint8List pcmChunk) {
    if (pcmChunk.length < 2) {
      return 0.0;
    }

    final samples = pcmChunk.buffer.asInt16List();
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
}
