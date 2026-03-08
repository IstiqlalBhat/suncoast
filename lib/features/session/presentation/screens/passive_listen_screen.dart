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

class PassiveListenScreen extends ConsumerStatefulWidget {
  final String activityId;

  const PassiveListenScreen({super.key, required this.activityId});

  @override
  ConsumerState<PassiveListenScreen> createState() =>
      _PassiveListenScreenState();
}

class _PassiveListenScreenState extends ConsumerState<PassiveListenScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(activeSessionProvider.notifier)
          .startSession(
            activityId: widget.activityId,
            mode: SessionMode.passive,
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
        title: AppStrings.passiveListen,
        subtitle: timerText,
        accentColor: AppColors.passive,
        onEndSession: () => _endSession(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.sessionGradient(AppColors.passive),
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
                  color: AppColors.passive,
                  isActive: sessionState.isRecording && !sessionState.isMuted,
                  amplitude: sessionState.audioLevel,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),

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
              const SizedBox(height: AppDimensions.paddingS),

              Text(
                sessionState.isRecording
                    ? '${sessionState.isMuted ? 'Muted' : 'Recording'} · $timerText'
                    : 'Finalizing session...',
                style: TextStyle(
                  color: AppColors.passive.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sessionState.isProcessing && sessionState.isRecording)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Analyzing latest observations...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: AppDimensions.paddingM),

              if (sessionState.error != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sessionState.error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),
              ],

              // Transcript preview
              if (sessionState.transcript.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Text(
                    sessionState.transcript.length > 200
                        ? '...${sessionState.transcript.substring(sessionState.transcript.length - 200)}'
                        : sessionState.transcript,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
                                color: AppColors.passive,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute button
                    _ControlButton(
                      icon: sessionState.isMuted ? Icons.mic_off : Icons.mic,
                      label: sessionState.isMuted
                          ? AppStrings.unmute
                          : AppStrings.mute,
                      color: AppColors.passive,
                      onTap: () =>
                          ref.read(activeSessionProvider.notifier).toggleMute(),
                    ),
                    // End session button
                    _ControlButton(
                      icon: Icons.stop_circle,
                      label: AppStrings.endSession,
                      color: AppColors.error,
                      isLarge: true,
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

  Future<void> _endSession(BuildContext context) async {
    final sessionId = await ref
        .read(activeSessionProvider.notifier)
        .endSession();
    if (sessionId != null && context.mounted) {
      context.go('/session/${widget.activityId}/summary?sessionId=$sessionId');
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLarge;
  final VoidCallback onTap;

  const _ControlButton({
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
