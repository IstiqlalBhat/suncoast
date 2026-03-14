import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/widgets/session_type_icon.dart';

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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isActive = activity.status == ActivityStatus.inProgress;
    final blendStrength = isActive ? 0.18 : 0.10;

    final typeColor = switch (activity.type) {
      ActivityType.passive => c.passive,
      ActivityType.twoway => c.chat,
      ActivityType.media => c.media,
    };

    final statusColor = switch (activity.status) {
      ActivityStatus.inProgress => c.success,
      ActivityStatus.completed => c.info,
      ActivityStatus.cancelled => c.error,
      ActivityStatus.pending => c.warning,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Color.lerp(c.card, typeColor, blendStrength)!,
            Color.lerp(c.card, typeColor, 0.03)!,
            c.card,
          ],
          stops: const [0.0, 0.25, 0.5],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: isActive
            ? Border.all(color: typeColor.withValues(alpha: 0.2))
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
                SizedBox(
                  width: 32,
                  height: 32,
                  child: SessionTypeIcon(
                    mode: activity.type.name,
                    color: typeColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            activity.type.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: typeColor.withValues(alpha: 0.8),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 3, height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.textTertiary.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activity.status.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (activity.location != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activity.location!,
                                style: TextStyle(fontSize: 10, color: c.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (activity.scheduledAt != null)
                      Text(
                        DateFormat('MMM d').format(activity.scheduledAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11, color: c.textTertiary,
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (onDelete != null)
                      SizedBox(
                        width: 28, height: 28,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz, size: 16,
                            color: c.textTertiary.withValues(alpha: 0.6)),
                          padding: EdgeInsets.zero,
                          color: c.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (value) {
                            if (value == 'complete') onMarkCompleted?.call();
                            if (value == 'delete') onDelete!();
                          },
                          itemBuilder: (context) {
                            final c = context.colors;
                            final items = <PopupMenuEntry<String>>[];
                            if (activity.status != ActivityStatus.completed && onMarkCompleted != null) {
                              items.add(PopupMenuItem<String>(
                                value: 'complete',
                                child: Row(children: [
                                  Icon(Icons.check_circle_outline, color: c.success),
                                  SizedBox(width: 8), Text('Mark completed'),
                                ]),
                              ));
                            }
                            items.add(PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete_outline, color: c.error),
                                SizedBox(width: 8), Text('Delete activity'),
                              ]),
                            ));
                            return items;
                          },
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
