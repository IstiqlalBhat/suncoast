import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/providers/auth_providers.dart';
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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider);
    final selectedFilter = ref.watch(selectedTypeFilterProvider);
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        'there';

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateActivitySheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (value) {
                  ref.read(activitiesProvider.notifier).search(value);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),

            // Type filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                ),
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: selectedFilter == null,
                    color: AppColors.primary,
                    onTap: () {
                      ref.read(selectedTypeFilterProvider.notifier).state = null;
                      ref.read(activitiesProvider.notifier).filterByType(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Passive',
                    icon: Icons.hearing,
                    isSelected: selectedFilter == ActivityType.passive,
                    color: AppColors.passive,
                    onTap: () {
                      ref.read(selectedTypeFilterProvider.notifier).state =
                          ActivityType.passive;
                      ref
                          .read(activitiesProvider.notifier)
                          .filterByType(ActivityType.passive);
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Chat',
                    icon: Icons.chat_bubble_outline,
                    isSelected: selectedFilter == ActivityType.twoway,
                    color: AppColors.chat,
                    onTap: () {
                      ref.read(selectedTypeFilterProvider.notifier).state =
                          ActivityType.twoway;
                      ref
                          .read(activitiesProvider.notifier)
                          .filterByType(ActivityType.twoway);
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Media',
                    icon: Icons.camera_alt_outlined,
                    isSelected: selectedFilter == ActivityType.media,
                    color: AppColors.media,
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

            // Stats row
            activitiesAsync.whenOrNull(
              data: (activities) {
                final pending = activities.where((a) => a.status == ActivityStatus.pending).length;
                final inProgress = activities.where((a) => a.status == ActivityStatus.inProgress).length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      _StatBadge(
                        count: activities.length,
                        label: 'Total',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        count: pending,
                        label: 'Pending',
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        count: inProgress,
                        label: 'Active',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                );
              },
            ) ?? const SizedBox.shrink(),
            const SizedBox(height: 4),

            // Activity list
            Expanded(
              child: activitiesAsync.when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: AppColors.textTertiary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          Text(
                            AppStrings.noActivities,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(activitiesProvider.notifier).refresh(),
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.paddingXXL + 80,
                      ),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return ActivityCard(
                          activity: activity,
                          onTap: () {
                            final route = activity.type.routeSegment;
                            context.push('/session/${activity.id}/$route');
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? color : AppColors.textTertiary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Quick Start Session',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 20),

            // Title field
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'What are you working on?',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Location field
            TextField(
              controller: _locationController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Location (optional)',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),

            // Session type selector
            Text(
              'Session Type',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _TypeOption(
                  icon: Icons.hearing,
                  label: 'Passive',
                  color: AppColors.passive,
                  isSelected: _selectedType == ActivityType.passive,
                  onTap: () =>
                      setState(() => _selectedType = ActivityType.passive),
                ),
                const SizedBox(width: 10),
                _TypeOption(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  color: AppColors.chat,
                  isSelected: _selectedType == ActivityType.twoway,
                  onTap: () =>
                      setState(() => _selectedType = ActivityType.twoway),
                ),
                const SizedBox(width: 10),
                _TypeOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Media',
                  color: AppColors.media,
                  isSelected: _selectedType == ActivityType.media,
                  onTap: () =>
                      setState(() => _selectedType = ActivityType.media),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Start Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textTertiary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
