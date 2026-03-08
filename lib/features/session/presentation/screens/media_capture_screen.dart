import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/gradients.dart';
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
      ref.read(activeSessionProvider.notifier).startSession(
        activityId: widget.activityId,
        mode: SessionMode.media,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(activeSessionProvider);
    final timerText = ref.watch(sessionTimerProvider);
    final sessionId = sessionState.session?.id;

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
                  color: AppColors.media,
                  isActive: sessionState.isRecording && !sessionState.isMuted,
                  amplitude: sessionState.audioLevel,
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

              // Media thumbnail grid placeholder
              Container(
                height: 120,
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
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.media.withValues(alpha: 0.5),
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap capture to add media',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Event feed
              Expanded(
                child: sessionId != null
                    ? ref.watch(sessionEventsProvider(sessionId)).when(
                        data: (events) => EventFeed(events: events),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.media,
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Text('Error loading events',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      )
                    : const EventFeed(events: []),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute
                    _MediaControlButton(
                      icon: sessionState.isMuted ? Icons.mic_off : Icons.mic,
                      label: sessionState.isMuted ? 'Unmute' : 'Mute',
                      color: AppColors.media,
                      onTap: () =>
                          ref.read(activeSessionProvider.notifier).toggleMute(),
                    ),
                    // Capture
                    _MediaControlButton(
                      icon: _selectedCapture == 'photo'
                          ? Icons.camera
                          : _selectedCapture == 'video'
                              ? Icons.videocam
                              : Icons.upload_file,
                      label: 'Capture',
                      color: AppColors.media,
                      isLarge: true,
                      onTap: _handleCapture,
                    ),
                    // End
                    _MediaControlButton(
                      icon: Icons.stop_circle,
                      label: 'End',
                      color: AppColors.error,
                      onTap: () => _endSession(context),
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

  void _handleCapture() {
    // TODO: Implement camera/file picker capture
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedCapture capture coming soon'),
      ),
    );
  }

  Future<void> _endSession(BuildContext context) async {
    final sessionId = await ref.read(activeSessionProvider.notifier).endSession();
    if (sessionId != null && context.mounted) {
      context.go('/session/${widget.activityId}/summary?sessionId=$sessionId');
    }
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
                  color:
                      isSelected ? AppColors.media : AppColors.textSecondary,
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
