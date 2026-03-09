import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
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
import '../../../../services/media/camera_service.dart';
import '../../../../services/media/media_upload_service.dart';
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

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  return AudioPlaybackService(apiClient: ref.watch(apiClientProvider));
});

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(ref.watch(supabaseClientProvider));
});

enum SessionConversationState { idle, userSpeaking, processing, aiSpeaking }

class SessionMediaItem {
  final MediaAttachmentModel attachment;
  final String? signedUrl;
  final String? localPath;
  final String? analysis;
  final bool isAnalyzing;

  const SessionMediaItem({
    required this.attachment,
    this.signedUrl,
    this.localPath,
    this.analysis,
    this.isAnalyzing = false,
  });

  SessionMediaItem copyWith({
    MediaAttachmentModel? attachment,
    String? signedUrl,
    String? localPath,
    String? analysis,
    bool? isAnalyzing,
  }) {
    return SessionMediaItem(
      attachment: attachment ?? this.attachment,
      signedUrl: signedUrl ?? this.signedUrl,
      localPath: localPath ?? this.localPath,
      analysis: analysis ?? this.analysis,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
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
        cameraService: ref.watch(cameraServiceProvider),
        mediaUploadService: ref.watch(mediaUploadServiceProvider),
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
    );
  }
}

class ActiveSessionNotifier extends StateNotifier<ActiveSessionState> {
  final SessionRepository _repository;
  final ActivityRepository _activityRepository;
  final ApiClient _apiClient;
  final AudioRecordingService _audioService;
  final AudioPlaybackService _audioPlaybackService;
  final CameraService _cameraService;
  final MediaUploadService _mediaUploadService;
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
  final List<int> _audioBuffer = [];
  final List<int> _interactiveAudioBuffer = [];
  String _lastProcessedTranscript = '';
  bool _isAiProcessing = false;
  bool _playbackInitialized = false;

