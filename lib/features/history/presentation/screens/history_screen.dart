import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Session History'), centerTitle: false),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'No sessions yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Start an activity to create your first session',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sessionHistoryProvider);
            },
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _SessionHistoryCard(
                  session: session,
                  onTap: () {
                    if (session['activity_id'] != null) {
                      context.push(
                        '/session/${session['activity_id']}/summary',
                      );
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppDimensions.paddingM),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.paddingM),
              ElevatedButton(
                onPressed: () => ref.invalidate(sessionHistoryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;

  const _SessionHistoryCard({required this.session, required this.onTap});

  Color get _modeColor {
    final mode = session['mode'] as String? ?? '';
    return switch (mode) {
      'passive' => AppColors.passive,
      'chat' => AppColors.chat,
      'media' => AppColors.media,
      _ => AppColors.primary,
    };
  }

  IconData get _modeIcon {
    final mode = session['mode'] as String? ?? '';
    return switch (mode) {
      'passive' => Icons.hearing,
      'chat' => Icons.chat_bubble_outline,
      'media' => Icons.camera_alt_outlined,
      _ => Icons.mic,
    };
  }

  String get _modeLabel {
    final mode = session['mode'] as String? ?? '';
    return switch (mode) {
      'passive' => 'Passive',
      'chat' => 'Chat',
      'media' => 'Media',
      _ => 'Session',
    };
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = session['started_at'] != null
        ? DateTime.tryParse(session['started_at'])
        : null;
    final endedAt = session['ended_at'] != null
        ? DateTime.tryParse(session['ended_at'])
        : null;
    final isActive = endedAt == null;

    String duration = '';
    if (startedAt != null && endedAt != null) {
      final diff = endedAt.difference(startedAt);
      if (diff.inHours > 0) {
        duration = '${diff.inHours}h ${diff.inMinutes % 60}m';
      } else {
        duration = '${diff.inMinutes}m';
      }
    }

    // Get activity title from joined data
    final activityTitle = session['activities'] != null
        ? (session['activities']['title'] as String? ?? 'Session')
        : 'Session';

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        side: isActive
            ? BorderSide(color: _modeColor.withValues(alpha: 0.5), width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              // Mode icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _modeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_modeIcon, color: _modeColor, size: 22),
              ),
              const SizedBox(width: AppDimensions.paddingM),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _modeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'LIVE' : _modeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _modeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (duration.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            duration,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Date & arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (startedAt != null)
                    Text(
                      DateFormat('MMM d, h:mm a').format(startedAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
