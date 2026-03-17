import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/ai_event_model.dart';
import '../../../../shared/models/media_attachment_model.dart';
import '../../../../shared/models/session_model.dart';
import '../../../../shared/models/user_settings_model.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/audio/audio_playback_service.dart';
import '../../../../services/audio/audio_recording_service.dart';
import '../../../../services/audio/voice_activity_gate.dart';
import '../../../../services/speech/apple_stt_service.dart';
import '../../../../services/conversation/elevenlabs_conversation_service.dart';
import '../../../../services/media/camera_service.dart';
import '../../../../services/media/media_upload_service.dart';
import '../../../../services/media/openai_realtime_media_service.dart';
import '../../../../services/voice/openai_realtime_voice_service.dart';
import '../models/conversation_entry.dart';
import '../../../dashboard/data/repositories/activity_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
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

final appleSttServiceProvider = Provider<AppleSttService>((ref) {
  return AppleSttService();
});

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  return AudioPlaybackService(apiClient: ref.watch(apiClientProvider));
});

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(ref.watch(supabaseClientProvider));
});

final openAiRealtimeMediaServiceProvider = Provider<OpenAiRealtimeMediaService>(
  (ref) {
    return OpenAiRealtimeMediaService(apiClient: ref.watch(apiClientProvider));
  },
);

enum SessionConversationState { idle, userSpeaking, processing, aiSpeaking }

enum RealtimeVoiceStatus {
  disconnected,
  connecting,
  connected,
  listening,
  aiSpeaking,
}

enum MediaCaptureSource { camera, gallery, filePicker }

class MediaCaptureRequest {
  final String captureType;
  final MediaCaptureSource source;

  const MediaCaptureRequest({required this.captureType, required this.source});
}

class SessionMediaItem {
  final MediaAttachmentModel attachment;
  final String? signedUrl;
  final String? localPath;
  final String? analysis;
  final bool isAnalyzing;
  final Uint8List? previewBytes;

  const SessionMediaItem({
    required this.attachment,
    this.signedUrl,
    this.localPath,
    this.analysis,
    this.isAnalyzing = false,
    this.previewBytes,
  });

  SessionMediaItem copyWith({
    MediaAttachmentModel? attachment,
    String? signedUrl,
    String? localPath,
    String? analysis,
    bool? isAnalyzing,
    Uint8List? previewBytes,
  }) {
    return SessionMediaItem(
      attachment: attachment ?? this.attachment,
      signedUrl: signedUrl ?? this.signedUrl,
      localPath: localPath ?? this.localPath,
      analysis: analysis ?? this.analysis,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      previewBytes: previewBytes ?? this.previewBytes,
    );
  }
}

class _MediaUploadResult {
  final MediaAttachmentModel attachment;
  final String? signedUrl;

  const _MediaUploadResult({required this.attachment, this.signedUrl});
}

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSessionState>((ref) {
      final supabase = ref.read(supabaseClientProvider);
      return ActiveSessionNotifier(
        repository: ref.watch(sessionRepositoryProvider),
        activityRepository: ref.watch(activityRepositoryProvider),
        apiClient: ref.watch(apiClientProvider),
        audioService: ref.watch(audioRecordingServiceProvider),
        audioPlaybackService: ref.watch(audioPlaybackServiceProvider),
        appleSttService: ref.watch(appleSttServiceProvider),
        cameraService: ref.watch(cameraServiceProvider),
        mediaUploadService: ref.watch(mediaUploadServiceProvider),
        realtimeMediaService: ref.watch(openAiRealtimeMediaServiceProvider),
        readSettings: () => ref.read(settingsProvider).valueOrNull,
        readCurrentUserId: () => supabase.auth.currentUser?.id ?? '',
      );
    });

class ActiveSessionState {
  static const _unset = Object();

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
  final SessionConversationState conversationState;
  final List<Map<String, dynamic>> referenceCards;
  final List<SessionMediaItem> mediaItems;
  final bool isConversationActive;
  final RealtimeVoiceStatus voiceStatus;
  final ToolCallRequest? activeToolRequest;
  final List<ConversationEntry> conversationEntries;

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
    this.conversationState = SessionConversationState.idle,
    this.referenceCards = const [],
    this.mediaItems = const [],
    this.isConversationActive = false,
    this.voiceStatus = RealtimeVoiceStatus.disconnected,
    this.activeToolRequest,
    this.conversationEntries = const [],
  });

  ActiveSessionState copyWith({
    SessionModel? session,
    bool? isRecording,
    bool? isMuted,
    bool? isProcessing,
    double? audioLevel,
    String? transcript,
    Object? error = _unset,
    Duration? elapsed,
    Object? aiResponse = _unset,
    String? activityTitle,
    String? activityContext,
    SessionConversationState? conversationState,
    List<Map<String, dynamic>>? referenceCards,
    List<SessionMediaItem>? mediaItems,
    bool? isConversationActive,
    RealtimeVoiceStatus? voiceStatus,
    Object? activeToolRequest = _unset,
    List<ConversationEntry>? conversationEntries,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      isRecording: isRecording ?? this.isRecording,
      isMuted: isMuted ?? this.isMuted,
      isProcessing: isProcessing ?? this.isProcessing,
      audioLevel: audioLevel ?? this.audioLevel,
      transcript: transcript ?? this.transcript,
      error: identical(error, _unset) ? this.error : error as String?,
      elapsed: elapsed ?? this.elapsed,
      aiResponse: identical(aiResponse, _unset)
          ? this.aiResponse
          : aiResponse as String?,
      activityTitle: activityTitle ?? this.activityTitle,
      activityContext: activityContext ?? this.activityContext,
      conversationState: conversationState ?? this.conversationState,
      referenceCards: referenceCards ?? this.referenceCards,
      mediaItems: mediaItems ?? this.mediaItems,
      isConversationActive: isConversationActive ?? this.isConversationActive,
      voiceStatus: voiceStatus ?? this.voiceStatus,
      activeToolRequest: identical(activeToolRequest, _unset)
          ? this.activeToolRequest
          : activeToolRequest as ToolCallRequest?,
      conversationEntries: conversationEntries ?? this.conversationEntries,
    );
  }
}

class ActiveSessionNotifier extends StateNotifier<ActiveSessionState> {
  final SessionRepository _repository;
  final ActivityRepository _activityRepository;
  final ApiClient _apiClient;
  final AudioRecordingService _audioService;
  final AudioPlaybackService _audioPlaybackService;
  final AppleSttService _appleSttService;
  final CameraService _cameraService;
  final MediaUploadService _mediaUploadService;
  final OpenAiRealtimeMediaService _realtimeMediaService;
  final UserSettingsModel? Function() _readSettings;
  final String Function() _readCurrentUserId;
  final _logger = Logger();
  static const _transcriptionInterval = Duration(seconds: 4);
  static const _minCharsBeforeAiProcessing = 120;

  Timer? _timer;
  Timer? _transcriptionTimer;
  StreamSubscription<double>? _amplitudeSub;
  StreamSubscription<List<int>>? _audioStreamSub;
  StreamSubscription<List<int>>? _interactiveAudioSub;
  StreamSubscription<String>? _onDeviceSttSub;
  StreamSubscription<double>? _onDeviceSoundLevelSub;
  bool _isOnDeviceSttActive = false;
  final List<int> _audioBuffer = [];
  final List<int> _interactiveAudioBuffer = [];
  String _lastProcessedTranscript = '';
  bool _isAiProcessing = false;
  Completer<void>? _aiProcessingCompleter;
  bool _playbackInitialized = false;

  // ElevenLabs Conversational AI
  ElevenLabsConversationService? _conversationService;
  StreamSubscription<ConversationStatus>? _convStatusSub;
  StreamSubscription<String>? _convUserTranscriptSub;
  StreamSubscription<String>? _convAgentResponseSub;
  StreamSubscription<AgentResponseCorrection>? _convAgentCorrectionSub;
  StreamSubscription<bool>? _convAgentSpeakingSub;
  StreamSubscription<double>? _convPlaybackLevelSub;
  StreamSubscription<String>? _convErrorSub;
  final VoiceActivityGate _conversationBargeInGate = VoiceActivityGate();

