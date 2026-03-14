import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/session_model.dart';
import '../../../../shared/widgets/session_app_bar.dart';
import '../models/conversation_entry.dart';
import '../providers/session_provider.dart';

class MediaCaptureScreen extends ConsumerStatefulWidget {
  final String activityId;

  const MediaCaptureScreen({super.key, required this.activityId});

  @override
  ConsumerState<MediaCaptureScreen> createState() => _MediaCaptureScreenState();
}

class _MediaCaptureScreenState extends ConsumerState<MediaCaptureScreen> {
  bool _isEnding = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(activeSessionProvider.notifier)
          .startSession(activityId: widget.activityId, mode: SessionMode.media);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sessionState = ref.watch(activeSessionProvider);
    final timerText = ref.watch(sessionTimerProvider);

    // Scroll to bottom when new entries arrive
    ref.listen(activeSessionProvider, (prev, next) {
      if ((prev?.conversationEntries.length ?? 0) <
          next.conversationEntries.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: c.background,
      extendBodyBehindAppBar: true,
      appBar: SessionAppBar(
        title: sessionState.activityTitle.isNotEmpty
            ? sessionState.activityTitle
            : 'Media Assistant',
        subtitle: timerText,
        accentColor: c.media,
        onEndSession: () => _endSession(context),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Error banner
                if (sessionState.error != null)
                  _ErrorBanner(message: sessionState.error!),

                // Conversation view
                Expanded(
                  child: _ConversationView(
                    entries: sessionState.conversationEntries,
                    scrollController: _scrollController,
                    voiceStatus: sessionState.voiceStatus,
                  ),
                ),

                // Voice state indicator
                _VoiceStateIndicator(
                  voiceStatus: sessionState.voiceStatus,
                  audioLevel: sessionState.audioLevel,
                  conversationState: sessionState.conversationState,
                ),

                // Tool request card (when AI asks for media)
                if (sessionState.activeToolRequest != null)
                  _ToolRequestCard(
                    request: sessionState.activeToolRequest!,
                    onAddPhoto: () => _handleToolRequestPhoto(),
                    onAddPdf: () => _handleToolRequestPdf(),
                    onDismiss: () => ref
                        .read(activeSessionProvider.notifier)
                        .dismissToolRequest(),
                  ),

                // Bottom controls
                _BottomControls(
                  isMuted: sessionState.isMuted,
                  isProcessing: sessionState.isProcessing,
                  onToggleMute: () =>
                      ref.read(activeSessionProvider.notifier).toggleMute(),
                  onAddMedia: _handleCapture,
                  onEnd: () => _endSession(context),
                ),
              ],
            ),
          ),
          if (_isEnding)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: c.media),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      'Ending session...',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleToolRequestPhoto() async {
    final c = context.colors;
    final request = await showModalBottomSheet<MediaCaptureRequest>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => const _PhotoPickerSheet(),
    );
    if (request == null || !mounted) return;

    await ref
        .read(activeSessionProvider.notifier)
        .captureMedia(request);
  }

  Future<void> _handleToolRequestPdf() async {
    await ref.read(activeSessionProvider.notifier).captureMedia(
      const MediaCaptureRequest(
        captureType: 'pdf',
        source: MediaCaptureSource.filePicker,
      ),
    );
  }

  Future<void> _handleCapture() async {
    final c = context.colors;
    final request = await showModalBottomSheet<MediaCaptureRequest>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => const _CaptureActionSheet(),
    );
    if (request == null || !mounted) return;
    await ref.read(activeSessionProvider.notifier).captureMedia(request);
  }

  Future<void> _endSession(BuildContext context) async {
    if (_isEnding) return;
    setState(() => _isEnding = true);
    final sessionId = await ref
        .read(activeSessionProvider.notifier)
        .endSession();
    if (sessionId != null && context.mounted) {
      context.go('/session/${widget.activityId}/summary?sessionId=$sessionId');
    } else if (mounted) {
      setState(() => _isEnding = false);
    }
  }
}

// ── Conversation View ────────────────────────────────────────────

class _ConversationView extends StatelessWidget {
  final List<ConversationEntry> entries;
  final ScrollController scrollController;
  final RealtimeVoiceStatus voiceStatus;

