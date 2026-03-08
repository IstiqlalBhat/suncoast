import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/session_model.dart';
import '../../../../shared/models/ai_event_model.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/audio/audio_recording_service.dart';
import '../../../dashboard/data/repositories/activity_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/datasources/session_remote_datasource.dart';
import '../../data/repositories/session_repository.dart';

final sessionRemoteDatasourceProvider = Provider<SessionRemoteDatasource>((
  ref,
) {
  return SessionRemoteDatasource(ref.watch(supabaseClientProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    remoteDatasource: ref.watch(sessionRemoteDatasourceProvider),
  );
});

final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  return AudioRecordingService();
});

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSessionState>((ref) {
      return ActiveSessionNotifier(
        repository: ref.watch(sessionRepositoryProvider),
        activityRepository: ref.watch(activityRepositoryProvider),
        apiClient: ref.watch(apiClientProvider),
        audioService: ref.watch(audioRecordingServiceProvider),
        userId: ref.watch(currentUserProvider)?.id ?? '',
      );
    });

class ActiveSessionState {
  final SessionModel? session;
  final bool isRecording;
  final bool isMuted;
  final bool isProcessing;
  final double audioLevel;
  final String transcript;
  final String? error;
  final Duration elapsed;
  final String? aiResponse;
  final String activityTitle;
  final String activityContext;

  const ActiveSessionState({
    this.session,
    this.isRecording = false,
    this.isMuted = false,
    this.isProcessing = false,
    this.audioLevel = 0.0,
    this.transcript = '',
    this.error,
    this.elapsed = Duration.zero,
    this.aiResponse,
    this.activityTitle = '',
    this.activityContext = 'Field session',
  });

  ActiveSessionState copyWith({
    SessionModel? session,
    bool? isRecording,
    bool? isMuted,
    bool? isProcessing,
    double? audioLevel,
    String? transcript,
    String? error,
    Duration? elapsed,
    String? aiResponse,
    String? activityTitle,
    String? activityContext,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      isRecording: isRecording ?? this.isRecording,
      isMuted: isMuted ?? this.isMuted,
      isProcessing: isProcessing ?? this.isProcessing,
      audioLevel: audioLevel ?? this.audioLevel,
      transcript: transcript ?? this.transcript,
      error: error,
      elapsed: elapsed ?? this.elapsed,
      aiResponse: aiResponse ?? this.aiResponse,
      activityTitle: activityTitle ?? this.activityTitle,
      activityContext: activityContext ?? this.activityContext,
    );
  }
}

class ActiveSessionNotifier extends StateNotifier<ActiveSessionState> {
  final SessionRepository _repository;
  final ActivityRepository _activityRepository;
  final ApiClient _apiClient;
  final AudioRecordingService _audioService;
  final String _userId;
  final _logger = Logger();
  static const _transcriptionInterval = Duration(seconds: 4);
  static const _minCharsBeforeAiProcessing = 120;

  Timer? _timer;
  Timer? _transcriptionTimer;
  StreamSubscription<double>? _amplitudeSub;
  StreamSubscription<List<int>>? _audioStreamSub;
  final List<int> _audioBuffer = [];
  String _lastProcessedTranscript = '';
  bool _isAiProcessing = false;

  ActiveSessionNotifier({
    required SessionRepository repository,
    required ActivityRepository activityRepository,
    required ApiClient apiClient,
    required AudioRecordingService audioService,
    required String userId,
  }) : _repository = repository,
       _activityRepository = activityRepository,
       _apiClient = apiClient,
       _audioService = audioService,
       _userId = userId,
       super(const ActiveSessionState());

  Future<void> startSession({
    required String activityId,
    required SessionMode mode,
  }) async {
    state = const ActiveSessionState();

    await _loadActivityContext(activityId);

    final result = await _repository.createSession(
      activityId: activityId,
      userId: _userId,
      mode: mode,
    );

    result.when(
      success: (session) {
        state = state.copyWith(
          session: session,
          isRecording: true,
          error: null,
        );
        _startTimer();
        _startAudioPipeline();
      },
      failure: (message, _) {
        state = state.copyWith(error: message);
      },
    );
  }

