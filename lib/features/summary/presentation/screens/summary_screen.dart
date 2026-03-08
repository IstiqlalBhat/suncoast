import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../providers/summary_provider.dart';

class SummaryScreen extends ConsumerWidget {
  final String activityId;
  final String sessionId;

  const SummaryScreen({
    super.key,
    required this.activityId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider(sessionId));

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
                // Duration
                if (summary.durationSeconds != null)
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Duration: ${_formatDuration(summary.durationSeconds!)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppDimensions.paddingL),

                // Key Observations
                _SectionHeader(
                  icon: Icons.visibility,
                  title: AppStrings.keyObservations,
                  color: AppColors.observation,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                ...summary.keyObservations.map(
                  (obs) => _SummaryItem(
                    text: obs,
                    color: AppColors.observation,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),

                // Actions Taken
                _SectionHeader(
                  icon: Icons.bolt,
                  title: AppStrings.actionsTaken,
                  color: AppColors.action,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                ...summary.actionsTaken.map(
                  (action) => _SummaryItem(
                    text: action,
                    color: AppColors.action,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),

                // Follow-ups
                _SectionHeader(
                  icon: Icons.flag,
                  title: AppStrings.pendingFollowUps,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                ...summary.followUps.map(
                  (fu) => _FollowUpItem(followUp: fu),
                ),
                const SizedBox(height: AppDimensions.paddingXL),

                // Confirm & Close
                GradientButton(
                  label: AppStrings.confirmAndClose,
                  icon: Icons.check_circle,
                  onPressed: () => context.go('/dashboard'),
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
          ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FollowUpItem extends StatelessWidget {
  final dynamic followUp;

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
          border: Border(
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
                    followUp.description as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (followUp.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Due: ${followUp.dueDate}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _priorityColor(followUp.priority as String)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                followUp.priority as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _priorityColor(followUp.priority as String),
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
