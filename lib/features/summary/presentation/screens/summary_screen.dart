import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../features/session/presentation/providers/session_provider.dart';
import '../../../../shared/models/session_summary_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../providers/summary_provider.dart';
import '../utils/summary_export.dart';

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
    final colors = context.colors;
    final summaryAsync = ref.watch(summaryProvider(widget.sessionId));
    final activityAsync =
        ref.watch(summaryActivityProvider(widget.activityId));
    final sessionAsync = ref.watch(sessionDetailsProvider(widget.sessionId));

    final activityTitle = activityAsync.valueOrNull?.title ?? 'Field session';
    final sessionDuration =
        summaryAsync.valueOrNull?.durationSeconds ??
        sessionAsync.valueOrNull?.endedAt
            ?.difference(
              sessionAsync.valueOrNull?.startedAt ?? DateTime.now(),
            )
            .inSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.sessionSummary),
        automaticallyImplyLeading: false,
        actions: [
          if (summaryAsync.valueOrNull != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.deepForest.withValues(alpha: 0.6),
              ),
              child: IconButton(
                icon: Icon(Icons.share, color: colors.primary, size: 20),
                tooltip: 'Share summary',
                onPressed: () => _showShareOptions(
                  summaryAsync.valueOrNull!,
                  activityTitle,
                  sessionDuration,
                ),
              ),
            ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) {
          if (summary == null) {
            return Center(
              child: Text(
                'Generating summary...',
                style: TextStyle(color: colors.textSecondary),
              ),
            );
          }

          return Stack(
            children: [
              // Decorative background
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.deepForest.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Positioned(
                bottom: 200,
                left: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.observation.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),

              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header card with circular timer ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activityTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                if (sessionDuration != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDuration(sessionDuration),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Circular timer indicator
                          if (sessionDuration != null)
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.deepForest,
                                border: Border.all(
                                  color: colors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                color: colors.primary,
                                size: 22,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Session Overview ──
                    if (summary.observationSummary.trim().isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.description_outlined,
                        title: 'Session Overview',
                        color: colors.primaryLight,
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        text: summary.observationSummary.trim(),
                        color: colors.primaryLight,
                        onTap: () => _editObservationSummary(summary),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Key Observations ──
                    _SectionHeader(
                      icon: Icons.visibility,
                      title: AppStrings.keyObservations,
                      color: colors.observation,
                      onAdd: () => _addObservation(summary),
                    ),
                    const SizedBox(height: 12),
                    if (summary.keyObservations.isEmpty)
                      const _EmptySummaryState(
                        message: 'No observations captured.',
                      )
                    else
                      ...summary.keyObservations.asMap().entries.map(
                        (entry) => _NumberedSummaryItem(
                          number: entry.key + 1,
                          text: entry.value,
                          color: colors.observation,
                          onTap: () =>
                              _editObservation(summary, entry.key),
                          onDismissed: () =>
                              _deleteObservation(summary, entry.key),
                        ),
                      ),
                    const SizedBox(height: 28),

                    // ── Actions Taken ──
                    _SectionHeader(
                      icon: Icons.bolt,
                      title: AppStrings.actionsTaken,
                      color: colors.action,
                      onAdd: () => _addAction(summary),
                    ),
                    const SizedBox(height: 12),
                    if (summary.actionsTaken.isEmpty &&
                        summary.actionStatuses.isEmpty)
                      const _EmptySummaryState(
                        message: 'No actions were triggered.',
                      )
                    else
                      ..._buildActionItems(summary).asMap().entries.map(
                        (entry) => _ActionSummaryItem(
                          action: entry.value,
                          index: entry.key + 1,
                          onTap: () =>
                              _editAction(summary, entry.key),
                          onDismissed: () =>
                              _deleteAction(summary, entry.key),
                        ),
                      ),
                    const SizedBox(height: 28),

                    // ── Pending Follow-ups ──
                    _SectionHeader(
                      icon: Icons.flag,
                      title: AppStrings.pendingFollowUps,
                      color: colors.warning,
                      onAdd: () => _addFollowUp(summary),
                    ),
                    const SizedBox(height: 12),
                    if (summary.followUps.isEmpty)
                      const _EmptySummaryState(
                        message: 'No follow-ups were identified.',
                      )
                    else
                      ...summary.followUps.asMap().entries.map(
                        (entry) => _FollowUpItem(
                          followUp: entry.value,
                          index: entry.key + 1,
                          onTap: () =>
                              _editFollowUp(summary, entry.key),
                          onDismissed: () =>
                              _deleteFollowUp(summary, entry.key),
                        ),
                      ),
                    const SizedBox(height: 36),

                    // ── Confirm button (pill with glow) ──
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color:
                                colors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isConfirming ? null : _confirmAndClose,
                          icon: _isConfirming
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.check_circle, size: 20),
                          label: Text(
                            _isConfirming
                                ? 'Confirming...'
                                : AppStrings.confirmAndClose,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Concentric rings loading
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: colors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Generating session summary...',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: colors.error,
                size: 48,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                'Failed to generate summary',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              ElevatedButton(
                onPressed: _goBackToDashboard,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ── All business logic methods (unchanged) ─────────────────
  // ═══════════════════════════════════════════════════════════════

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
        .map(
          (action) =>
              _ActionSummaryData(label: action, status: 'completed'),
        )
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

  Future<String?> _showEditTextDialog(
    String current, {
    String label = 'Text',
  }) {
    final controller = TextEditingController(text: current);
    final colors = context.colors;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
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
    final colors = context.colors;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
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
    final colors = context.colors;

    return showDialog<FollowUpModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colors.card,
          title:
              Text(current == null ? 'Add Follow-Up' : 'Edit Follow-Up'),
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
                onChanged: (v) =>
                    setDialogState(() => priority = v ?? priority),
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
                        onPressed: () =>
                            setDialogState(() => dueDate = null),
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

  Future<void> _editObservationSummary(SessionSummaryModel summary) async {
    final newText = await _showEditTextDialog(
      summary.observationSummary,
      label: 'Overview',
    );
    if (newText == null || newText == summary.observationSummary) return;
    _updateSummaryField({'observation_summary': newText});
  }

  Future<void> _addObservation(SessionSummaryModel summary) async {
    final text = await _showEditTextDialog('', label: 'Observation');
    if (text == null || text.trim().isEmpty) return;
    final updated = [...summary.keyObservations, text.trim()];
    _updateSummaryField({'key_observations': updated});
  }

  Future<void> _editObservation(
    SessionSummaryModel summary,
    int index,
  ) async {
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
    SessionSummaryModel summary,
    int index,
  ) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) {
      ref.invalidate(summaryProvider(widget.sessionId));
      return;
    }
    final updated = [...summary.keyObservations]..removeAt(index);
    _updateSummaryField({'key_observations': updated});
  }

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

  Future<void> _addFollowUp(SessionSummaryModel summary) async {
    final followUp = await _showEditFollowUpDialog(null);
    if (followUp == null) return;
    final updated = [...summary.followUps, followUp];
    _updateSummaryField({
      'follow_ups': updated.map((f) => f.toJson()).toList(),
    });
  }

  Future<void> _editFollowUp(
    SessionSummaryModel summary,
    int index,
  ) async {
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
    SessionSummaryModel summary,
    int index,
  ) async {
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

  void _showShareOptions(
    SessionSummaryModel summary,
    String activityTitle,
    int? durationSeconds,
  ) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Share Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _ShareOption(
                icon: Icons.picture_as_pdf,
                iconColor: colors.error,
                title: 'Share as PDF',
                subtitle: 'Formatted document',
                onTap: () {
                  Navigator.pop(context);
                  _shareAs(
                    summary: summary,
                    activityTitle: activityTitle,
                    durationSeconds: durationSeconds,
                    asPdf: true,
                  );
                },
              ),
              const SizedBox(height: 8),
              _ShareOption(
                icon: Icons.description_outlined,
                iconColor: colors.primary,
                title: 'Share as Markdown',
                subtitle: 'Plain text format',
                onTap: () {
                  Navigator.pop(context);
                  _shareAs(
                    summary: summary,
                    activityTitle: activityTitle,
                    durationSeconds: durationSeconds,
                    asPdf: false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareAs({
    required SessionSummaryModel summary,
    required String activityTitle,
    int? durationSeconds,
    required bool asPdf,
  }) async {
    try {
      if (asPdf) {
        await SummaryExport.shareAsPdf(
          summary: summary,
          activityTitle: activityTitle,
          durationSeconds: durationSeconds,
        );
      } else {
        await SummaryExport.shareAsMarkdown(
          summary: summary,
          activityTitle: activityTitle,
          durationSeconds: durationSeconds,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }

  Future<void> _confirmAndClose() async {
    setState(() => _isConfirming = true);
    final summaryRepo = ref.read(summaryRepositoryProvider);
    final result = await summaryRepo.confirmSummary(widget.sessionId);
    if (!mounted) return;
    result.when(
      success: (_) => _goBackToDashboard(),
      failure: (message, _) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        setState(() => _isConfirming = false);
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) return '${minutes}m ${secs}s';
    return '${secs}s';
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Section Header (circular icon container) ─────────────────
// ═══════════════════════════════════════════════════════════════

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
        // Circular icon container
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(Icons.add, color: color, size: 18),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Summary Card (overview text, no number) ──────────────────
// ═══════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: c.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.textTertiary.withValues(alpha: 0.08),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: c.textTertiary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Numbered Summary Item (with circular number) ─────────────
// ═══════════════════════════════════════════════════════════════

class _NumberedSummaryItem extends StatelessWidget {
  final int number;
  final String text;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const _NumberedSummaryItem({
    required this.number,
    required this.text,
    required this.color,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numbered circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: c.textPrimary,
                          height: 1.4,
                        ),
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: c.textTertiary.withValues(alpha: 0.4),
                  ),
                ),
              ],
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
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: c.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(Icons.delete_outline, color: c.error),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDismissed!(),
        child: item,
      );
    }

    return item;
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Action Summary Item (with status dot) ────────────────────
// ═══════════════════════════════════════════════════════════════

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

class _ActionSummaryItem extends StatelessWidget {
  final _ActionSummaryData action;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const _ActionSummaryItem({
    required this.action,
    required this.index,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final statusColor = switch (action.status) {
      'in_progress' => c.warning,
      'pending' => c.warning,
      'failed' => c.error,
      _ => c.success,
    };
    final statusLabel = switch (action.status) {
      'in_progress' => 'In progress',
      'pending' => 'Pending',
      'failed' => 'Failed',
      _ => 'Done',
    };

    Widget item = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numbered circle in action color
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.action.withValues(alpha: 0.15),
                  border: Border.all(
                    color: c.action.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.action,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        action.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: c.textPrimary),
                      ),
                    ),
                    if (action.externalLabel != null ||
                        action.externalUrl != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        action.externalLabel ?? action.externalUrl ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: c.info),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status pill
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
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

    if (onDismissed != null) {
      item = Dismissible(
        key: ValueKey('action-${action.label.hashCode}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: c.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(Icons.delete_outline, color: c.error),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDismissed!(),
        child: item,
      );
    }

    return item;
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Follow-Up Item (with priority circle) ────────────────────
// ═══════════════════════════════════════════════════════════════

class _FollowUpItem extends StatelessWidget {
  final FollowUpModel followUp;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const _FollowUpItem({
    required this.followUp,
    required this.index,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Color priorityColor(String priority) => switch (priority) {
      'high' => c.error,
      'medium' => c.warning,
      _ => c.info,
    };

    final pColor = priorityColor(followUp.priority);

    Widget item = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numbered circle in warning color
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.warning.withValues(alpha: 0.15),
                  border: Border.all(
                    color: c.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.warning,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        followUp.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: c.textPrimary),
                      ),
                    ),
                    if (followUp.dueDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color:
                                c.textTertiary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.yMMMd().format(followUp.dueDate!),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: c.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Priority dot + label
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      followUp.priority,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: pColor,
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

    if (onDismissed != null) {
      item = Dismissible(
        key: ValueKey('followup-${followUp.description.hashCode}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: c.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(Icons.delete_outline, color: c.error),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDismissed!(),
        child: item,
      );
    }

    return item;
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Empty State ──────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _EmptySummaryState extends StatelessWidget {
  final String message;

  const _EmptySummaryState({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: c.textSecondary),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Share Option Tile ────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: c.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: c.textTertiary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