  Future<void> _loadActivityContext(String activityId) async {
    final result = await _activityRepository.getActivity(activityId);
    result.when(
      success: (activity) {
        state = state.copyWith(
          activityTitle: activity.title,
          activityContext: _buildActivityContext(activity),
        );
      },
      failure: (message, code) {
        state = state.copyWith(activityContext: 'Field session');
      },
    );
  }

  String _buildActivityContext(ActivityModel activity) {
    final contextParts = <String>[
      'Activity: ${activity.title}',
      'Mode: ${activity.type.displayName}',
    ];

    if (activity.description?.trim().isNotEmpty ?? false) {
      contextParts.add('Description: ${activity.description!.trim()}');
    }

    if (activity.location?.trim().isNotEmpty ?? false) {
      contextParts.add('Location: ${activity.location!.trim()}');
    }

    return contextParts.join('\n');
  }

  Future<void> _startAudioPipeline() async {
    try {
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(error: 'Microphone permission required');
        return;
      }

      // Listen to amplitude for waveform visualization
      _amplitudeSub = _audioService.amplitudeStream.listen((level) {
        if (!state.isMuted) {
          state = state.copyWith(audioLevel: level);
        }
      });

      // Start streaming audio
      final audioStream = _audioService.startStream();
      _audioStreamSub = audioStream.listen(
        (chunk) {
          if (!state.isMuted) {
            _audioBuffer.addAll(chunk);
          }
        },
        onError: (e) {
          _logger.e('Audio stream error: $e');
        },
      );

      // Send audio chunks to Deepgram every 3 seconds
      _transcriptionTimer = Timer.periodic(
        _transcriptionInterval,
        (_) => _sendAudioChunk(),
      );

      _logger.i('Audio pipeline started');
    } catch (e) {
      _logger.e('Failed to start audio pipeline: $e');
      state = state.copyWith(error: 'Failed to start recording: $e');
    }
  }

  Future<void> _sendAudioChunk() async {
    if (_audioBuffer.isEmpty || state.isMuted || state.session == null) return;

    // Copy and clear buffer
    final chunk = Uint8List.fromList(_audioBuffer);
    _audioBuffer.clear();

    try {
      final result = await _apiClient.callDeepgramProxy(chunk);

      // Extract transcript from Deepgram response
      final alternatives = result['results']?['channels']?[0]?['alternatives'];
      if (alternatives != null && (alternatives as List).isNotEmpty) {
        final transcriptText = alternatives[0]['transcript'] as String? ?? '';
        if (transcriptText.isNotEmpty) {
          final newTranscript = '${state.transcript} $transcriptText'.trim();
          state = state.copyWith(transcript: newTranscript);

          // Update transcript in Supabase
          await _repository.updateTranscript(state.session!.id, newTranscript);

          // Process with Gemini after a meaningful amount of new content arrives.
          await _maybeProcessWithAI();
        }
      }
    } catch (e) {
      _logger.e('Transcription failed: $e');
      // Don't update error state for transient transcription failures
    }
  }

  Future<void> _maybeProcessWithAI({bool force = false}) async {
    if (_isAiProcessing || state.session == null) return;

    final transcript = state.transcript.trim();
    if (transcript.isEmpty) return;

    final safePreviousLength = math.min(
      _lastProcessedTranscript.length,
      transcript.length,
    );
    final newContent = transcript.substring(safePreviousLength);

    if (!force && newContent.length < _minCharsBeforeAiProcessing) {
      return;
    }

    final previousTranscript = _lastProcessedTranscript;
    _lastProcessedTranscript = transcript;
    _isAiProcessing = true;

    try {
      state = state.copyWith(isProcessing: true);

      await _apiClient.callFunction(
        'processTranscript',
        data: {
          'transcript': transcript,
          'activityContext': state.activityContext,
          'sessionId': state.session!.id,
        },
      );

      state = state.copyWith(isProcessing: false);
    } catch (e) {
      _lastProcessedTranscript = previousTranscript;
      _logger.e('AI processing failed: $e');
      state = state.copyWith(isProcessing: false);
    } finally {
      _isAiProcessing = false;
    }
  }

  /// Send a chat message (for two-way chat mode)
  Future<String?> sendChatMessage(String message) async {
    if (state.session == null) return null;

    try {
      state = state.copyWith(isProcessing: true);

      final response = await _apiClient.callFunction(
        'chat',
        data: {
          'message': message,
          'sessionContext': state.transcript,
          'sessionId': state.session!.id,
        },
      );

      final aiMessage = response['message'] as String? ?? '';
      state = state.copyWith(
        isProcessing: false,
        aiResponse: aiMessage,
        transcript: '${state.transcript}\nUser: $message\nAI: $aiMessage'
            .trim(),
      );

      return aiMessage;
    } catch (e) {
      _logger.e('Chat failed: $e');
      state = state.copyWith(isProcessing: false, error: 'Chat failed');
      return null;
    }
  }

  /// Analyze an image (for media mode)
  Future<String?> analyzeImage(List<int> imageBytes, String context) async {
    if (state.session == null) return null;

    try {
      state = state.copyWith(isProcessing: true);

      final response = await _apiClient.callFunction(
        'analyzeImage',
        data: {
          'image': String.fromCharCodes(imageBytes),
          'context': context,
          'sessionId': state.session!.id,
        },
      );

      final analysis = response['analysis'] as String? ?? '';
      state = state.copyWith(isProcessing: false);
      return analysis;
    } catch (e) {
      _logger.e('Image analysis failed: $e');
      state = state.copyWith(isProcessing: false);
      return null;
    }
  }

  Future<String?> endSession() async {
    if (state.session == null) return null;
    final sessionId = state.session!.id;

    // Stop audio pipeline
    _transcriptionTimer?.cancel();
    await _audioStreamSub?.cancel();
    await _amplitudeSub?.cancel();
    await _audioService.stop();
    _timer?.cancel();

    state = state.copyWith(isRecording: false, isProcessing: true);

    // Send any remaining audio
    if (_audioBuffer.isNotEmpty) {
      await _sendAudioChunk();
    }

    // Process final transcript with AI if needed
    if (state.transcript.isNotEmpty &&
        state.transcript != _lastProcessedTranscript) {
      await _maybeProcessWithAI(force: true);
    }

    final result = await _repository.endSession(sessionId);

    result.when(
      success: (session) {
        state = state.copyWith(
          session: session,
          isProcessing: false,
          audioLevel: 0,
        );
      },
      failure: (message, _) {
        state = state.copyWith(isProcessing: false, error: message);
      },
    );

    return sessionId;
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
    if (state.isMuted) {
      state = state.copyWith(audioLevel: 0.0);
    }
  }

  void updateAudioLevel(double level) {
    state = state.copyWith(audioLevel: level);
  }

  void appendTranscript(String text) {
    state = state.copyWith(transcript: '${state.transcript} $text'.trim());
  }

  void reset() {
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _audioStreamSub?.cancel();
    _amplitudeSub?.cancel();
    _audioBuffer.clear();
    _lastProcessedTranscript = '';
    _isAiProcessing = false;
    state = const ActiveSessionState();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _audioStreamSub?.cancel();
    _amplitudeSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}

final sessionEventsProvider = StreamProvider.family<List<AiEventModel>, String>(
  (ref, sessionId) {
    final repository = ref.watch(sessionRepositoryProvider);
    return repository.subscribeToEvents(sessionId);
  },
);

final sessionDetailsProvider = FutureProvider.family<SessionModel, String>((
  ref,
  sessionId,
) async {
  final repository = ref.watch(sessionRepositoryProvider);
  final result = await repository.getSession(sessionId);
  return result.when(
    success: (session) => session,
    failure: (message, _) => throw Exception(message),
  );
});

final sessionTimerProvider = Provider<String>((ref) {
  final session = ref.watch(activeSessionProvider);
  final elapsed = session.elapsed;
  final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
});