  const _ConversationView({
    required this.entries,
    required this.scrollController,
    required this.voiceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                voiceStatus == RealtimeVoiceStatus.connecting
                    ? Icons.wifi_calling_3
                    : voiceStatus == RealtimeVoiceStatus.disconnected
                        ? Icons.mic_off_outlined
                        : Icons.graphic_eq_rounded,
                color: c.media.withValues(alpha: 0.5),
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                voiceStatus == RealtimeVoiceStatus.connecting
                    ? 'Connecting to voice assistant...'
                    : voiceStatus == RealtimeVoiceStatus.disconnected
                        ? 'Starting session...'
                        : 'Voice assistant is ready.\nSpeak or add media to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingS,
        AppDimensions.paddingM,
        AppDimensions.paddingS,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ConversationBubble(entry: entry),
        );
      },
    );
  }
}

// ── Conversation Bubble ──────────────────────────────────────────

class _ConversationBubble extends StatelessWidget {
  final ConversationEntry entry;

  const _ConversationBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isUser = entry.role == ConversationRole.user;
    final isToolRequest = entry.type == ConversationEntryType.toolRequest;
    final isMedia = entry.type == ConversationEntryType.mediaAttachment;

    if (isToolRequest) {
      return _buildToolRequestBubble(context, c);
    }

