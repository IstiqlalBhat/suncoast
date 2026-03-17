import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../../shared/widgets/session_type_icon.dart';
import '../../../session/presentation/providers/session_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/activity_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateActivitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateActivitySheet(
        onCreated: (activity) {
          ref.read(activitiesProvider.notifier).refresh();
          final route = activity.type.routeSegment;
          context.push('/session/${activity.id}/$route');
        },
      ),
    );
  }

  Future<void> _openActivity(ActivityModel activity) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }
    final latestActivityResult =
        await ref.read(activityRepositoryProvider).getActivity(activity.id);
    if (!latestActivityResult.isSuccess) {
      final message = latestActivityResult.when(
        success: (_) => 'Failed to open activity.',
        failure: (errorMessage, _) => errorMessage,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    final latestActivity = latestActivityResult.dataOrNull ?? activity;
    final latestSessionResult = await ref
        .read(sessionRepositoryProvider)
        .getLatestCompletedSessionForActivity(
          activityId: latestActivity.id,
          userId: userId,
        );
    if (!mounted) return;
    final latestCompletedSession = latestSessionResult.dataOrNull;
    if (latestCompletedSession != null) {
      context.push(
        '/session/${latestActivity.id}/summary?sessionId=${latestCompletedSession.id}',
      );
      return;
    }
    if (!latestSessionResult.isSuccess) {
      final message = latestSessionResult.when(
        success: (_) => 'Failed to open activity.',
        failure: (errorMessage, _) => errorMessage,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    if (latestActivity.status == ActivityStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No completed session summary found.')),
      );
      return;
    }
    final route = latestActivity.type.routeSegment;
    if (!mounted) return;
    context.push('/session/${latestActivity.id}/$route');
  }

  Future<void> _confirmDeleteActivity(ActivityModel activity) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete activity'),
        content: Text(
          'Delete "${activity.title}" and all sessions linked to it? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child:
                Text('Delete', style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final message =
        await ref.read(activitiesProvider.notifier).deleteActivity(activity.id);
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _markActivityCompleted(ActivityModel activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark activity completed'),
        content: Text(
          'Mark "${activity.title}" as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Mark completed'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final message = await ref
        .read(activitiesProvider.notifier)
        .updateActivityStatus(activity.id, ActivityStatus.completed);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Activity marked completed.')),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final activitiesAsync = ref.watch(activitiesProvider);
    final selectedFilter = ref.watch(selectedTypeFilterProvider);
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        'there';

    return Scaffold(
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showCreateActivitySheet(context),
          backgroundColor: c.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child: Icon(Icons.add_rounded, color: c.onPrimary, size: 28),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Greeting ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting,',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: c.textTertiary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppStrings.searchActivities,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(activitiesProvider.notifier).search('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: c.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: c.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide:
                        BorderSide(color: c.primary, width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  ref.read(activitiesProvider.notifier).search(value);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 18),

            // ── Unified stat bar ──
            activitiesAsync.whenOrNull(
                  data: (activities) {
                    final pending = activities
                        .where((a) => a.status == ActivityStatus.pending)
                        .length;
                    final inProgress = activities
                        .where((a) => a.status == ActivityStatus.inProgress)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              _StatCell(
                                count: activities.length,
                                label: 'sessions',
                                accentColor: c.primary,
                              ),
                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: c.divider.withValues(alpha: 0.5),
                                indent: 6,
                                endIndent: 6,
                              ),
                              _StatCell(
                                count: pending,
                                label: 'pending',
                                accentColor: c.warning,
                              ),
                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: c.divider.withValues(alpha: 0.5),
                                indent: 6,
                                endIndent: 6,
                              ),
                              _StatCell(
                                count: inProgress,
                                label: 'active',
                                accentColor: c.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ) ??
                const SizedBox.shrink(),
            const SizedBox(height: 18),

            // ── Editorial text-tab filters ──
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _TabFilter(
                    label: 'All',
                    isSelected: selectedFilter == null,
                    color: c.primary,
                    onTap: () {
                      ref.read(selectedTypeFilterProvider.notifier).state = null;
                      ref.read(activitiesProvider.notifier).filterByType(null);
                    },
                  ),
                  const SizedBox(width: 28),
                  _TabFilter(
                    label: 'Passive',
                    isSelected: selectedFilter == ActivityType.passive,
                    color: c.passive,
                    onTap: () {
                      ref.read(selectedTypeFilterProvider.notifier).state =
                          ActivityType.passive;
                      ref
                          .read(activitiesProvider.notifier)
                          .filterByType(ActivityType.passive);
                    },
                  ),
                  const SizedBox(width: 28),
                  _TabFilter(
                    label: 'Chat',
                    isSelected: selectedFilter == ActivityType.twoway,
                    color: c.chat,
                    onTap: () {
                      ref.read(selectedTypeFilterProvider.notifier).state =
                          ActivityType.twoway;
                      ref
                          .read(activitiesProvider.notifier)
                          .filterByType(ActivityType.twoway);
                    },
                  ),
                  const SizedBox(width: 28),
                  _TabFilter(
                    label: 'Media',
                    isSelected: selectedFilter == ActivityType.media,
                    color: c.media,
                    onTap: () {
                      ref.read(selectedTypeFilterProvider.notifier).state =
                          ActivityType.media;
                      ref
                          .read(activitiesProvider.notifier)
                          .filterByType(ActivityType.media);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Activity list ──
            Expanded(
              child: activitiesAsync.when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SessionTypeIcon(
                            mode: 'passive',
                            color: c.textTertiary.withValues(alpha: 0.3),
                            size: 64,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppStrings.noActivities,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: c.textTertiary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to create your first session',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: c.textTertiary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(activitiesProvider.notifier).refresh(),
                    color: c.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.paddingXXL + 80,
                      ),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return Dismissible(
                          key: ValueKey(activity.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _confirmDeleteActivity(activity);
                            return false;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 28),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(Icons.delete_outline,
                                color: c.error, size: 26),
                          ),
                          child: ActivityCard(
                            activity: activity,
                            onTap: () => _openActivity(activity),
                            onMarkCompleted: () =>
                                _markActivityCompleted(activity),
                            onDelete: () => _confirmDeleteActivity(activity),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: c.primary),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: c.error),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(error.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(activitiesProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Stat Cell (inside unified stat bar) ──────────────────────
// ═══════════════════════════════════════════════════════════════

class _StatCell extends StatelessWidget {
  final int count;
  final String label;
  final Color accentColor;

  const _StatCell({
    required this.count,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: c.textTertiary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Text Tab Filter (editorial underline style) ──────────────
// ═══════════════════════════════════════════════════════════════

class _TabFilter extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TabFilter({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? color : c.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: isSelected ? 18 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Create Activity Sheet ────────────────────────────────────
// ═══════════════════════════════════════════════════════════════

class _CreateActivitySheet extends ConsumerStatefulWidget {
  final void Function(ActivityModel activity) onCreated;
  const _CreateActivitySheet({required this.onCreated});

  @override
  ConsumerState<_CreateActivitySheet> createState() =>
      _CreateActivitySheetState();
}

class _CreateActivitySheetState extends ConsumerState<_CreateActivitySheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  ActivityType _selectedType = ActivityType.passive;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _isCreating = true);
    final repo = ref.read(activityRepositoryProvider);
    final result = await repo.createActivity(
      title: title,
      type: _selectedType,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );
    if (!mounted) return;
    result.when(
      success: (activity) {
        Navigator.of(context).pop();
        widget.onCreated(activity);
      },
      failure: (message, _) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  Color _typeColor(ActivityType t, AppColorScheme c) => switch (t) {
    ActivityType.passive => c.passive,
    ActivityType.twoway => c.chat,
    ActivityType.media => c.media,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: c.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quick Start Session',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700, color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'What are you working on?',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                filled: true, fillColor: c.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Location (optional)',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                filled: true, fillColor: c.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            Text(
              'SESSION TYPE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: c.textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2, fontSize: 10,
              ),
            ),
            const SizedBox(height: 16),
            // ── Type selectors with custom icons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ActivityType.values.map((type) {
                final tc = _typeColor(type, c);
                final isSel = _selectedType == type;
                final label = switch (type) {
                  ActivityType.passive => 'Passive',
                  ActivityType.twoway => 'Chat',
                  ActivityType.media => 'Media',
                };
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel ? tc.withValues(alpha: 0.15) : c.surfaceLight,
                          border: Border.all(
                            color: isSel ? tc : c.divider,
                            width: isSel ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: SessionTypeIcon(mode: type.name, color: isSel ? tc : c.textTertiary, size: 30),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(label, style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                        color: isSel ? tc : c.textSecondary,
                      )),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  elevation: 0,
                ),
                child: _isCreating
                    ? SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onPrimary))
                    : const Text('Start Session',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