  // OpenAI Realtime Voice (media mode)
  OpenAiRealtimeVoiceService? _voiceService;
  StreamSubscription<VoiceSessionStatus>? _voiceStatusSub;
  StreamSubscription<ToolCallRequest>? _voiceToolCallSub;
  StreamSubscription<String>? _voiceUserTranscriptSub;
  StreamSubscription<String>? _voiceAiTranscriptSub;
  StreamSubscription<bool>? _voiceAiSpeakingSub;
  StreamSubscription<String>? _voiceErrorSub;
  StreamSubscription<List<int>>? _voiceAudioSub;
  int _voiceSampleRate = 24000;

  ActiveSessionNotifier({
    required SessionRepository repository,
    required ActivityRepository activityRepository,
    required ApiClient apiClient,
    required AudioRecordingService audioService,
    required AudioPlaybackService audioPlaybackService,
    required AppleSttService appleSttService,
    required CameraService cameraService,
    required MediaUploadService mediaUploadService,
    required OpenAiRealtimeMediaService realtimeMediaService,
    required UserSettingsModel? Function() readSettings,
    required String Function() readCurrentUserId,
  }) : _repository = repository,
       _activityRepository = activityRepository,
       _apiClient = apiClient,
       _audioService = audioService,
       _audioPlaybackService = audioPlaybackService,
       _appleSttService = appleSttService,
       _cameraService = cameraService,
       _mediaUploadService = mediaUploadService,
       _realtimeMediaService = realtimeMediaService,
       _readSettings = readSettings,
       _readCurrentUserId = readCurrentUserId,
       super(const ActiveSessionState());

  void _setStateIfMounted(
    ActiveSessionState Function(ActiveSessionState current) update,
  ) {
    if (!mounted) return;
    state = update(state);
  }

  Future<void> startSession({
    required String activityId,
    required SessionMode mode,
  }) async {
    if (!mounted) return;
    final userId = _readCurrentUserId().trim();
    if (userId.isEmpty) {
      _logger.e(
        'Cannot start ${mode.name} session without an authenticated user',
      );
      _setStateIfMounted(
        (current) => current.copyWith(
          error: 'Your login session expired. Please sign in again.',
        ),
      );
      return;
    }

    _logger.i('Starting ${mode.name} session for activity $activityId');
    reset();
    if (!mounted) return;

    await _loadActivityContext(activityId);
    if (!mounted) return;

    final result = await _repository.createSession(
      activityId: activityId,
      userId: userId,
      mode: mode,
    );
    if (!mounted) return;

    result.when(
      success: (session) {
        _logger.i('Session created successfully: ${session.id}');
        _setStateIfMounted(
          (current) => current.copyWith(
            session: session,
            isRecording: true,
            error: null,
            conversationState: SessionConversationState.idle,
          ),
        );
        unawaited(_syncActivityStatus(session.id, 'in_progress'));
        _startTimer();
        if (mode == SessionMode.passive) {
          _startAudioPipeline();
        } else if (mode == SessionMode.chat) {
          _startConversation();
        } else if (mode == SessionMode.media) {
          unawaited(_startRealtimeVoiceSession());
        }
      },
      failure: (message, _) {
        _logger.e('Session creation failed: $message');
        _setStateIfMounted((current) => current.copyWith(error: message));
      },
    );
  }

  Future<void> _loadActivityContext(String activityId) async {
    final result = await _activityRepository.getActivity(activityId);
    if (!mounted) return;
    result.when(
      success: (activity) {
        _setStateIfMounted(
          (current) => current.copyWith(
            activityTitle: activity.title,
            activityContext: _buildActivityContext(activity),
          ),
        );
      },
      failure: (message, code) {
        _setStateIfMounted(
          (current) => current.copyWith(activityContext: 'Field session'),
        );
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

  void _ensureAmplitudeSubscription() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _audioService.amplitudeStream.listen((level) {
      if (!state.isMuted) {
        state = state.copyWith(audioLevel: level);
      }
    });
  }

  Future<void> _preparePlayback() async {
    if (!_playbackInitialized) {
      await _audioPlaybackService.initialize();
      _playbackInitialized = true;
    }

    final settings = _readSettings();
    final usePremium = settings?.usePremiumTts ?? true;
    await _audioPlaybackService.setSpeed(settings?.voiceSpeed ?? 1.0);
    _audioPlaybackService.setEngine(
      usePremium ? TtsEngine.openai : TtsEngine.device,
    );
  }

  /// Start ElevenLabs real-time voice conversation for chat mode.
  /// Falls back to push-to-talk if premium voice is disabled or connection fails.
  Future<void> _startConversation() async {
    if (state.session == null) return;

    final settings = _readSettings();
    if (settings?.elevenlabsEnabled == false) {
      _logger.i('ElevenLabs disabled, using push-to-talk mode');
      _setStateIfMounted(
        (current) => current.copyWith(isConversationActive: false),
      );
      return;
    }

    try {
      _conversationService = ElevenLabsConversationService(
        apiClient: _apiClient,
      );

      // Listen to conversation events
      _convStatusSub = _conversationService!.statusStream.listen((status) {
        if (!mounted) return;
        if (status == ConversationStatus.error ||
            status == ConversationStatus.disconnected) {
          _conversationBargeInGate.reset();
          _setStateIfMounted(
            (current) => current.copyWith(
              isConversationActive: false,
              conversationState: SessionConversationState.idle,
            ),
          );
        }
      });

      _convUserTranscriptSub = _conversationService!.userTranscriptStream
          .listen((transcript) {
            if (!mounted || state.session == null) return;
            final updated = _appendTranscriptLine('User: $transcript');
            _setStateIfMounted(
              (current) => current.copyWith(transcript: updated),
            );
            _repository.updateTranscript(state.session!.id, updated);
          });

      _convAgentResponseSub = _conversationService!.agentResponseStream.listen((
        response,
      ) {
        if (!mounted || state.session == null) return;
        final updated = _appendTranscriptLine('AI: $response');
        _setStateIfMounted(
          (current) =>
              current.copyWith(transcript: updated, aiResponse: response),
        );
        _repository.updateTranscript(state.session!.id, updated);
      });

      _convAgentCorrectionSub = _conversationService!
          .agentResponseCorrectionStream
          .listen(_handleConversationAgentCorrection);

      _convAgentSpeakingSub = _conversationService!.agentSpeakingStream.listen((
        speaking,
      ) {
        if (!mounted) return;
        _setStateIfMounted(
          (current) => current.copyWith(
            conversationState: speaking
                ? SessionConversationState.aiSpeaking
                : (_conversationBargeInGate.isGateOpen
                      ? SessionConversationState.userSpeaking
                      : SessionConversationState.idle),
          ),
        );
      });

      _convPlaybackLevelSub = _conversationService!.playbackLevelStream.listen(
        _conversationBargeInGate.updatePlaybackLevel,
      );

      _convErrorSub = _conversationService!.errorStream.listen((error) {
        if (!mounted) return;
        _logger.e('Conversation error: $error');
        _setStateIfMounted((current) => current.copyWith(error: error));
      });

      // Connect to ElevenLabs
      await _conversationService!.start(
        sessionId: state.session!.id,
        activityContext: _buildSessionContext(),
      );

      // Start mic and pipe audio to the conversation service
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission required');
      }

      _ensureAmplitudeSubscription();
      final stream = _audioService.startStream(
        enableVoiceProcessing: true,
        preferSpeakerOutput: true,
      );
      _interactiveAudioSub = stream.listen(_handleConversationAudioChunk);

      _setStateIfMounted(
        (current) => current.copyWith(isConversationActive: true),
      );
      _logger.i('ElevenLabs conversation started successfully');
    } catch (e) {
      _logger.e(
        'Failed to start conversation, falling back to push-to-talk: $e',
      );
      _setStateIfMounted(
        (current) => current.copyWith(
          isConversationActive: false,
          error: 'Voice agent unavailable. Using push-to-talk.',
        ),
      );
      // Clean up failed conversation
      await _conversationService?.dispose();
      _conversationService = null;
    }
  }

  void _handleConversationAudioChunk(List<int> chunk) {
    final conversationService = _conversationService;
    if (conversationService == null) {
      return;
    }

    if (state.isMuted) {
      _conversationBargeInGate.reset();
      return;
    }

    final decision = _conversationBargeInGate.process(
      chunk,
      aiSpeaking: conversationService.isAgentSpeaking,
    );

    if (decision.shouldInterruptPlayback) {
      conversationService.sendUserActivity();
      conversationService.interruptPlayback();
      _logger.i(
        'Local barge-in triggered '
        '(mic=${decision.micLevel.toStringAsFixed(3)})',
      );
      _setStateIfMounted(
        (current) => current.copyWith(
          conversationState: SessionConversationState.userSpeaking,
        ),
      );
    } else if (decision.userSpeechEnded &&
        !conversationService.isAgentSpeaking &&
        state.conversationState == SessionConversationState.userSpeaking) {
      _setStateIfMounted(
        (current) =>
            current.copyWith(conversationState: SessionConversationState.idle),
      );
    }

    for (final audioChunk in decision.chunksToSend) {
      conversationService.sendAudioChunk(audioChunk);
    }
  }

  void _handleConversationAgentCorrection(AgentResponseCorrection correction) {
    if (!mounted || state.session == null) return;

    final correctedResponse = correction.correctedAgentResponse.trim();
    final updatedTranscript = _replaceLastTranscriptLine(
      speakerPrefix: 'AI:',
      replacementText: correctedResponse,
      originalText: correction.originalAgentResponse,
    );

    _setStateIfMounted(
      (current) => current.copyWith(
        transcript: updatedTranscript,
        aiResponse: correctedResponse.isEmpty ? null : correctedResponse,
      ),
    );
    _repository.updateTranscript(state.session!.id, updatedTranscript);
  }

  Future<void> _startAudioPipeline() async {
    final settings = _readSettings();
    if (settings?.sttEngine == SttEngine.device) {
      await _startOnDeviceSttPipeline();
    } else {
      await _startCloudSttPipeline();
    }
  }

  Future<void> _startOnDeviceSttPipeline() async {
    try {
      final initError = await _appleSttService.initialize();
      if (initError != null) {
        state = state.copyWith(error: initError);
        return;
      }

      _isOnDeviceSttActive = true;

      // Subscribe to transcript stream
      _onDeviceSttSub = _appleSttService.transcriptStream.listen(
        (text) {
          if (!mounted || state.isMuted || state.session == null) return;
          final newTranscript = '${state.transcript} $text'.trim();
          state = state.copyWith(transcript: newTranscript);
          _repository.updateTranscript(state.session!.id, newTranscript);
          _maybeProcessWithAI();
        },
        onError: (e) {
          _logger.e('On-device STT transcript error: $e');
        },
      );

      // Subscribe to sound level stream for waveform
      _onDeviceSoundLevelSub = _appleSttService.soundLevelStream.listen((
        level,
      ) {
        if (!state.isMuted) {
          state = state.copyWith(audioLevel: level);
        }
      });

      // Map language code to locale (e.g. 'en' -> 'en-US')
      final settings = _readSettings();
      final lang = settings?.language ?? 'en';
      final locale = lang.contains('-') ? lang : '$lang-US';

      await _appleSttService.startListening(locale: locale);
      _logger.i('On-device STT pipeline started (locale=$locale)');
    } catch (e) {
      _logger.e('Failed to start on-device STT pipeline: $e');
      state = state.copyWith(
        error: 'Failed to start on-device speech recognition: $e',
      );
    }
  }

  Future<void> _startCloudSttPipeline() async {
    try {
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(error: 'Microphone permission required');
        return;
      }

      _ensureAmplitudeSubscription();

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

      // Send audio chunks for transcription every few seconds
      _transcriptionTimer = Timer.periodic(
        _transcriptionInterval,
        (_) => _sendAudioChunk(),
      );

      _logger.i('Cloud STT pipeline started');
    } catch (e) {
      _logger.e('Failed to start cloud STT pipeline: $e');
      state = state.copyWith(error: 'Failed to start recording: $e');
    }
  }

