import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/models/ai_event_model.dart';

class EventFeedRow extends StatelessWidget {
  final AiEventModel event;
  final VoidCallback? onTap;

  const EventFeedRow({super.key, required this.event, this.onTap});

  Color get _eventColor => switch (event.type) {
    AiEventType.observation => AppColors.observation,
    AiEventType.lookup => AppColors.lookup,
    AiEventType.action => AppColors.action,
  };

  IconData get _eventIcon => switch (event.type) {
    AiEventType.observation => Icons.visibility,
    AiEventType.lookup => Icons.search,
    AiEventType.action => Icons.bolt,
  };

  String get _eventLabel => switch (event.type) {
    AiEventType.observation => 'Observation',
    AiEventType.lookup => 'Lookup',
    AiEventType.action => 'Action',
  };

  Color get _backgroundColor => switch (event.type) {
    AiEventType.observation => AppColors.card,
    AiEventType.lookup => AppColors.lookup.withValues(alpha: 0.08),
    AiEventType.action => AppColors.action.withValues(alpha: 0.12),
  };

  Color get _statusColor => switch (event.status) {
    AiEventStatus.pending => AppColors.warning,
    AiEventStatus.failed => AppColors.error,
    AiEventStatus.skipped => AppColors.textSecondary,
    AiEventStatus.completed => AppColors.success,
  };

  String? get _timestamp => event.createdAt == null
      ? null
      : DateFormat.Hm().format(event.createdAt!.toLocal());

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border(left: BorderSide(color: _eventColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_eventIcon, size: 16, color: _eventColor),
              const SizedBox(width: 6),
              Text(
                _eventLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _eventColor,
                  letterSpacing: 0.5,
                ),
              ),
              if (_timestamp != null) ...[
                const SizedBox(width: 8),
                Text(
                  _timestamp!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              if (event.type == AiEventType.action) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    switch (event.status) {
                      AiEventStatus.pending => 'Pending',
                      AiEventStatus.failed => 'Failed',
                      AiEventStatus.skipped => 'Skipped',
                      AiEventStatus.completed => 'Done',
                    },
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (event.confidence != null)
                Text(
                  '${(event.confidence! * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
          if (event.externalRecordUrl != null ||
              event.actionLabel != null ||
              event.requiresConfirmation) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (event.actionLabel != null)
                  _MetaPill(label: event.actionLabel!, color: _eventColor),
                if (event.requiresConfirmation)
                  const _MetaPill(
                    label: 'Needs confirmation',
                    color: AppColors.warning,
                  ),
                if (event.externalRecordUrl != null)
                  const _MetaPill(
                    label: 'Linked record',
                    color: AppColors.info,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    final animated =
        child.animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: animated,
      );
    }

    return animated;
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