  ActiveSessionNotifier({
    required SessionRepository repository,
    required ActivityRepository activityRepository,
    required ApiClient apiClient,
    required AudioRecordingService audioService,
    required AudioPlaybackService audioPlaybackService,
    required CameraService cameraService,
    required MediaUploadService mediaUploadService,
    required UserSettingsModel? Function() readSettings,
    required String Function() readCurrentUserId,
  }) : _repository = repository,
       _activityRepository = activityRepository,
       _apiClient = apiClient,
       _audioService = audioService,
       _audioPlaybackService = audioPlaybackService,
       _cameraService = cameraService,
       _mediaUploadService = mediaUploadService,
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
        _startTimer();
        if (mode == SessionMode.passive) {
          _startAudioPipeline();
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
    _amplitudeSub ??= _audioService.amplitudeStream.listen((level) {
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
    if (settings != null) {
      await _audioPlaybackService.setSpeed(settings.voiceSpeed);
      _audioPlaybackService.setEngine(
        settings.usePremiumTts ? TtsEngine.elevenLabs : TtsEngine.device,
      );
    }
  }

  Future<void> _startAudioPipeline() async {
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

  bool get isInteractiveCaptureActive =>
      state.conversationState == SessionConversationState.userSpeaking;

  Future<void> startInteractiveTurn() async {
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

      final result = await _apiClient.callDeepgramProxy(audioBytes);
      final deepgramError = result['error'];
      if (deepgramError != null) {
        final message = deepgramError is String
            ? deepgramError
            : deepgramError.toString();
        _logger.e('Deepgram interactive turn failed: $message');
        state = state.copyWith(
          conversationState: SessionConversationState.idle,
          isProcessing: false,
          error: 'Transcription failed: $message',
        );
        return null;
      }
      final alternatives = result['results']?['channels']?[0]?['alternatives'];
      final transcriptText = alternatives is List && alternatives.isNotEmpty
          ? (alternatives[0]['transcript'] as String? ?? '').trim()
          : '';

      if (transcriptText.isEmpty) {
        state = state.copyWith(
          conversationState: SessionConversationState.idle,
          isProcessing: false,
          error: 'I could not hear anything. Try again.',
        );
        return null;
      }

      final updatedTranscript = [
        state.transcript,
        'User: $transcriptText',
      ].where((value) => value.trim().isNotEmpty).join('\n');

      state = state.copyWith(transcript: updatedTranscript);
      await _repository.updateTranscript(state.session!.id, updatedTranscript);

      final response = await _apiClient.callFunction(
        'chat',
        data: {
          'message': transcriptText,
          'sessionContext': '${state.activityContext}\n\n$updatedTranscript',
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
          : '$updatedTranscript\nAI: $aiMessage';

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

  Future<void> captureMedia(String captureType) async {
    if (state.session == null) return;

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final file = await _pickMediaFile(captureType);
      if (file == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }

      final storagePath = await _mediaUploadService.uploadMedia(
        file: file,
        sessionId: state.session!.id,
        type: captureType,
      );

      if (storagePath == null) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Failed to upload media',
        );
        return;
      }

      final mimeType = _inferMimeType(file, captureType);
      final attachmentResult = await _repository.createMediaAttachment(
        sessionId: state.session!.id,
        type: _parseMediaType(captureType),
        storagePath: storagePath,
        mimeType: mimeType,
        fileSizeBytes: await file.length(),
        metadata: {'local_path': file.path},
      );

      final attachment = attachmentResult.dataOrNull;
      if (attachment == null) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Failed to save media attachment',
        );
        return;
      }

      final signedUrl = await _mediaUploadService.createSignedUrl(storagePath);
      final initialItem = SessionMediaItem(
        attachment: attachment,
        signedUrl: signedUrl,
        localPath: file.path,
        isAnalyzing: captureType == 'photo',
      );
      state = state.copyWith(
        mediaItems: [...state.mediaItems, initialItem],
        isProcessing: false,
      );

      if (captureType == 'photo') {
        final analysis = await _analyzePhoto(file, attachment.id, mimeType);
        if (analysis != null) {
          state = state.copyWith(aiResponse: analysis);
        }
      } else {
        await _repository.updateMediaAttachment(attachment.id, {
          'ai_analysis': captureType == 'video'
              ? 'Video uploaded for later review.'
              : 'Attachment uploaded and ready for review.',
          'analysis_status': 'skipped',
        });
        _updateMediaItem(
          attachment.id,
          (item) => item.copyWith(
            attachment: item.attachment.copyWith(analysisStatus: 'skipped'),
            analysis: captureType == 'video'
                ? 'Video uploaded for later review.'
                : 'Attachment uploaded and ready for review.',
            isAnalyzing: false,
          ),
        );
      }
    } catch (e) {
      _logger.e('Capture media failed: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to capture media',
      );
    }
  }

  Future<File?> _pickMediaFile(String captureType) {
    switch (captureType) {
      case 'photo':
        return _cameraService.takePhoto();
      case 'video':
        return _cameraService.recordVideo();
      case 'file':
        return _cameraService.pickFile();
      default:
        return Future.value(null);
    }
  }

  Future<String?> _analyzePhoto(
    File file,
    String attachmentId,
    String mimeType,
  ) async {
    try {
      final imageBytes = await file.readAsBytes();
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

  MediaType _parseMediaType(String captureType) {
    return switch (captureType) {
      'photo' => MediaType.photo,
      'video' => MediaType.video,
      _ => MediaType.file,
    };
  }

  String _inferMimeType(File file, String captureType) {
    final extension = file.path.split('.').last.toLowerCase();
    return switch (captureType) {
      'photo' => 'image/${extension == 'jpg' ? 'jpeg' : extension}',
      'video' => 'video/$extension',
      _ => switch (extension) {
        'pdf' => 'application/pdf',
        'doc' => 'application/msword',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        _ => 'application/octet-stream',
      },
    };
  }

  /// Send a chat message (for two-way chat mode)
  Future<String?> sendChatMessage(String message) async {
    if (state.session == null) return null;

    try {
      state = state.copyWith(
        isProcessing: true,
        conversationState: SessionConversationState.processing,
      );

      final response = await _apiClient.callFunction(
        'chat',
        data: {
          'message': message,
          'sessionContext': '${state.activityContext}\n\n${state.transcript}',
          'sessionId': state.session!.id,
        },
      );

      final aiMessage = response['message'] as String? ?? '';
      final referenceCards = ((response['referenceCards'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      state = state.copyWith(
        isProcessing: false,
        conversationState: SessionConversationState.idle,
        aiResponse: aiMessage,
        referenceCards: referenceCards,
        transcript: '${state.transcript}\nUser: $message\nAI: $aiMessage'
            .trim(),
      );

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

    // Stop audio pipeline
    _transcriptionTimer?.cancel();
    await _audioStreamSub?.cancel();
    await _interactiveAudioSub?.cancel();
    await _amplitudeSub?.cancel();
    await _audioService.stop();
    await _audioPlaybackService.stop();
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
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _audioStreamSub?.cancel();
    _interactiveAudioSub?.cancel();
    _amplitudeSub?.cancel();
    _audioService.dispose();
    _audioPlaybackService.dispose();
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