  Future<void> _sendAudioChunk() async {
    if (_audioBuffer.isEmpty || state.isMuted || state.session == null) return;

    // Copy and clear buffer
    final chunk = Uint8List.fromList(_audioBuffer);
    _audioBuffer.clear();

    _logger.i('Sending audio chunk: ${chunk.length} bytes');

    try {
      final result = await _apiClient.transcribeAudio(chunk);
      final transcriptText = (result['transcript'] as String? ?? '').trim();

      if (transcriptText.isNotEmpty) {
        final newTranscript = '${state.transcript} $transcriptText'.trim();
        state = state.copyWith(transcript: newTranscript);

        // Update transcript in Supabase
        await _repository.updateTranscript(state.session!.id, newTranscript);

        // Process with Gemini after a meaningful amount of new content arrives.
        await _maybeProcessWithAI();
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
    _aiProcessingCompleter = Completer<void>();

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
      _aiProcessingCompleter?.complete();
      _aiProcessingCompleter = null;
    }
  }

  bool get isInteractiveCaptureActive =>
      state.conversationState == SessionConversationState.userSpeaking;

  Future<void> startInteractiveTurn() async {
    // Skip push-to-talk when ElevenLabs conversation is active
    if (state.isConversationActive) return;

    if (state.session == null) {
      _setStateIfMounted(
        (current) => current.copyWith(error: 'Session is still starting.'),
      );
      return;
    }

    if (state.isMuted || state.isProcessing || isInteractiveCaptureActive) {
      return;
    }

    try {
      _logger.i('Starting interactive voice turn');
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(error: 'Microphone permission required');
        return;
      }

      _ensureAmplitudeSubscription();
      _interactiveAudioBuffer.clear();
      state = state.copyWith(
        conversationState: SessionConversationState.userSpeaking,
        audioLevel: 0,
        error: null,
      );

      final stream = _audioService.startStream();
      _interactiveAudioSub = stream.listen(
        (chunk) {
          _interactiveAudioBuffer.addAll(chunk);
        },
        onError: (e) {
          _logger.e('Interactive audio stream error: $e');
          state = state.copyWith(
            conversationState: SessionConversationState.idle,
            error: 'Failed to record audio turn',
          );
        },
      );
    } catch (e) {
      _logger.e('Failed to start interactive turn: $e');
      state = state.copyWith(
        conversationState: SessionConversationState.idle,
        error: 'Failed to start microphone',
      );
    }
  }

