import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/activity_model.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkCompleted;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.onDelete,
    this.onMarkCompleted,
  });

  Color get _typeColor => switch (activity.type) {
    ActivityType.passive => AppColors.passive,
    ActivityType.twoway => AppColors.chat,
    ActivityType.media => AppColors.media,
  };

  IconData get _typeIcon => switch (activity.type) {
    ActivityType.passive => Icons.hearing,
    ActivityType.twoway => Icons.chat_bubble_outline,
    ActivityType.media => Icons.camera_alt_outlined,
  };

  IconData get _statusIcon => switch (activity.status) {
    ActivityStatus.inProgress => Icons.play_circle_filled,
    ActivityStatus.completed => Icons.check_circle,
    ActivityStatus.cancelled => Icons.cancel,
    ActivityStatus.pending => Icons.schedule,
  };

  Color get _statusColor => switch (activity.status) {
    ActivityStatus.inProgress => AppColors.success,
    ActivityStatus.completed => AppColors.info,
    ActivityStatus.cancelled => AppColors.error,
    ActivityStatus.pending => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final isActive = activity.status == ActivityStatus.inProgress;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(color: _typeColor.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Type indicator with glow effect for active
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _typeColor.withValues(alpha: isActive ? 0.4 : 0.1),
                    ),
                  ),
                  child: Icon(_typeIcon, color: _typeColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              activity.type.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _typeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Status indicator
                          Icon(_statusIcon, size: 12, color: _statusColor),
                          const SizedBox(width: 3),
                          Text(
                            activity.status.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: _statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (activity.location != null) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                activity.location!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (activity.status != ActivityStatus.completed &&
                          onMarkCompleted != null) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: onMarkCompleted,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Mark completed',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Schedule & Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (activity.scheduledAt != null)
                      Text(
                        DateFormat('MMM d').format(activity.scheduledAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onDelete != null)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                            color: AppColors.surface,
                            onSelected: (value) {
                              if (value == 'complete') {
                                onMarkCompleted?.call();
                              }
                              if (value == 'delete') {
                                onDelete!();
                              }
                            },
                            itemBuilder: (context) {
                              final items = <PopupMenuEntry<String>>[];

                              if (activity.status != ActivityStatus.completed &&
                                  onMarkCompleted != null) {
                                items.add(
                                  const PopupMenuItem<String>(
                                    value: 'complete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline,
                                            color: AppColors.success),
                                        SizedBox(width: 8),
                                        Text('Mark completed'),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              items.add(
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: AppColors.error),
                                      SizedBox(width: 8),
                                      Text('Delete activity'),
                                    ],
                                  ),
                                ),
                              );

                              return items;
                            },
                          ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: _typeColor,
                            size: 16,
                          ),
                        ),
                      ],
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
