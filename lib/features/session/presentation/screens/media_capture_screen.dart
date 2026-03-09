import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../shared/models/media_attachment_model.dart';
import '../../../../shared/models/session_model.dart';
import '../../../../shared/widgets/event_feed.dart';
import '../../../../shared/widgets/session_app_bar.dart';
import '../../../../shared/widgets/waveform_visualizer.dart';
import '../providers/session_provider.dart';

class MediaCaptureScreen extends ConsumerStatefulWidget {
  final String activityId;

  const MediaCaptureScreen({super.key, required this.activityId});

  @override
  ConsumerState<MediaCaptureScreen> createState() => _MediaCaptureScreenState();
}

class _MediaCaptureScreenState extends ConsumerState<MediaCaptureScreen> {
  String _selectedCapture = 'photo';

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
  Widget build(BuildContext context) {
    final sessionState = ref.watch(activeSessionProvider);
    final timerText = ref.watch(sessionTimerProvider);
    final sessionId = sessionState.session?.id;
    final isHolding =
        sessionState.conversationState == SessionConversationState.userSpeaking;
    final isAiSpeaking =
        sessionState.conversationState == SessionConversationState.aiSpeaking;
    final isProcessing =
        sessionState.conversationState == SessionConversationState.processing;
    final waveformColor = isHolding ? AppColors.passive : AppColors.chat;
    final statusText = switch (sessionState.conversationState) {
      SessionConversationState.userSpeaking =>
        'Listening for your next instruction...',
      SessionConversationState.processing => 'Analyzing your request...',
      SessionConversationState.aiSpeaking => 'AI responding...',
      SessionConversationState.idle => AppStrings.holdToTalk,
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SessionAppBar(
        title: AppStrings.mediaCapture,
        subtitle: timerText,
        accentColor: AppColors.media,
        onEndSession: () => _endSession(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.sessionGradient(AppColors.media),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.paddingM),

              // Waveform
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                ),
                child: WaveformVisualizer(
                  color: waveformColor,
                  isActive: isHolding || isAiSpeaking || isProcessing,
                  amplitude: sessionState.audioLevel,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                statusText,
                style: TextStyle(
                  color: waveformColor.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              if (sessionState.activityTitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                  ),
                  child: Text(
                    sessionState.activityTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: AppDimensions.paddingM),

              if (sessionState.aiResponse != null &&
                  sessionState.aiResponse!.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.media.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Prompt',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.media,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sessionState.aiResponse!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.paddingM),

              // Capture mode pills
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                ),
                child: Row(
                  children: [
                    _CapturePill(
                      icon: Icons.camera_alt,
                      label: 'Photo',
                      isSelected: _selectedCapture == 'photo',
                      onTap: () => setState(() => _selectedCapture = 'photo'),
                    ),
                    const SizedBox(width: 8),
                    _CapturePill(
                      icon: Icons.videocam,
                      label: 'Video',
                      isSelected: _selectedCapture == 'video',
                      onTap: () => setState(() => _selectedCapture = 'video'),
                    ),
                    const SizedBox(width: 8),
                    _CapturePill(
                      icon: Icons.attach_file,
                      label: 'File',
                      isSelected: _selectedCapture == 'file',
                      onTap: () => setState(() => _selectedCapture = 'file'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Media timeline / uploaded items
              Container(
                constraints: const BoxConstraints(
                  minHeight: 120,
                  maxHeight: 220,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.media.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: sessionState.mediaItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.media.withValues(alpha: 0.5),
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap capture to add media',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        itemCount: sessionState.mediaItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppDimensions.paddingS),
                        itemBuilder: (context, index) {
                          final item = sessionState.mediaItems[index];
                          return _MediaAttachmentCard(item: item);
                        },
                      ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Event feed
              Expanded(
                child: sessionId != null
                    ? ref
                          .watch(sessionEventsProvider(sessionId))
                          .when(
                            data: (events) => EventFeed(events: events),
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.media,
                              ),
                            ),
                            error: (e, _) => const Center(
                              child: Text(
                                'Error loading events',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          )
                    : const EventFeed(events: []),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) {
                        ref
                            .read(activeSessionProvider.notifier)
                            .startInteractiveTurn();
                      },
                      onTapUp: (_) {
                        ref
                            .read(activeSessionProvider.notifier)
                            .finishInteractiveTurn();
                      },
                      onTapCancel: () {
                        ref
                            .read(activeSessionProvider.notifier)
                            .finishInteractiveTurn();
                      },
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isHolding
                              ? AppGradients.mediaGradient
                              : null,
                          color: isHolding
                              ? null
                              : AppColors.media.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.media.withValues(
                              alpha: isHolding ? 0.8 : 0.3,
                            ),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isHolding ? Icons.mic : Icons.mic_none,
                          color: isHolding ? Colors.white : AppColors.media,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MediaControlButton(
                          icon: sessionState.isMuted
                              ? Icons.mic_off
                              : Icons.mic,
                          label: sessionState.isMuted ? 'Unmute' : 'Mute',
                          color: AppColors.media,
                          onTap: () => ref
                              .read(activeSessionProvider.notifier)
                              .toggleMute(),
                        ),
                        _MediaControlButton(
                          icon: _selectedCapture == 'photo'
                              ? Icons.camera
                              : _selectedCapture == 'video'
                              ? Icons.videocam
                              : Icons.upload_file,
                          label: sessionState.isProcessing
                              ? 'Working...'
                              : 'Capture',
                          color: AppColors.media,
                          isLarge: true,
                          onTap: _handleCapture,
                        ),
                        _MediaControlButton(
                          icon: Icons.stop_circle,
                          label: 'End',
                          color: AppColors.error,
                          onTap: () => _endSession(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCapture() async {
    await ref
        .read(activeSessionProvider.notifier)
        .captureMedia(_selectedCapture);
  }

  Future<void> _endSession(BuildContext context) async {
    final sessionId = await ref
        .read(activeSessionProvider.notifier)
        .endSession();
    if (sessionId != null && context.mounted) {
      context.go('/session/${widget.activityId}/summary?sessionId=$sessionId');
    }
  }
}

class _MediaAttachmentCard extends StatelessWidget {
  final SessionMediaItem item;

  const _MediaAttachmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.attachment.type) {
      MediaType.photo => Icons.photo_camera_back,
      MediaType.video => Icons.videocam,
      MediaType.file => Icons.attach_file,
    };

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.media.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.media, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.attachment.type.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.media,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.isAnalyzing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (item.localPath != null) ...[
            const SizedBox(height: 8),
            Text(
              item.localPath!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (item.signedUrl != null &&
              item.attachment.type == MediaType.photo) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Image.network(
                item.signedUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
          if (item.analysis?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              item.analysis!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

class _CapturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CapturePill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.media.withValues(alpha: 0.2)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: isSelected ? AppColors.media : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.media : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.media : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLarge;
  final VoidCallback onTap;

  const _MediaControlButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isLarge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 72.0 : 56.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: isLarge ? 36 : 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