  Future<String?> finishInteractiveTurn() async {
    if (state.isConversationActive) return null;
    if (!isInteractiveCaptureActive || state.session == null) return null;

    state = state.copyWith(
      conversationState: SessionConversationState.processing,
      isProcessing: true,
      audioLevel: 0,
      error: null,
    );

    try {
      _logger.i('Finishing interactive voice turn');
      await _audioService.stop();
      await _interactiveAudioSub?.cancel();
      _interactiveAudioSub = null;

      if (_interactiveAudioBuffer.isEmpty) {
        state = state.copyWith(
          conversationState: SessionConversationState.idle,
          isProcessing: false,
          error: 'No audio captured. Try again.',
        );
        return null;
      }

      final audioBytes = Uint8List.fromList(_interactiveAudioBuffer);
      _interactiveAudioBuffer.clear();

      final result = await _apiClient.transcribeAudio(audioBytes);
      final whisperError = result['error'];
      if (whisperError != null) {
        final message = whisperError is String
            ? whisperError
            : whisperError.toString();
        _logger.e('Whisper interactive turn failed: $message');
        state = state.copyWith(
          conversationState: SessionConversationState.idle,
          isProcessing: false,
          error: 'Transcription failed: $message',
        );
        return null;
      }
      final transcriptText = (result['transcript'] as String? ?? '').trim();

      if (transcriptText.isEmpty) {
        state = state.copyWith(
          conversationState: SessionConversationState.idle,
          isProcessing: false,
          error: 'I could not hear anything. Try again.',
        );
        return null;
      }

      final updatedTranscript = _appendTranscriptLine('User: $transcriptText');

      state = state.copyWith(transcript: updatedTranscript);
      await _repository.updateTranscript(state.session!.id, updatedTranscript);

      final response = await _apiClient.callFunction(
        'chat',
        data: {
          'message': transcriptText,
          'sessionContext': _buildSessionContext(
            transcriptOverride: updatedTranscript,
          ),
          'sessionId': state.session!.id,
        },
      );

      final aiMessage = (response['message'] as String? ?? '').trim();
      _logger.i('Chat function returned response length: ${aiMessage.length}');
      final referenceCards = ((response['referenceCards'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final transcriptWithAi = aiMessage.isEmpty
          ? updatedTranscript
          : _appendTranscriptLine(
              'AI: $aiMessage',
              transcriptOverride: updatedTranscript,
            );

      state = state.copyWith(
        transcript: transcriptWithAi,
        aiResponse: aiMessage,
        referenceCards: referenceCards,
      );
      await _repository.updateTranscript(state.session!.id, transcriptWithAi);

      final settings = _readSettings();
      if ((settings?.voiceOutputEnabled ?? true) && aiMessage.isNotEmpty) {
        await _preparePlayback();
        state = state.copyWith(
          conversationState: SessionConversationState.aiSpeaking,
          isProcessing: false,
        );
        try {
          await _audioPlaybackService.speak(aiMessage);
        } catch (e) {
          _logger.e('TTS playback failed: $e');
        }
      }

      state = state.copyWith(
        conversationState: SessionConversationState.idle,
        isProcessing: false,
      );
      return aiMessage;
    } catch (e) {
      _logger.e('Failed to complete interactive turn: $e');
      state = state.copyWith(
        conversationState: SessionConversationState.idle,
        isProcessing: false,
        error: 'Failed to process audio turn: $e',
      );
      return null;
    }
  }

  Future<void> captureMedia(MediaCaptureRequest request) async {
    if (state.session == null) return;

    state = state.copyWith(
      isProcessing: true,
      error: null,
      conversationState: SessionConversationState.processing,
    );

    try {
      final file = await _pickMediaFile(request);
      if (file == null) {
        state = state.copyWith(
          isProcessing: false,
          conversationState: SessionConversationState.idle,
        );
        return;
      }

      // If voice session is active, inject media into the voice conversation
      if (_voiceService != null && _voiceService!.isConnected) {
        final type = request.captureType == 'pdf' ? 'pdf' : 'image';
        await handleToolCallMediaResponse(file, type);
        state = state.copyWith(
          isProcessing: false,
          conversationState: SessionConversationState.idle,
        );
        return;
      }

      final mimeType = _inferMimeType(file, request.captureType);
      final resolvedCaptureType = _resolveCaptureType(
        request.captureType,
        mimeType,
      );
      final mediaType = _parseMediaType(resolvedCaptureType);
      final fileSizeBytes = await file.length();
      final previewBytes = await _loadPreviewBytes(file, mimeType);
      final shouldAnalyzeImage = mimeType.startsWith('image/');
      final pendingAttachmentId =
          'pending-${DateTime.now().microsecondsSinceEpoch}';
      final analysisBytes = shouldAnalyzeImage
          ? (previewBytes ?? await file.readAsBytes())
          : null;
      var activeMediaItemId = pendingAttachmentId;

      state = state.copyWith(
        mediaItems: [
          ...state.mediaItems,
          SessionMediaItem(
            attachment: MediaAttachmentModel(
              id: pendingAttachmentId,
              sessionId: state.session!.id,
              type: mediaType,
              storagePath: '',
              mimeType: mimeType,
              fileSizeBytes: fileSizeBytes,
              analysisStatus: shouldAnalyzeImage ? 'processing' : 'uploading',
              metadata: {'local_path': file.path, 'pending': true},
            ),
            localPath: file.path,
            isAnalyzing: shouldAnalyzeImage,
            previewBytes: previewBytes,
          ),
        ],
      );

      final realtimeAnalysisFuture = shouldAnalyzeImage && analysisBytes != null
          ? _streamRealtimePhotoAnalysis(
              imageBytes: analysisBytes,
              mimeType: mimeType,
              mediaItemId: () => activeMediaItemId,
            )
          : Future<String?>.value(null);

      final uploadResult = await _uploadCapturedMedia(
        file: file,
        sessionId: state.session!.id,
        mediaType: mediaType,
        captureType: resolvedCaptureType,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        source: request.source.name,
      );

      if (uploadResult == null) {
        _updateMediaItem(
          activeMediaItemId,
          (item) => item.copyWith(
            attachment: item.attachment.copyWith(analysisStatus: 'failed'),
            isAnalyzing: false,
            analysis: item.analysis?.trim().isNotEmpty == true
                ? item.analysis
                : 'Upload failed. Try again.',
          ),
        );
        state = state.copyWith(
          isProcessing: false,
          conversationState: SessionConversationState.idle,
          error: 'Failed to upload media',
        );
        unawaited(realtimeAnalysisFuture.catchError((_) => null));
        return;
      }

      activeMediaItemId = uploadResult.attachment.id;
      final existingAnalysis = state.mediaItems
          .where((item) => item.attachment.id == pendingAttachmentId)
          .map((item) => item.analysis)
          .firstOrNull;
      final initialItem = SessionMediaItem(
        attachment: uploadResult.attachment,
        signedUrl: uploadResult.signedUrl,
        localPath: file.path,
        analysis: existingAnalysis,
        isAnalyzing: shouldAnalyzeImage,
        previewBytes: previewBytes,
      );
      _replaceMediaItem(pendingAttachmentId, initialItem);

      if (shouldAnalyzeImage) {
        final analysis = await realtimeAnalysisFuture;
        if (analysis != null) {
          await _persistRealtimePhotoAnalysis(
            attachmentId: uploadResult.attachment.id,
            analysis: analysis,
          );
          state = state.copyWith(
            aiResponse: analysis,
            isProcessing: false,
            conversationState: SessionConversationState.idle,
          );
          unawaited(_speakMediaAssistantResponse(analysis));
          return;
        }

        final fallbackAnalysis = await _analyzePhoto(
          imageBytes: analysisBytes!,
          attachmentId: uploadResult.attachment.id,
          mimeType: mimeType,
        );
        if (fallbackAnalysis != null) {
          state = state.copyWith(aiResponse: fallbackAnalysis);
          unawaited(_speakMediaAssistantResponse(fallbackAnalysis));
        }
      } else {
        await _repository.updateMediaAttachment(uploadResult.attachment.id, {
          'ai_analysis': resolvedCaptureType == 'video'
              ? 'Video uploaded for later review.'
              : 'Attachment uploaded and ready for review.',
          'analysis_status': 'skipped',
        });
        _updateMediaItem(
          uploadResult.attachment.id,
          (item) => item.copyWith(
            attachment: item.attachment.copyWith(analysisStatus: 'skipped'),
            analysis: resolvedCaptureType == 'video'
                ? 'Video uploaded for later review.'
                : 'Attachment uploaded and ready for review.',
            isAnalyzing: false,
          ),
        );
      }

      state = state.copyWith(
        isProcessing: false,
        conversationState: SessionConversationState.idle,
      );
    } catch (e) {
      _logger.e('Capture media failed: $e');
      state = state.copyWith(
        isProcessing: false,
        conversationState: SessionConversationState.idle,
        error: 'Failed to capture media',
      );
    }
  }

  Future<File?> _pickMediaFile(MediaCaptureRequest request) {
    switch ((request.captureType, request.source)) {
      case ('photo', MediaCaptureSource.camera):
        return _cameraService.takePhoto();
      case ('photo', MediaCaptureSource.gallery):
        return _cameraService.pickImage();
      case ('pdf', MediaCaptureSource.filePicker):
        return _cameraService.pickPdf();
      case ('file', MediaCaptureSource.filePicker):
        return _cameraService.pickFile();
      default:
        return Future.value(null);
    }
  }

  Future<String?> _analyzePhoto({
    required List<int> imageBytes,
    required String attachmentId,
    required String mimeType,
  }) async {
    try {
      final response = await _apiClient.callFunction(
        'analyzeImage',
        data: {
          'image': base64Encode(imageBytes),
          'context':
              '${state.activityContext}\nRecent context:\n${state.transcript}',
          'sessionId': state.session!.id,
          'attachmentId': attachmentId,
          'mimeType': mimeType,
        },
      );

      final analysis = (response['analysis'] as String? ?? '').trim();
      if (analysis.isEmpty) {
        throw StateError('Image analysis returned empty content');
      }

      final updatedAttachment = await _repository.updateMediaAttachment(
        attachmentId,
        {'ai_analysis': analysis, 'analysis_status': 'completed'},
      );

      _updateMediaItem(
        attachmentId,
        (item) => item.copyWith(
          attachment: updatedAttachment.dataOrNull ?? item.attachment,
          analysis: analysis,
          isAnalyzing: false,
        ),
      );

      return analysis;
    } catch (e) {
      _logger.e('Photo analysis failed: $e');
      await _repository.updateMediaAttachment(attachmentId, {
        'analysis_status': 'failed',
      });
      _updateMediaItem(
        attachmentId,
        (item) => item.copyWith(
          attachment: item.attachment.copyWith(analysisStatus: 'failed'),
          isAnalyzing: false,
          analysis: 'Image analysis failed.',
        ),
      );
      return null;
    }
  }

  Future<void> _startRealtimeVoiceSession() async {
    if (state.session == null) return;

    _setStateIfMounted(
      (current) =>
          current.copyWith(voiceStatus: RealtimeVoiceStatus.connecting),
    );

    try {
      // Get ephemeral token from Firebase
      final response = await _apiClient.callFunction(
        'createRealtimeMediaSession',
        data: {
          'sessionId': state.session!.id,
          'activityContext': state.activityContext,
        },
      );

      final clientSecret = (response['clientSecret'] as String? ?? '').trim();
      final model = (response['model'] as String? ?? 'gpt-4o-realtime-preview')
          .trim();
      final instructions = (response['instructions'] as String? ?? '').trim();

      if (clientSecret.isEmpty) {
        throw StateError('No client secret returned');
      }

      // Configure audio session for playAndRecord
      final audioSession = await AudioSession.instance;
      await audioSession.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
        ),
      );

      _voiceService = OpenAiRealtimeVoiceService();

      // Subscribe to voice events
      _voiceStatusSub = _voiceService!.statusStream.listen((status) {
        if (!mounted) return;
        if (status == VoiceSessionStatus.disconnected ||
            status == VoiceSessionStatus.error) {
          _setStateIfMounted(
            (current) => current.copyWith(
              voiceStatus: RealtimeVoiceStatus.disconnected,
              conversationState: SessionConversationState.idle,
            ),
          );
        }
      });

      _voiceToolCallSub = _voiceService!.toolCallStream.listen((toolCall) {
        if (!mounted) return;
        _addConversationEntry(
          ConversationEntry(
            id: 'tool-${DateTime.now().microsecondsSinceEpoch}',
            role: ConversationRole.ai,
            type: ConversationEntryType.toolRequest,
            text: toolCall.reason,
            timestamp: DateTime.now(),
            toolRequest: toolCall,
          ),
        );
        _setStateIfMounted(
          (current) => current.copyWith(activeToolRequest: toolCall),
        );
      });

      final userTranscriptBuffer = StringBuffer();
      _voiceUserTranscriptSub = _voiceService!.userTranscriptStream.listen((
        text,
      ) {
        if (!mounted || state.session == null) return;
        userTranscriptBuffer.write(text);
        final fullText = userTranscriptBuffer.toString().trim();
        if (fullText.isNotEmpty) {
          _addConversationEntry(
            ConversationEntry(
              id: 'user-${DateTime.now().microsecondsSinceEpoch}',
              role: ConversationRole.user,
              type: ConversationEntryType.text,
              text: fullText,
              timestamp: DateTime.now(),
            ),
          );
          final updated = _appendTranscriptLine('User: $fullText');
          _setStateIfMounted(
            (current) => current.copyWith(transcript: updated),
          );
          _repository.updateTranscript(state.session!.id, updated);
          userTranscriptBuffer.clear();
        }
      });

      final aiTranscriptBuffer = StringBuffer();
      _voiceAiTranscriptSub = _voiceService!.aiTranscriptStream.listen((text) {
        if (!mounted || state.session == null) return;
        aiTranscriptBuffer.write(text);
        // Finalize on sentence boundaries or after a pause
      });

      _voiceAiSpeakingSub = _voiceService!.aiSpeakingStream.listen((speaking) {
        if (!mounted) return;
        _setStateIfMounted(
          (current) => current.copyWith(
            conversationState: speaking
                ? SessionConversationState.aiSpeaking
                : SessionConversationState.idle,
            voiceStatus: speaking
                ? RealtimeVoiceStatus.aiSpeaking
                : RealtimeVoiceStatus.listening,
          ),
        );
        // When AI stops speaking, flush accumulated transcript
        if (!speaking && aiTranscriptBuffer.isNotEmpty) {
          final fullText = aiTranscriptBuffer.toString().trim();
          if (fullText.isNotEmpty) {
            _addConversationEntry(
              ConversationEntry(
                id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
                role: ConversationRole.ai,
                type: ConversationEntryType.text,
                text: fullText,
                timestamp: DateTime.now(),
              ),
            );
            final updated = _appendTranscriptLine('AI: $fullText');
            _setStateIfMounted(
              (current) =>
                  current.copyWith(transcript: updated, aiResponse: fullText),
            );
            _repository.updateTranscript(state.session!.id, updated);
          }
          aiTranscriptBuffer.clear();
        }
      });

      _voiceErrorSub = _voiceService!.errorStream.listen((error) {
        if (!mounted) return;
        _logger.e('Voice session error: $error');
        _setStateIfMounted((current) => current.copyWith(error: error));
      });

      // Connect to OpenAI Realtime
      await _voiceService!.connect(
        clientSecret: clientSecret,
        model: model,
        instructions: instructions,
      );

      // Start mic and pipe audio to voice service
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission required');
      }

      _ensureAmplitudeSubscription();

      // Try 24kHz first, fall back to 16kHz
      try {
        final stream = _audioService.startStream(sampleRate: 24000);
        _voiceSampleRate = 24000;
        _voiceAudioSub = stream.listen((chunk) {
          if (!state.isMuted && _voiceService?.isAiSpeaking != true) {
            _voiceService?.sendAudioChunk(chunk);
          }
        });
      } catch (e) {
        _logger.w('24kHz not supported, falling back to 16kHz: $e');
        final stream = _audioService.startStream(sampleRate: 16000);
        _voiceSampleRate = 16000;
        _voiceAudioSub = stream.listen((chunk) {
          if (!state.isMuted && _voiceService?.isAiSpeaking != true) {
            _voiceService?.sendAudioChunk(chunk);
          }
        });
      }

      _setStateIfMounted(
        (current) => current.copyWith(
          voiceStatus: RealtimeVoiceStatus.connected,
          isConversationActive: true,
        ),
      );
      _logger.i(
        'Realtime voice session started (sampleRate=$_voiceSampleRate)',
      );
    } catch (e) {
      _logger.e('Failed to start realtime voice session: $e');
      _setStateIfMounted(
        (current) => current.copyWith(
          voiceStatus: RealtimeVoiceStatus.disconnected,
          error: 'Voice assistant unavailable: $e',
        ),
      );
      await _voiceService?.dispose();
      _voiceService = null;
    }
  }

