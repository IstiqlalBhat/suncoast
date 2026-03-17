import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../shared/models/session_model.dart';
import '../../../../shared/widgets/event_feed.dart';
import '../../../../shared/widgets/session_app_bar.dart';
import '../../../../shared/widgets/waveform_visualizer.dart';
import '../../../summary/presentation/providers/summary_provider.dart';
import '../providers/session_provider.dart';

class VoiceChatScreen extends ConsumerStatefulWidget {
  final String activityId;

  const VoiceChatScreen({super.key, required this.activityId});

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen> {
  bool _showReferencePanel = false;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(activeSessionProvider.notifier)
          .startSession(activityId: widget.activityId, mode: SessionMode.chat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sessionState = ref.watch(activeSessionProvider);
    final timerText = ref.watch(sessionTimerProvider);
    final sessionId = sessionState.session?.id;
    final isConversation = sessionState.isConversationActive;
    final isHolding =
        sessionState.conversationState == SessionConversationState.userSpeaking;
    final isAiSpeaking =
        sessionState.conversationState == SessionConversationState.aiSpeaking;
    final isProcessing =
        sessionState.conversationState == SessionConversationState.processing;
    final isMuted = sessionState.isMuted;

    // Waveform color and status adapt to conversation vs push-to-talk mode
    final waveformColor = isConversation
        ? (isAiSpeaking ? c.chat : c.passive)
        : (isHolding ? c.passive : c.chat);

    final statusText = isConversation
        ? (isAiSpeaking
            ? 'AI responding...'
            : isMuted
                ? 'Muted'
                : 'Listening...')
        : switch (sessionState.conversationState) {
            SessionConversationState.userSpeaking => 'Listening...',
            SessionConversationState.processing => 'Thinking...',
            SessionConversationState.aiSpeaking => 'AI responding...',
            SessionConversationState.idle => AppStrings.holdToTalk,
          };

    final referenceCards = sessionState.referenceCards;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SessionAppBar(
        title: AppStrings.voiceChat,
        subtitle: timerText,
        accentColor: c.chat,
        onEndSession: () => _endSession(context),
        actions: [
          IconButton(
            icon: Icon(
              _showReferencePanel ? Icons.info : Icons.info_outline,
              color: c.chat,
            ),
            onPressed: () {
              setState(() => _showReferencePanel = !_showReferencePanel);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
        decoration: BoxDecoration(
          gradient: AppGradients.sessionGradient(c.chat, c),
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
                  isActive: isConversation
                      ? (!isMuted || isAiSpeaking)
                      : (isHolding || isAiSpeaking || isProcessing),
                  amplitude: sessionState.audioLevel,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),

              // Status
              Text(
                statusText,
                style: TextStyle(
                  color: waveformColor.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
                      color: c.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: AppDimensions.paddingM),

              if (sessionState.error != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                  ),
                  constraints: const BoxConstraints(maxHeight: 80),
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: c.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: c.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: c.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sessionState.error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: c.textPrimary),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Reference panel (collapsible)
              if (_showReferencePanel && referenceCards.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: c.chat.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: c.chat,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Reference',
                            style: TextStyle(
                              color: c.chat,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (referenceCards.isEmpty)
                        Text(
                          'Reference cards will appear here during conversation.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        ...referenceCards.map(
                          (card) => _ReferenceCard(
                            card: card,
                            accentColor: c.chat,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.paddingS),

              // Event feed
              Expanded(
                child: sessionId != null
                    ? ref
                          .watch(sessionEventsProvider(sessionId))
                          .when(
                            data: (events) => EventFeed(
                              events: events,
                              onEditEvent: (event, fields) => ref
                                  .read(sessionRepositoryProvider)
                                  .updateAiEvent(event.id, fields),
                              onDeleteEvent: (event) => ref
                                  .read(sessionRepositoryProvider)
                                  .deleteAiEvent(event.id),
                            ),
                            loading: () => Center(
                              child: CircularProgressIndicator(
                                color: c.chat,
                              ),
                            ),
                            error: (e, _) => Center(
                              child: Text(
                                'Error loading events',
                                style: TextStyle(color: c.error),
                              ),
                            ),
                          )
                    : const EventFeed(events: []),
              ),

              // Bottom controls — conversation mode vs push-to-talk fallback
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  children: [
                    if (isConversation)
                      // Always-listening mode: mute/unmute toggle
                      GestureDetector(
                        onTap: () => ref
                            .read(activeSessionProvider.notifier)
                            .toggleMute(),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isMuted ? null : AppGradients.chatGradient(c),
                            color: isMuted
                                ? c.error.withValues(alpha: 0.15)
                                : null,
                            border: Border.all(
                              color: isMuted
                                  ? c.error.withValues(alpha: 0.5)
                                  : c.chat.withValues(alpha: 0.8),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isMuted ? Icons.mic_off : Icons.mic,
                            color: isMuted ? c.error : Colors.white,
                            size: 40,
                          ),
                        ),
                      )
                    else
                      // Push-to-talk fallback
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
                            gradient:
                                isHolding ? AppGradients.chatGradient(c) : null,
                            color: isHolding
                                ? null
                                : c.chat.withValues(alpha: 0.15),
                            border: Border.all(
                              color: c.chat.withValues(
                                alpha: isHolding ? 0.8 : 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isHolding ? Icons.mic : Icons.mic_none,
                            color: isHolding ? Colors.white : c.chat,
                            size: 40,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppDimensions.paddingM),
                    // End session
                    TextButton.icon(
                      onPressed: () => _endSession(context),
                      icon: Icon(
                        Icons.stop,
                        color: c.error,
                        size: 18,
                      ),
                      label: Text(
                        AppStrings.endSession,
                        style: TextStyle(color: c.error),
                      ),
                    ),
                  ],
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

  void _endSession(BuildContext context) {
    if (_isEnding) return;
    _isEnding = true;
    final sessionId = ref.read(activeSessionProvider).session?.id;
    if (sessionId == null) return;

    // Navigate immediately — no blocking overlay
    triggerSummaryGeneration(ref, sessionId);
    context.go('/session/${widget.activityId}/summary?sessionId=$sessionId');

    // Clean up session in the background
    ref.read(activeSessionProvider.notifier).endSession();
  }
}

class _ReferenceCard extends StatelessWidget {
  final Map<String, dynamic> card;
  final Color accentColor;

  const _ReferenceCard({required this.card, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = (card['type'] as String? ?? 'info').toLowerCase();
    final title = card['title'] as String? ?? 'Reference';
    final content = card['content'] as String? ?? '';
    final subtitle = card['subtitle'] as String?;
    final cardColor = switch (type) {
      'task' => c.success,
      'contact' => c.info,
      'suggestion' => c.textSecondary,
      _ => accentColor,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border(left: BorderSide(color: cardColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ],
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}
