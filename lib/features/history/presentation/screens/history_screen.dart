import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/session_type_icon.dart';
import '../../../session/presentation/providers/session_provider.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>>? _localSessions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sessionsAsync = ref.watch(sessionHistoryProvider);

    ref.listen(sessionHistoryProvider, (_, next) {
      next.whenData((data) {
        setState(() => _localSessions = List.of(data));
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Session History'), centerTitle: false),
      body: Stack(
        children: [
          // Decorative background
          Positioned(
            top: 40,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.deepForest.withValues(alpha: 0.35),
              ),
            ),
          ),

          // Content
          sessionsAsync.when(
            data: (sessions) {
              final displaySessions = _localSessions ?? List.of(sessions);
              _localSessions ??= displaySessions;

              if (displaySessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Concentric rings empty state
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: c.textTertiary
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: c.textTertiary
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.textTertiary
                                    .withValues(alpha: 0.06),
                              ),
                              child: Icon(
                                Icons.history,
                                size: 22,
                                color: c.textTertiary
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No sessions yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                      Text(
                        'Start an activity to create your first session',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: c.textTertiary,
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
                color: c.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  itemCount: displaySessions.length,
                  itemBuilder: (context, index) {
                    final session = displaySessions[index];
                    final sessionId = session['id'] as String?;
                    return Dismissible(
                      key: ValueKey(sessionId ?? index),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(
                          right: AppDimensions.paddingL,
                        ),
                        margin: const EdgeInsets.only(
                          bottom: AppDimensions.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: c.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: c.error,
                        ),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context),
                      onDismissed: (_) {
                        setState(() => _localSessions!.removeAt(index));
                        if (sessionId != null) {
                          ref
                              .read(sessionRepositoryProvider)
                              .deleteSession(sessionId);
                        }
                      },
                      child: _SessionHistoryCard(
                        session: session,
                        onTap: () {
                          if (session['activity_id'] != null &&
                              sessionId != null) {
                            context.push(
                              '/session/${session['activity_id']}/summary?sessionId=$sessionId',
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: c.primary),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: c.error,
                  ),
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
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    final c = context.colors;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.card,
        title: const Text('Delete Session'),
        content: const Text(
          'This will permanently delete the session and all its events, attachments, and summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: c.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;

  const _SessionHistoryCard({required this.session, required this.onTap});

  Color _modeColor(AppColorScheme c) {
    final mode = session['mode'] as String? ?? '';
    return switch (mode) {
      'passive' => c.passive,
      'chat' => c.chat,
      'media' => c.media,
      _ => c.primary,
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
    final c = context.colors;
    final modeColor = _modeColor(c);

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

    final activityTitle = session['activities'] != null
        ? (session['activities']['title'] as String? ?? 'Session')
        : 'Session';

    final blendStrength = isActive ? 0.18 : 0.10;
    final mode = session['mode'] as String? ?? 'passive';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Color.lerp(c.card, modeColor, blendStrength)!,
            Color.lerp(c.card, modeColor, 0.03)!,
            c.card,
          ],
          stops: const [0.0, 0.25, 0.5],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: isActive
            ? Border.all(color: modeColor.withValues(alpha: 0.2))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                // Custom painted icon
                SizedBox(
                  width: 32,
                  height: 32,
                  child: SessionTypeIcon(mode: mode, color: modeColor, size: 32),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activityTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Mode pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: modeColor.withValues(alpha: 0.1),
                            ),
                            child: Text(
                              isActive ? 'LIVE' : _modeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: modeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (duration.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.textTertiary
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              duration,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: c.textTertiary),
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
                        DateFormat('MMM d, h:mm a')
                            .format(startedAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: c.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: modeColor.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: modeColor.withValues(alpha: 0.7),
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