  Future<void> handleToolCallMediaResponse(File file, String type) async {
    if (state.session == null) return;
    final session = state.session!;
    final toolCall = state.activeToolRequest;
    final captureType = type == 'image' ? 'photo' : 'pdf';
    final mimeType = _inferMimeType(file, captureType);
    final mediaType = type == 'image' ? MediaType.photo : MediaType.file;
    final fileSizeBytes = await file.length();
    final previewBytes = type == 'image'
        ? await _loadPreviewBytes(file, mimeType)
        : null;
    final pendingAttachmentId =
        'pending-${DateTime.now().microsecondsSinceEpoch}';
    var activeAttachmentId = pendingAttachmentId;

    _setStateIfMounted(
      (current) => current.copyWith(
        isProcessing: true,
        activeToolRequest: null,
        mediaItems: [
          ...current.mediaItems,
          SessionMediaItem(
            attachment: MediaAttachmentModel(
              id: pendingAttachmentId,
              sessionId: session.id,
              type: mediaType,
              storagePath: '',
              mimeType: mimeType,
              fileSizeBytes: fileSizeBytes,
              analysisStatus: 'processing',
              metadata: {
                'local_path': file.path,
                'pending': true,
                'source': 'tool_request',
              },
            ),
            localPath: file.path,
            isAnalyzing: true,
            previewBytes: previewBytes,
          ),
        ],
      ),
    );
    if (toolCall != null) {
      _removeToolRequestEntry(toolCall.callId);
    }

    try {
      final uploadResult = await _uploadCapturedMedia(
        file: file,
        sessionId: session.id,
        mediaType: mediaType,
        captureType: captureType,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        source: 'tool_request',
      );

      if (uploadResult == null) {
        throw StateError('Failed to upload media');
      }

      activeAttachmentId = uploadResult.attachment.id;
      _replaceMediaItem(
        pendingAttachmentId,
        SessionMediaItem(
          attachment: uploadResult.attachment,
          signedUrl: uploadResult.signedUrl,
          localPath: file.path,
          isAnalyzing: true,
          previewBytes: previewBytes,
        ),
      );

      if (type == 'image') {
        final bytes = previewBytes ?? await file.readAsBytes();

        // Add to conversation entries immediately
        _addConversationEntry(
          ConversationEntry(
            id: 'media-${DateTime.now().microsecondsSinceEpoch}',
            role: ConversationRole.user,
            type: ConversationEntryType.mediaAttachment,
            text: 'Photo shared',
            timestamp: DateTime.now(),
          ),
        );

        // Use GPT-4o vision to analyze the image, then inject text into voice conversation
        final analysisResponse = await _apiClient.callFunction(
          'analyzeImage',
          data: {
            'image': base64Encode(bytes),
            'context': state.activityContext,
            'sessionId': session.id,
            'attachmentId': activeAttachmentId,
            'mimeType': mimeType,
          },
        );
        final analysis = (analysisResponse['analysis'] as String? ?? '').trim();
        if (analysis.isEmpty) {
          throw StateError('Image analysis returned empty content');
        }

        _updateMediaItem(
          activeAttachmentId,
          (item) => item.copyWith(
            attachment: item.attachment.copyWith(
              aiAnalysis: analysis,
              analysisStatus: 'completed',
            ),
            analysis: analysis,
            isAnalyzing: false,
          ),
        );

        if (analysis.isNotEmpty) {
          _voiceService?.sendMediaContext(
            textContent:
                'The user just shared a photo. Here is the image analysis:\n$analysis',
          );
        }

        // Submit tool result if this was a tool call
        if (toolCall != null) {
          _submitRealtimeToolResult(toolCall.callId, {
            'status': 'image_analyzed',
            'analysis': analysis,
            'attachmentId': activeAttachmentId,
          });
        }
      } else if (type == 'pdf') {
        final bytes = await file.readAsBytes();
        final base64Pdf = base64Encode(bytes);

        // Extract text server-side
        final result = await _apiClient.callFunction(
          'extractPdfText',
          data: {
            'pdfBase64': base64Pdf,
            'sessionId': session.id,
            'attachmentId': activeAttachmentId,
          },
        );

        final extractedText = (result['text'] as String? ?? '').trim();
        final pageCount = _parsePdfPageCount(result['pageCount']);
        final truncated = result['truncated'] as bool? ?? false;
        final persistedServerSide = result.containsKey('analysis');
        final attachmentAnalysis =
            (result['analysis'] as String? ??
                    _buildPdfAttachmentAnalysis(
                      extractedText: extractedText,
                      pageCount: pageCount,
                      truncated: truncated,
                    ))
                .trim();

        if (!persistedServerSide) {
          await _persistPdfExtractionFallback(
            attachmentId: activeAttachmentId,
            analysis: attachmentAnalysis,
            extractedText: extractedText,
            pageCount: pageCount,
            truncated: truncated,
          );
        }

        _updateMediaItem(
          activeAttachmentId,
          (item) => item.copyWith(
            attachment: item.attachment.copyWith(
              aiAnalysis: attachmentAnalysis.isEmpty
                  ? item.attachment.aiAnalysis
                  : attachmentAnalysis,
              analysisStatus: 'completed',
            ),
            analysis: attachmentAnalysis.isEmpty
                ? item.analysis
                : attachmentAnalysis,
            isAnalyzing: false,
          ),
        );

        if (extractedText.isNotEmpty) {
          final pdfContext = [
            'PDF Document ($pageCount pages${truncated ? ', truncated' : ''}):',
            extractedText,
          ].join('\n');

          _voiceService?.sendMediaContext(textContent: pdfContext);
        }

        _addConversationEntry(
          ConversationEntry(
            id: 'media-${DateTime.now().microsecondsSinceEpoch}',
            role: ConversationRole.user,
            type: ConversationEntryType.mediaAttachment,
            text: 'PDF shared ($pageCount pages)',
            timestamp: DateTime.now(),
          ),
        );

        if (toolCall != null) {
          _submitRealtimeToolResult(toolCall.callId, {
            'status': 'pdf_provided',
            'pages': pageCount,
            'truncated': truncated,
            'analysis': attachmentAnalysis,
            'attachmentId': activeAttachmentId,
          });
        }
      }
    } catch (e) {
      _logger.e('Failed to handle tool call media response: $e');
      if (activeAttachmentId != pendingAttachmentId) {
        await _repository.updateMediaAttachment(activeAttachmentId, {
          'analysis_status': 'failed',
        });
      }
      _updateMediaItem(
        activeAttachmentId,
        (item) => item.copyWith(
          attachment: item.attachment.copyWith(analysisStatus: 'failed'),
          analysis: type == 'pdf'
              ? 'PDF processing failed.'
              : 'Image analysis failed.',
          isAnalyzing: false,
        ),
      );
      if (toolCall != null) {
        _submitRealtimeToolResult(toolCall.callId, {
          'error': 'Failed to process media',
        });
      }
    } finally {
      _setStateIfMounted((current) => current.copyWith(isProcessing: false));
    }
  }