    if (isMedia) {
      return _buildMediaBubble(context, c, isUser);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? c.surface
              : c.media.withValues(alpha: 0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimensions.radiusM),
            topRight: const Radius.circular(AppDimensions.radiusM),
            bottomLeft: Radius.circular(
              isUser ? AppDimensions.radiusM : 4,
            ),
            bottomRight: Radius.circular(
              isUser ? 4 : AppDimensions.radiusM,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.text,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(entry.timestamp),
              style: TextStyle(
                color: c.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolRequestBubble(BuildContext context, AppColorScheme c) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.media.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: c.media.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            entry.toolRequest?.toolName == 'request_pdf'
                ? Icons.picture_as_pdf_outlined
                : Icons.add_a_photo_outlined,
            color: c.media,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBubble(BuildContext context, AppColorScheme c, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: c.media.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              entry.text.toLowerCase().contains('pdf')
                  ? Icons.picture_as_pdf_outlined
                  : Icons.photo_outlined,
              color: c.media,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              entry.text,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// ── Voice State Indicator ────────────────────────────────────────

class _VoiceStateIndicator extends StatelessWidget {
  final RealtimeVoiceStatus voiceStatus;
  final double audioLevel;
  final SessionConversationState conversationState;

  const _VoiceStateIndicator({
    required this.voiceStatus,
    required this.audioLevel,
    required this.conversationState,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (voiceStatus == RealtimeVoiceStatus.disconnected) {
      return const SizedBox(height: 16);
    }

    final isListening = voiceStatus == RealtimeVoiceStatus.connected ||
        voiceStatus == RealtimeVoiceStatus.listening;
    final isSpeaking = voiceStatus == RealtimeVoiceStatus.aiSpeaking ||
        conversationState == SessionConversationState.aiSpeaking;
    final isConnecting = voiceStatus == RealtimeVoiceStatus.connecting;

    final label = isConnecting
        ? 'Connecting...'
        : isSpeaking
            ? 'AI Speaking'
            : conversationState == SessionConversationState.processing
                ? 'Processing...'
                : 'Listening';

    final orbSize = 48.0 + (isListening ? audioLevel * 16.0 : 0.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow ring
                if (!isConnecting)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: orbSize + 20,
                    height: orbSize + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.media.withValues(
                            alpha: isSpeaking ? 0.3 : 0.15,
                          ),
                          blurRadius: isSpeaking ? 24 : 12,
                          spreadRadius: isSpeaking ? 4 : 1,
                        ),
                      ],
                    ),
                  ),
                // Main orb
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: orbSize,
                  height: orbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        c.media.withValues(alpha: 0.7),
                        c.media.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: isConnecting
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          isSpeaking
                              ? Icons.graphic_eq_rounded
                              : Icons.mic,
                          color: Colors.white,
                          size: 22,
                        ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                    )
                    .then(delay: Duration.zero)
                    .shimmer(
                      duration: isSpeaking
                          ? const Duration(milliseconds: 1200)
                          : const Duration(milliseconds: 2400),
                      color: c.media.withValues(alpha: 0.15),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: c.media.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tool Request Card ────────────────────────────────────────────

class _ToolRequestCard extends StatelessWidget {
  final ToolCallRequest request;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddPdf;
  final VoidCallback onDismiss;

  const _ToolRequestCard({
    required this.request,
    required this.onAddPhoto,
    required this.onAddPdf,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isImageRequest = request.toolName == 'request_image';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        0,
        AppDimensions.paddingM,
        AppDimensions.paddingS,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: c.media.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isImageRequest
                    ? Icons.add_a_photo_outlined
                    : Icons.picture_as_pdf_outlined,
                color: c.media,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.reason.isNotEmpty
                      ? request.reason
                      : isImageRequest
                          ? 'I need a photo to help you.'
                          : 'I need a PDF document.',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isImageRequest ? onAddPhoto : onAddPdf,
                  icon: Icon(
                    isImageRequest ? Icons.camera_alt_outlined : Icons.upload_file_outlined,
                    size: 16,
                  ),
                  label: Text(isImageRequest ? 'Add Photo' : 'Add PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.media,
                    foregroundColor: c.background,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textSecondary,
                  side: BorderSide(
                    color: c.divider,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: const Text('Dismiss', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: 0.2, end: 0);
  }
}

// ── Error Banner ─────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingS,
        AppDimensions.paddingM,
        0,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: c.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: c.error.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: c.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Controls ──────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final bool isMuted;
  final bool isProcessing;
  final VoidCallback onToggleMute;
  final VoidCallback onAddMedia;
  final VoidCallback onEnd;

  const _BottomControls({
    required this.isMuted,
    required this.isProcessing,
    required this.onToggleMute,
    required this.onAddMedia,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingL,
            AppDimensions.paddingM,
            AppDimensions.paddingL,
            AppDimensions.paddingS,
          ),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: c.divider.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: isMuted ? Icons.mic_off_outlined : Icons.mic_none,
                label: isMuted ? 'Unmute' : 'Mute',
                color: isMuted ? c.error : c.media,
                onTap: onToggleMute,
              ),
              _ControlButton(
                icon: Icons.add_photo_alternate_outlined,
                label: 'Add Media',
                color: c.media,
                onTap: isProcessing ? null : onAddMedia,
                isLarge: true,
              ),
              _ControlButton(
                icon: Icons.stop_circle_outlined,
                label: 'End',
                color: c.error,
                onTap: onEnd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLarge;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = isLarge ? 56.0 : 48.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: onTap == null ? 0.06 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: onTap == null ? 0.1 : 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: onTap == null
                  ? color.withValues(alpha: 0.4)
                  : color,
              size: isLarge ? 26 : 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: onTap == null
                ? c.textTertiary
                : c.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Capture Action Sheet (3 options) ─────────────────────────────

class _CaptureActionSheet extends StatelessWidget {
  const _CaptureActionSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingM,
          10,
          AppDimensions.paddingM,
          AppDimensions.paddingM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add media',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Share a photo or document with the voice assistant.',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const _CaptureActionTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take photo',
              subtitle: 'Open the camera to capture an image.',
              request: MediaCaptureRequest(
                captureType: 'photo',
                source: MediaCaptureSource.camera,
              ),
            ),
            const SizedBox(height: 8),
            const _CaptureActionTile(
              icon: Icons.photo_library_outlined,
              title: 'Upload photo',
              subtitle: 'Choose an existing image from your library.',
              request: MediaCaptureRequest(
                captureType: 'photo',
                source: MediaCaptureSource.gallery,
              ),
            ),
            const SizedBox(height: 8),
            const _CaptureActionTile(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Upload PDF',
              subtitle: 'Share a PDF document for analysis.',
              request: MediaCaptureRequest(
                captureType: 'pdf',
                source: MediaCaptureSource.filePicker,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo Picker Sheet (for tool call image requests) ────────────

class _PhotoPickerSheet extends StatelessWidget {
  const _PhotoPickerSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingM,
          10,
          AppDimensions.paddingM,
          AppDimensions.paddingM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add a photo',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const _CaptureActionTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take photo',
              subtitle: 'Open the camera.',
              request: MediaCaptureRequest(
                captureType: 'photo',
                source: MediaCaptureSource.camera,
              ),
            ),
            const SizedBox(height: 8),
            const _CaptureActionTile(
              icon: Icons.photo_library_outlined,
              title: 'Upload photo',
              subtitle: 'Choose from your library.',
              request: MediaCaptureRequest(
                captureType: 'photo',
                source: MediaCaptureSource.gallery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Capture Action Tile ──────────────────────────────────────────

class _CaptureActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final MediaCaptureRequest request;

  const _CaptureActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Material(
      color: c.surface.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        onTap: () => Navigator.of(context).pop(request),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.media.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: c.media, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
