import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_ea/services/audio/voice_activity_gate.dart';

void main() {
  Uint8List pcmChunk(double amplitude, {int samples = 160}) {
    final safeAmplitude = amplitude.clamp(0.0, 0.99);
    final sampleValue = (safeAmplitude * 32767).round();
    final data = Int16List(samples);
    for (var i = 0; i < data.length; i += 1) {
      data[i] = sampleValue;
    }
    return data.buffer.asUint8List();
  }

  group('VoiceActivityGate', () {
    test('passes through audio while agent is not speaking', () {
      final gate = VoiceActivityGate();

      final decision = gate.process(pcmChunk(0.03), aiSpeaking: false);

      expect(decision.shouldInterruptPlayback, isFalse);
      expect(decision.userSpeechEnded, isFalse);
      expect(decision.chunksToSend, hasLength(1));
      expect(gate.isGateOpen, isFalse);
    });

    test('keeps gate closed for low-level echo while agent is speaking', () {
      final gate = VoiceActivityGate();
      gate.updatePlaybackLevel(0.08);

      for (var i = 0; i < 4; i += 1) {
        final decision = gate.process(pcmChunk(0.02), aiSpeaking: true);
        expect(decision.shouldInterruptPlayback, isFalse);
        expect(decision.chunksToSend, isEmpty);
      }

      expect(gate.isGateOpen, isFalse);
    });

    test('opens gate after sustained user speech and includes preroll', () {
      final gate = VoiceActivityGate();
      gate.updatePlaybackLevel(0.08);

      gate.process(pcmChunk(0.01), aiSpeaking: true);
      final firstSpeech = gate.process(pcmChunk(0.06), aiSpeaking: true);
      final secondSpeech = gate.process(pcmChunk(0.06), aiSpeaking: true);

      expect(firstSpeech.shouldInterruptPlayback, isFalse);
      expect(secondSpeech.shouldInterruptPlayback, isTrue);
      expect(secondSpeech.chunksToSend.length, greaterThanOrEqualTo(3));
      expect(gate.isGateOpen, isTrue);
    });

    test('closes gate after hangover silence', () {
      final gate = VoiceActivityGate();
      gate.updatePlaybackLevel(0.08);

      gate.process(pcmChunk(0.01), aiSpeaking: true);
      gate.process(pcmChunk(0.07), aiSpeaking: true);
      gate.process(pcmChunk(0.07), aiSpeaking: true);

      VoiceActivityGateDecision? lastDecision;
      for (var i = 0; i < 4; i += 1) {
        lastDecision = gate.process(pcmChunk(0.0), aiSpeaking: true);
      }

      expect(lastDecision?.userSpeechEnded, isTrue);
      expect(lastDecision?.chunksToSend, isEmpty);
      expect(gate.isGateOpen, isFalse);
    });
  });
}