  void dismissToolRequest() {
    final toolCall = state.activeToolRequest;
    if (toolCall == null) return;

    _submitRealtimeToolResult(toolCall.callId, {
      'status': 'dismissed',
      'reason': 'User declined to provide media',
    });

    _setStateIfMounted((current) => current.copyWith(activeToolRequest: null));
    _removeToolRequestEntry(toolCall.callId);
  }

  void _submitRealtimeToolResult(String callId, Map<String, dynamic> payload) {
    _voiceService?.submitToolResult(callId, jsonEncode(payload));
  }

  void _removeToolRequestEntry(String callId) {
    _setStateIfMounted(
      (current) => current.copyWith(
        conversationEntries: current.conversationEntries
            .where(
              (entry) =>
                  entry.type != ConversationEntryType.toolRequest ||
                  entry.toolRequest?.callId != callId,
            )
            .toList(),
      ),
    );
  }

  Future<void> _persistPdfExtractionFallback({
    required String attachmentId,
    required String analysis,
    required String extractedText,
    required int pageCount,
    required bool truncated,
  }) async {
    final normalizedAnalysis = analysis.trim();
    if (normalizedAnalysis.isEmpty || state.session == null) {
      return;
    }

    final updatedAttachment = await _repository.updateMediaAttachment(
      attachmentId,
      {'ai_analysis': normalizedAnalysis, 'analysis_status': 'completed'},
    );

    final attachment = updatedAttachment.dataOrNull;
    if (attachment != null) {
      _updateMediaItem(
        attachmentId,
        (item) => item.copyWith(attachment: attachment),
      );
    }

    final eventContent = _buildPdfObservationContent(
      extractedText: extractedText,
      pageCount: pageCount,
      truncated: truncated,
    );

    if (eventContent.isEmpty) {
      return;
    }

    final eventResult = await _repository.createAiEvent(
      sessionId: state.session!.id,
      type: AiEventType.observation,
      content: eventContent,
      source: 'pdf_extract',
      metadata: {
        'source': 'pdf_extract',
        'attachmentId': attachmentId,
        'pageCount': pageCount,
        'truncated': truncated,
      },
    );

    if (eventResult.isFailure) {
      _logger.w('Failed to persist PDF extraction event');
    }
  }

  void _addConversationEntry(ConversationEntry entry) {
    _setStateIfMounted(
      (current) => current.copyWith(
        conversationEntries: [...current.conversationEntries, entry],
      ),
    );
  }

  Future<_MediaUploadResult?> _uploadCapturedMedia({
    required File file,
    required String sessionId,
    required MediaType mediaType,
    required String captureType,
    required String mimeType,
    required int fileSizeBytes,
    required String source,
  }) async {
    final storagePath = await _mediaUploadService.uploadMedia(
      file: file,
      sessionId: sessionId,
      type: captureType,
      contentType: mimeType,
    );

    if (storagePath == null) {
      return null;
    }

    final attachmentResult = await _repository.createMediaAttachment(
      sessionId: sessionId,
      type: mediaType,
      storagePath: storagePath,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
      metadata: {
        'local_path': file.path,
        'source': source,
        'original_name': file.path.split(Platform.pathSeparator).last,
      },
    );

    final attachment = attachmentResult.dataOrNull;
    if (attachment == null) {
      return null;
    }

    final signedUrl = await _mediaUploadService.createSignedUrl(storagePath);
    return _MediaUploadResult(attachment: attachment, signedUrl: signedUrl);
  }

