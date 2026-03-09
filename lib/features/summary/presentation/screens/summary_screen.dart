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
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
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

  void _goBackToDashboard() {
    ref.invalidate(activitiesProvider);
    ref.invalidate(sessionHistoryProvider);
    ref.read(activeSessionProvider.notifier).reset();
    context.go('/dashboard');
  }

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
                    onTap: () => _editObservationSummary(summary),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                ],

                _SectionHeader(
                  icon: Icons.visibility,
                  title: AppStrings.keyObservations,
                  color: AppColors.observation,
                  onAdd: () => _addObservation(summary),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                if (summary.keyObservations.isEmpty)
                  const _EmptySummaryState(message: 'No observations captured.')
                else
                  ...summary.keyObservations.asMap().entries.map(
                    (entry) => _SummaryItem(
                      text: entry.value,
                      color: AppColors.observation,
                      onTap: () => _editObservation(summary, entry.key),
                      onDismissed: () =>
                          _deleteObservation(summary, entry.key),
                    ),
                  ),
                const SizedBox(height: AppDimensions.paddingL),

                _SectionHeader(
                  icon: Icons.bolt,
                  title: AppStrings.actionsTaken,
                  color: AppColors.action,
                  onAdd: () => _addAction(summary),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                if (summary.actionsTaken.isEmpty &&
                    summary.actionStatuses.isEmpty)
                  const _EmptySummaryState(
                    message: 'No actions were triggered.',
                  )
                else
                  ..._buildActionItems(summary).asMap().entries.map(
                    (entry) => _ActionSummaryItem(
                      action: entry.value,
                      onTap: () => _editAction(summary, entry.key),
                      onDismissed: () => _deleteAction(summary, entry.key),
                    ),
                  ),
                const SizedBox(height: AppDimensions.paddingL),

                _SectionHeader(
                  icon: Icons.flag,
                  title: AppStrings.pendingFollowUps,
                  color: AppColors.warning,
                  onAdd: () => _addFollowUp(summary),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                if (summary.followUps.isEmpty)
                  const _EmptySummaryState(
                    message: 'No follow-ups were identified.',
                  )
                else
                  ...summary.followUps.asMap().entries.map(
                    (entry) => _FollowUpItem(
                      followUp: entry.value,
                      onTap: () => _editFollowUp(summary, entry.key),
                      onDismissed: () =>
                          _deleteFollowUp(summary, entry.key),
                    ),
                  ),
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
                onPressed: _goBackToDashboard,
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

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

  Future<void> _updateSummaryField(Map<String, dynamic> fields) async {
    final repo = ref.read(summaryRepositoryProvider);
    final result = await repo.updateSummary(widget.sessionId, fields);
    if (!mounted) return;
    result.when(
      success: (_) => ref.invalidate(summaryProvider(widget.sessionId)),
      failure: (message, _) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
    );
  }

  Future<String?> _showEditTextDialog(String current, {String label = 'Text'}) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Edit $label'),
        content: TextFormField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<FollowUpModel?> _showEditFollowUpDialog(FollowUpModel? current) {
    final descController =
        TextEditingController(text: current?.description ?? '');
    String priority = current?.priority ?? 'medium';
    DateTime? dueDate = current?.dueDate;

    return showDialog<FollowUpModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(current == null ? 'Add Follow-Up' : 'Edit Follow-Up'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descController,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (v) => setDialogState(() => priority = v ?? priority),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  dueDate != null
                      ? 'Due: ${DateFormat.yMMMd().format(dueDate!)}'
                      : 'No due date',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                    ),
                    if (dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setDialogState(() => dueDate = null),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (descController.text.trim().isEmpty) return;
                Navigator.pop(
                  context,
                  FollowUpModel(
                    description: descController.text.trim(),
                    priority: priority,
                    dueDate: dueDate,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Observation Summary ─────────────────────────────────────────────

  Future<void> _editObservationSummary(SessionSummaryModel summary) async {
    final newText = await _showEditTextDialog(
      summary.observationSummary,
      label: 'Overview',
    );
    if (newText == null || newText == summary.observationSummary) return;
    _updateSummaryField({'observation_summary': newText});
  }

  // ── Key Observations ────────────────────────────────────────────────

  Future<void> _addObservation(SessionSummaryModel summary) async {
    final text = await _showEditTextDialog('', label: 'Observation');
    if (text == null || text.trim().isEmpty) return;
    final updated = [...summary.keyObservations, text.trim()];
    _updateSummaryField({'key_observations': updated});
  }

  Future<void> _editObservation(
      SessionSummaryModel summary, int index) async {
    final text = await _showEditTextDialog(
      summary.keyObservations[index],
      label: 'Observation',
    );
    if (text == null || text == summary.keyObservations[index]) return;
    final updated = [...summary.keyObservations];
    updated[index] = text;
    _updateSummaryField({'key_observations': updated});
  }

  Future<void> _deleteObservation(
      SessionSummaryModel summary, int index) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) {
      // Re-render to undo the dismiss animation
      ref.invalidate(summaryProvider(widget.sessionId));
      return;
    }
    final updated = [...summary.keyObservations]..removeAt(index);
    _updateSummaryField({'key_observations': updated});
  }

  // ── Actions ─────────────────────────────────────────────────────────

  Future<void> _addAction(SessionSummaryModel summary) async {
    final text = await _showEditTextDialog('', label: 'Action');
    if (text == null || text.trim().isEmpty) return;
    if (summary.actionStatuses.isNotEmpty) {
      final updated = [
        ...summary.actionStatuses,
        {'label': text.trim(), 'status': 'completed'},
      ];
      _updateSummaryField({'action_statuses': updated});
    } else {
      final updated = [...summary.actionsTaken, text.trim()];
      _updateSummaryField({'actions_taken': updated});
    }
  }

  Future<void> _editAction(SessionSummaryModel summary, int index) async {
    if (summary.actionStatuses.isNotEmpty) {
      final item = summary.actionStatuses[index];
      final text = await _showEditTextDialog(
        (item['label'] ?? item['description'] ?? '').toString(),
        label: 'Action',
      );
      if (text == null) return;
      final updated = [...summary.actionStatuses];
      updated[index] = {...item, 'label': text};
      _updateSummaryField({'action_statuses': updated});
    } else {
      final text = await _showEditTextDialog(
        summary.actionsTaken[index],
        label: 'Action',
      );
      if (text == null || text == summary.actionsTaken[index]) return;
      final updated = [...summary.actionsTaken];
      updated[index] = text;
      _updateSummaryField({'actions_taken': updated});
    }
  }

  Future<void> _deleteAction(SessionSummaryModel summary, int index) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) {
      ref.invalidate(summaryProvider(widget.sessionId));
      return;
    }
    if (summary.actionStatuses.isNotEmpty) {
      final updated = [...summary.actionStatuses]..removeAt(index);
      _updateSummaryField({'action_statuses': updated});
    } else {
      final updated = [...summary.actionsTaken]..removeAt(index);
      _updateSummaryField({'actions_taken': updated});
    }
  }

  // ── Follow-Ups ──────────────────────────────────────────────────────

  Future<void> _addFollowUp(SessionSummaryModel summary) async {
    final followUp = await _showEditFollowUpDialog(null);
    if (followUp == null) return;
    final updated = [...summary.followUps, followUp];
    _updateSummaryField({
      'follow_ups': updated.map((f) => f.toJson()).toList(),
    });
  }

  Future<void> _editFollowUp(SessionSummaryModel summary, int index) async {
    final followUp =
        await _showEditFollowUpDialog(summary.followUps[index]);
    if (followUp == null) return;
    final updated = [...summary.followUps];
    updated[index] = followUp;
    _updateSummaryField({
      'follow_ups': updated.map((f) => f.toJson()).toList(),
    });
  }

  Future<void> _deleteFollowUp(
      SessionSummaryModel summary, int index) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) {
      ref.invalidate(summaryProvider(widget.sessionId));
      return;
    }
    final updated = [...summary.followUps]..removeAt(index);
    _updateSummaryField({
      'follow_ups': updated.map((f) => f.toJson()).toList(),
    });
  }

  // ── Confirm & Close ─────────────────────────────────────────────────

  Future<void> _confirmAndClose() async {
    setState(() => _isConfirming = true);

    final summaryRepo = ref.read(summaryRepositoryProvider);
    final result = await summaryRepo.confirmSummary(widget.sessionId);
    if (!mounted) return;

    result.when(
      success: (_) {
        _goBackToDashboard();
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

// ── Private Widgets ──────────────────────────────────────────────────────

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
  final VoidCallback? onAdd;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.onAdd,
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
        const Spacer(),
        if (onAdd != null)
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: color, size: 22),
            onPressed: onAdd,
            tooltip: 'Add',
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const _SummaryItem({
    required this.text,
    required this.color,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    Widget item = Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );

    if (onDismissed != null) {
      item = Dismissible(
        key: ValueKey('$text-${text.hashCode}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppDimensions.paddingL),
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDismissed!(),
        child: item,
      );
    }

    return item;
  }
}

class _ActionSummaryItem extends StatelessWidget {
  final _ActionSummaryData action;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const _ActionSummaryItem({
    required this.action,
    this.onTap,
    this.onDismissed,
  });

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

    Widget item = Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
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
      ),
    );

    if (onDismissed != null) {
      item = Dismissible(
        key: ValueKey('action-${action.label.hashCode}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppDimensions.paddingL),
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDismissed!(),
        child: item,
      );
    }

    return item;
  }
}

class _FollowUpItem extends StatelessWidget {
  final FollowUpModel followUp;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const _FollowUpItem({
    required this.followUp,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    Widget item = Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor(
                    followUp.priority,
                  ).withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
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
      ),
    );

    if (onDismissed != null) {
      item = Dismissible(
        key: ValueKey('followup-${followUp.description.hashCode}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppDimensions.paddingL),
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDismissed!(),
        child: item,
      );
    }

    return item;
  }

  Color _priorityColor(String priority) => switch (priority) {
    'high' => AppColors.error,
    'medium' => AppColors.warning,
    _ => AppColors.info,
  };
}
