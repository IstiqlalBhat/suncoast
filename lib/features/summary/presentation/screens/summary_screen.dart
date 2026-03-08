import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../features/session/presentation/providers/session_provider.dart';
import '../../../../shared/models/session_summary_model.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../providers/summary_provider.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  final String activityId;
  final String sessionId;

  const SummaryScreen({
    super.key,
    required this.activityId,
    required this.sessionId,
  });

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(summaryProvider(widget.sessionId));
    final activityAsync = ref.watch(summaryActivityProvider(widget.activityId));
    final sessionAsync = ref.watch(sessionDetailsProvider(widget.sessionId));

    final activityTitle = activityAsync.valueOrNull?.title ?? 'Field session';
    final sessionDuration =
        summaryAsync.valueOrNull?.durationSeconds ??
        sessionAsync.valueOrNull?.endedAt
            ?.difference(sessionAsync.valueOrNull?.startedAt ?? DateTime.now())
            .inSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.sessionSummary),
        automaticallyImplyLeading: false,
      ),
      body: summaryAsync.when(
        data: (summary) {
          if (summary == null) {
            return const Center(
              child: Text(
                'Generating summary...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activityTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (sessionDuration != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Elapsed time: ${_formatDuration(sessionDuration)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),

                if (summary.observationSummary.trim().isNotEmpty) ...[
                  const _SectionHeader(
                    icon: Icons.description_outlined,
                    title: 'Session Overview',
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  _SummaryItem(
                    text: summary.observationSummary.trim(),
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                ],

                const _SectionHeader(
                  icon: Icons.visibility,
                  title: AppStrings.keyObservations,
                  color: AppColors.observation,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                if (summary.keyObservations.isEmpty)
                  const _EmptySummaryState(message: 'No observations captured.')
                else
                  ...summary.keyObservations.map(
                    (obs) =>
                        _SummaryItem(text: obs, color: AppColors.observation),
                  ),
                const SizedBox(height: AppDimensions.paddingL),

                const _SectionHeader(
                  icon: Icons.bolt,
                  title: AppStrings.actionsTaken,
                  color: AppColors.action,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                if (summary.actionsTaken.isEmpty &&
                    summary.actionStatuses.isEmpty)
                  const _EmptySummaryState(
                    message: 'No actions were triggered.',
                  )
                else
                  ..._buildActionItems(
                    summary,
                  ).map((item) => _ActionSummaryItem(action: item)),
                const SizedBox(height: AppDimensions.paddingL),

                const _SectionHeader(
                  icon: Icons.flag,
                  title: AppStrings.pendingFollowUps,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                if (summary.followUps.isEmpty)
                  const _EmptySummaryState(
                    message: 'No follow-ups were identified.',
                  )
                else
                  ...summary.followUps.map((fu) => _FollowUpItem(followUp: fu)),
                const SizedBox(height: AppDimensions.paddingXL),

                GradientButton(
                  label: AppStrings.confirmAndClose,
                  icon: Icons.check_circle,
                  isLoading: _isConfirming,
                  onPressed: _isConfirming ? null : _confirmAndClose,
                ),
                const SizedBox(height: AppDimensions.paddingXL),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: AppDimensions.paddingM),
              Text(
                'Generating session summary...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                'Failed to generate summary',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ActionSummaryData> _buildActionItems(SessionSummaryModel summary) {
    if (summary.actionStatuses.isNotEmpty) {
      return summary.actionStatuses
          .map(
            (item) => _ActionSummaryData(
              label: (item['label'] ?? item['description'] ?? 'Action')
                  .toString(),
              status: (item['status'] ?? 'completed').toString(),
              externalUrl: item['external_url']?.toString(),
              externalLabel: item['external_label']?.toString(),
            ),
          )
          .toList();
    }

    return summary.actionsTaken
        .map((action) => _ActionSummaryData(label: action, status: 'completed'))
        .toList();
  }

  Future<void> _confirmAndClose() async {
    setState(() => _isConfirming = true);

    final summaryRepo = ref.read(summaryRepositoryProvider);
    final result = await summaryRepo.confirmSummary(widget.sessionId);
    if (!mounted) return;

    result.when(
      success: (_) {
        ref.read(activeSessionProvider.notifier).reset();
        context.go('/dashboard');
      },
      failure: (message, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        setState(() => _isConfirming = false);
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }
}

class _EmptySummaryState extends StatelessWidget {
  final String message;

  const _EmptySummaryState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ActionSummaryData {
  final String label;
  final String status;
  final String? externalUrl;
  final String? externalLabel;

  const _ActionSummaryData({
    required this.label,
    required this.status,
    this.externalUrl,
    this.externalLabel,
  });
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String text;
  final Color color;

  const _SummaryItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _ActionSummaryItem extends StatelessWidget {
  final _ActionSummaryData action;

  const _ActionSummaryItem({required this.action});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (action.status) {
      'in_progress' => AppColors.warning,
      'pending' => AppColors.warning,
      'failed' => AppColors.error,
      _ => AppColors.success,
    };
    final statusLabel = switch (action.status) {
      'in_progress' => 'In progress',
      'pending' => 'Pending',
      'failed' => 'Failed',
      _ => 'Done',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: const Border(
            left: BorderSide(color: AppColors.action, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (action.externalLabel != null ||
                      action.externalUrl != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      action.externalLabel ?? action.externalUrl ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.info),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpItem extends StatelessWidget {
  final FollowUpModel followUp;

  const _FollowUpItem({required this.followUp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: const Border(
            left: BorderSide(color: AppColors.warning, width: 3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    followUp.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (followUp.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Due: ${DateFormat.yMMMd().format(followUp.dueDate!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _priorityColor(
                  followUp.priority,
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                followUp.priority,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _priorityColor(followUp.priority),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) => switch (priority) {
    'high' => AppColors.error,
    'medium' => AppColors.warning,
    _ => AppColors.info,
  };
}