  Future<String?> _streamRealtimePhotoAnalysis({
    required List<int> imageBytes,
    required String mimeType,
    required String Function() mediaItemId,
  }) async {
    if (state.session == null) {
      return null;
    }

    try {
      final result = await _realtimeMediaService.analyzeImage(
        sessionId: state.session!.id,
        activityContext: state.activityContext,
        imageBytes: imageBytes,
        mimeType: mimeType,
        promptContext: _buildSessionContext(),
        onPartial: (partialText) {
          _updateMediaItem(
            mediaItemId(),
            (item) => item.copyWith(analysis: partialText, isAnalyzing: true),
          );
        },
      );

      _updateMediaItem(
        mediaItemId(),
        (item) => item.copyWith(analysis: result.analysis, isAnalyzing: false),
      );
      return result.analysis;
    } catch (e) {
      _logger.e('Realtime photo analysis failed: $e');
      _updateMediaItem(
        mediaItemId(),
        (item) => item.copyWith(isAnalyzing: false),
      );
      return null;
    }
  }

  Future<void> _persistRealtimePhotoAnalysis({
    required String attachmentId,
    required String analysis,
  }) async {
    final attachmentResult = await _repository.updateMediaAttachment(
      attachmentId,
      {'ai_analysis': analysis, 'analysis_status': 'completed'},
    );

    final updatedAttachment = attachmentResult.dataOrNull;
    _updateMediaItem(
      attachmentId,
      (item) => item.copyWith(
        attachment:
            updatedAttachment ??
            item.attachment.copyWith(
              aiAnalysis: analysis,
              analysisStatus: 'completed',
            ),
        analysis: analysis,
        isAnalyzing: false,
      ),
    );

    final eventResult = await _repository.createAiEvent(
      sessionId: state.session!.id,
      type: AiEventType.observation,
      content: analysis,
      source: 'openai_realtime',
      metadata: {
        'source': 'openai_realtime_media',
        'attachmentId': attachmentId,
      },
    );

    if (eventResult.isFailure) {
      _logger.w('Failed to persist realtime media event');
    }
  }

  Future<void> _speakMediaAssistantResponse(String message) async {
    final trimmedMessage = message.trim();
    final settings = _readSettings();

    if (trimmedMessage.isEmpty || !(settings?.voiceOutputEnabled ?? true)) {
      return;
    }

    try {
      await _preparePlayback();
      _setStateIfMounted(
        (current) => current.copyWith(
          conversationState: SessionConversationState.aiSpeaking,
        ),
      );
      await _audioPlaybackService.speak(trimmedMessage);
    } catch (e) {
      _logger.e('Realtime media TTS failed: $e');
    } finally {
      if (mounted) {
        _setStateIfMounted(
          (current) => current.copyWith(
            conversationState: current.isProcessing
                ? SessionConversationState.processing
                : SessionConversationState.idle,
          ),
        );
      }
    }
  }

  void _updateMediaItem(
    String attachmentId,
    SessionMediaItem Function(SessionMediaItem item) transform,
  ) {
    state = state.copyWith(
      mediaItems: state.mediaItems
          .map(
            (item) =>
                item.attachment.id == attachmentId ? transform(item) : item,
          )
          .toList(),
    );
  }

  void _replaceMediaItem(String attachmentId, SessionMediaItem replacement) {
    state = state.copyWith(
      mediaItems: state.mediaItems
          .map(
            (item) => item.attachment.id == attachmentId ? replacement : item,
          )
          .toList(),
    );
  }

  String _appendTranscriptLine(String line, {String? transcriptOverride}) {
    final currentTranscript = (transcriptOverride ?? state.transcript).trim();
    final trimmedLine = line.trim();

    return [
      if (currentTranscript.isNotEmpty) currentTranscript,
      if (trimmedLine.isNotEmpty) trimmedLine,
    ].join('\n');
  }

  String _replaceLastTranscriptLine({
    required String speakerPrefix,
    required String replacementText,
    String? originalText,
    String? transcriptOverride,
  }) {
    final currentTranscript = (transcriptOverride ?? state.transcript).trim();
    if (currentTranscript.isEmpty) {
      return replacementText.trim().isEmpty
          ? ''
          : '$speakerPrefix ${replacementText.trim()}'.trim();
    }

    final replacement = replacementText.trim();
    final original = originalText?.trim();
    final lines = currentTranscript
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    int? fallbackIndex;
    for (var i = lines.length - 1; i >= 0; i -= 1) {
      final line = lines[i].trim();
      if (!line.startsWith(speakerPrefix)) {
        continue;
      }

      fallbackIndex ??= i;
      final normalizedLine = line.substring(speakerPrefix.length).trim();
      if (original == null ||
          normalizedLine == original ||
          normalizedLine.startsWith(original)) {
        if (replacement.isEmpty) {
          lines.removeAt(i);
        } else {
          lines[i] = '$speakerPrefix $replacement'.trim();
        }
        return lines.join('\n');
      }
    }

    if (fallbackIndex != null) {
      if (replacement.isEmpty) {
        lines.removeAt(fallbackIndex);
      } else {
        lines[fallbackIndex] = '$speakerPrefix $replacement'.trim();
      }
      return lines.join('\n');
    }

    return replacement.isEmpty
        ? currentTranscript
        : _appendTranscriptLine(
            '$speakerPrefix $replacement'.trim(),
            transcriptOverride: currentTranscript,
          );
  }

  String _buildSessionContext({String? transcriptOverride}) {
    final contextSections = <String>[state.activityContext];
    final transcript = (transcriptOverride ?? state.transcript).trim();

    if (transcript.isNotEmpty) {
      contextSections.add('Conversation history:\n$transcript');
    }

    final mediaInsights = state.mediaItems
        .map((item) {
          final analysis = (item.analysis ?? item.attachment.aiAnalysis ?? '')
              .trim();
          if (analysis.isEmpty) {
            return null;
          }

          final label = switch (item.attachment.type) {
            MediaType.photo => 'Image finding',
            MediaType.video => 'Video note',
            MediaType.file => 'File note',
          };

          return '$label: $analysis';
        })
        .whereType<String>()
        .toList();

    if (mediaInsights.isNotEmpty) {
      final recentInsights = mediaInsights.length <= 3
          ? mediaInsights
          : mediaInsights.sublist(mediaInsights.length - 3);
      contextSections.add(
        'Recent media findings:\n${recentInsights.join('\n\n')}',
      );
    }

    return contextSections.join('\n\n');
  }

  String _buildPdfAttachmentAnalysis({
    required String extractedText,
    required int pageCount,
    required bool truncated,
  }) {
    final header =
        'PDF extracted successfully ($pageCount pages${truncated ? ', truncated' : ''}).';
    final normalizedText = _normalizeMediaText(extractedText);
    if (normalizedText.isEmpty) {
      return '$header\n\nNo extractable text was found in the PDF.';
    }

    const maxLength = 6000;
    final availableLength = math.max(maxLength - header.length - 2, 0);
    final excerpt = normalizedText.substring(
      0,
      math.min(normalizedText.length, availableLength),
    );
    return '$header\n\n$excerpt';
  }

  String _buildPdfObservationContent({
    required String extractedText,
    required int pageCount,
    required bool truncated,
  }) {
    final header =
        'PDF uploaded ($pageCount pages${truncated ? ', extracted text truncated' : ''}).';
    final normalizedText = _normalizeMediaText(extractedText);
    if (normalizedText.isEmpty) {
      return '$header No extractable text was found.';
    }

    const maxLength = 320;
    final excerpt = normalizedText.substring(
      0,
      math.min(normalizedText.length, maxLength),
    );
    return '$header $excerpt';
  }

