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

class VoiceChatScreen extends ConsumerStatefulWidget {
  final String activityId;

  const VoiceChatScreen({super.key, required this.activityId});

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen> {
  bool _isHolding = false;
  bool _showReferencePanel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeSessionProvider.notifier).startSession(
        activityId: widget.activityId,
        mode: SessionMode.chat,
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
        title: AppStrings.voiceChat,
        subtitle: timerText,
        accentColor: AppColors.chat,
        onEndSession: () => _endSession(context),
        actions: [
          IconButton(
            icon: Icon(
              _showReferencePanel ? Icons.info : Icons.info_outline,
              color: AppColors.chat,
            ),
            onPressed: () {
              setState(() => _showReferencePanel = !_showReferencePanel);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.sessionGradient(AppColors.chat),
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
                  color: AppColors.chat,
                  isActive: _isHolding,
                  amplitude: sessionState.audioLevel,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),

              // Status
              Text(
                _isHolding ? AppStrings.listening : AppStrings.holdToTalk,
                style: TextStyle(
                  color: AppColors.chat.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Reference panel (collapsible)
              if (_showReferencePanel)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.chat.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: AppColors.chat),
                          const SizedBox(width: 8),
                          Text(
                            'AI Reference',
                            style: TextStyle(
                              color: AppColors.chat,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reference cards will appear here during conversation.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.paddingS),

              // Event feed
              Expanded(
                child: sessionId != null
                    ? ref.watch(sessionEventsProvider(sessionId)).when(
                        data: (events) => EventFeed(events: events),
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.chat),
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
                child: Column(
                  children: [
                    // Hold-to-talk button
                    GestureDetector(
                      onLongPressStart: (_) => setState(() => _isHolding = true),
                      onLongPressEnd: (_) => setState(() => _isHolding = false),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isHolding
                              ? AppGradients.chatGradient
                              : null,
                          color: _isHolding ? null : AppColors.chat.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.chat.withValues(alpha: _isHolding ? 0.8 : 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _isHolding ? Icons.mic : Icons.mic_none,
                          color: _isHolding ? Colors.white : AppColors.chat,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    // End session
                    TextButton.icon(
                      onPressed: () => _endSession(context),
                      icon: Icon(Icons.stop, color: AppColors.error, size: 18),
                      label: Text(
                        AppStrings.endSession,
                        style: TextStyle(color: AppColors.error),
                      ),
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
    final sessionId = await ref.read(activeSessionProvider.notifier).endSession();
    if (sessionId != null && context.mounted) {
      context.go('/session/${widget.activityId}/summary?sessionId=$sessionId');
    }
  }
}