  String _normalizeMediaText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _parsePdfPageCount(dynamic value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text => int.tryParse(text.trim()) ?? 0,
      List<dynamic> items => items.length,
      _ => 0,
    };
  }

  MediaType _parseMediaType(String captureType) {
    return switch (captureType) {
      'photo' => MediaType.photo,
      'video' => MediaType.video,
      _ => MediaType.file,
    };
  }

  String _inferMimeType(File file, String captureType) {
    final extension = file.path.split('.').last.toLowerCase();
    final normalizedExtension = extension == 'jpg' ? 'jpeg' : extension;

    if ({
      'jpeg',
      'png',
      'webp',
      'heic',
      'heif',
      'gif',
      'bmp',
    }.contains(normalizedExtension)) {
      return 'image/$normalizedExtension';
    }

    if ({'mp4', 'mov', 'm4v', 'webm', 'avi'}.contains(normalizedExtension)) {
      if (normalizedExtension == 'mov') {
        return 'video/quicktime';
      }
      return 'video/$normalizedExtension';
    }

    return switch (normalizedExtension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      _ =>
        captureType == 'photo'
            ? 'image/jpeg'
            : captureType == 'video'
            ? 'video/mp4'
            : 'application/octet-stream',
    };
  }

  String _resolveCaptureType(String captureType, String mimeType) {
    if (mimeType.startsWith('image/')) {
      return 'photo';
    }
    if (mimeType.startsWith('video/')) {
      return 'video';
    }
    return captureType;
  }

  Future<Uint8List?> _loadPreviewBytes(File file, String mimeType) async {
    if (!mimeType.startsWith('image/')) {
      return null;
    }

    try {
      return await file.readAsBytes();
    } catch (e) {
      _logger.w('Failed to read preview bytes: $e');
      return null;
    }
  }

  /// Send a chat message (for two-way chat mode)
  Future<String?> sendChatMessage(String message) async {
    if (state.session == null) return null;

    try {
      state = state.copyWith(
        isProcessing: true,
        conversationState: SessionConversationState.processing,
      );

      final transcriptWithUser = _appendTranscriptLine('User: $message');
      final response = await _apiClient.callFunction(
        'chat',
        data: {
          'message': message,
          'sessionContext': _buildSessionContext(
            transcriptOverride: transcriptWithUser,
          ),
          'sessionId': state.session!.id,
        },
      );

      final aiMessage = response['message'] as String? ?? '';
      final referenceCards = ((response['referenceCards'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final transcriptWithAi = aiMessage.trim().isEmpty
          ? transcriptWithUser
          : _appendTranscriptLine(
              'AI: $aiMessage',
              transcriptOverride: transcriptWithUser,
            );
      state = state.copyWith(
        isProcessing: false,
        conversationState: SessionConversationState.idle,
        aiResponse: aiMessage,
        referenceCards: referenceCards,
        transcript: transcriptWithAi,
      );
      await _repository.updateTranscript(state.session!.id, transcriptWithAi);

      return aiMessage;
    } catch (e) {
      _logger.e('Chat failed: $e');
      state = state.copyWith(
        isProcessing: false,
        conversationState: SessionConversationState.idle,
        error: 'Chat failed',
      );
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
          'image': base64Encode(imageBytes),
          'context': context,
          'sessionId': state.session!.id,
          'mimeType': 'image/jpeg',
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

    // Stop ElevenLabs conversation if active
    await _stopConversation();
    // Stop voice session if active
    await _stopVoiceSession();
    // Stop on-device STT if active
    await _stopOnDeviceStt();

    // Stop audio pipeline
    _transcriptionTimer?.cancel();
    await _audioStreamSub?.cancel();
    await _interactiveAudioSub?.cancel();
    await _amplitudeSub?.cancel();
    await _audioService.stop();
    await _audioPlaybackService.stop();
    _timer?.cancel();

    state = state.copyWith(isRecording: false, isProcessing: true);

    // Send any remaining audio (cloud pipeline only)
    if (_audioBuffer.isNotEmpty) {
      await _sendAudioChunk();
    }

    // Wait for any in-flight AI processing to finish
    await _aiProcessingCompleter?.future;

    // Process final transcript with AI if needed
    if (state.transcript.isNotEmpty &&
        state.transcript != _lastProcessedTranscript) {
      await _maybeProcessWithAI(force: true);
    }

    final result = await _repository.endSession(sessionId);

    result.when(
      success: (session) async {
        await _syncActivityStatus(session.id, 'completed');
        state = state.copyWith(
          session: session,
          isProcessing: false,
          audioLevel: 0,
          conversationState: SessionConversationState.idle,
        );
      },
      failure: (message, _) {
        state = state.copyWith(isProcessing: false, error: message);
      },
    );

    return sessionId;
  }

  void toggleMute() {
    final wasMuted = state.isMuted;
    state = state.copyWith(isMuted: !wasMuted);
    if (!wasMuted) {
      // Now muted
      state = state.copyWith(audioLevel: 0.0);
      _conversationBargeInGate.reset();
      if (_isOnDeviceSttActive) {
        _appleSttService.stopListening();
      }
    } else {
      // Now unmuted
      if (_isOnDeviceSttActive) {
        final settings = _readSettings();
        final lang = settings?.language ?? 'en';
        final locale = lang.contains('-') ? lang : '$lang-US';
        _appleSttService.startListening(locale: locale);
      }
    }
  }

  void updateAudioLevel(double level) {
    state = state.copyWith(audioLevel: level);
  }

  void appendTranscript(String text) {
    state = state.copyWith(transcript: '${state.transcript} $text'.trim());
  }

  Future<void> _stopVoiceSession() async {
    await _voiceStatusSub?.cancel();
    await _voiceToolCallSub?.cancel();
    await _voiceUserTranscriptSub?.cancel();
    await _voiceAiTranscriptSub?.cancel();
    await _voiceAiSpeakingSub?.cancel();
    await _voiceErrorSub?.cancel();
    await _voiceAudioSub?.cancel();
    _voiceStatusSub = null;
    _voiceToolCallSub = null;
    _voiceUserTranscriptSub = null;
    _voiceAiTranscriptSub = null;
    _voiceAiSpeakingSub = null;
    _voiceErrorSub = null;
    _voiceAudioSub = null;
    await _voiceService?.stop();
    _voiceService = null;
  }

  Future<void> _stopOnDeviceStt() async {
    if (!_isOnDeviceSttActive) return;
    _isOnDeviceSttActive = false;
    await _onDeviceSttSub?.cancel();
    _onDeviceSttSub = null;
    await _onDeviceSoundLevelSub?.cancel();
    _onDeviceSoundLevelSub = null;
    await _appleSttService.stopListening();
  }

  Future<void> _stopConversation() async {
    await _convStatusSub?.cancel();
    await _convUserTranscriptSub?.cancel();
    await _convAgentResponseSub?.cancel();
    await _convAgentCorrectionSub?.cancel();
    await _convAgentSpeakingSub?.cancel();
    await _convPlaybackLevelSub?.cancel();
    await _convErrorSub?.cancel();
    _convStatusSub = null;
    _convUserTranscriptSub = null;
    _convAgentResponseSub = null;
    _convAgentCorrectionSub = null;
    _convAgentSpeakingSub = null;
    _convPlaybackLevelSub = null;
    _convErrorSub = null;
    _conversationBargeInGate.reset(resetNoiseFloor: true);
    await _conversationService?.stop();
    _conversationService = null;
  }

  Future<void> _syncActivityStatus(String sessionId, String status) async {
    try {
      await _apiClient.callFunction(
        'syncActivityStatus',
        data: {'sessionId': sessionId, 'status': status},
      );
    } catch (error) {
      _logger.e(
        'Failed to sync activity status for session $sessionId: $error',
      );
    }
  }

  void reset() {
    _stopConversation();
    _stopVoiceSession();
    _stopOnDeviceStt();
    _realtimeMediaService.disconnect();
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _audioStreamSub?.cancel();
    _interactiveAudioSub?.cancel();
    _amplitudeSub?.cancel();
    _audioBuffer.clear();
    _interactiveAudioBuffer.clear();
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
    _stopConversation();
    _stopVoiceSession();
    _stopOnDeviceStt();
    _voiceService?.dispose();
    _conversationService?.dispose();
    _realtimeMediaService.dispose();
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _audioStreamSub?.cancel();
    _interactiveAudioSub?.cancel();
    _amplitudeSub?.cancel();
    _audioService.dispose();
    _audioPlaybackService.dispose();
    _appleSttService.dispose();
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
