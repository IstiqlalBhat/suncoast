import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/models/ai_event_model.dart';

class EventFeedRow extends StatelessWidget {
  final AiEventModel event;
  final VoidCallback? onTap;
  final bool animate;

  const EventFeedRow({
    super.key,
    required this.event,
    this.onTap,
    this.animate = true,
  });

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

  String? get _timestamp => event.createdAt == null
      ? null
      : DateFormat.Hm().format(event.createdAt!.toLocal());

  Color _eventColor(AppColorScheme c) => switch (event.type) {
    AiEventType.observation => c.observation,
    AiEventType.lookup => c.lookup,
    AiEventType.action => c.action,
  };

  Color _backgroundColor(AppColorScheme c) => switch (event.type) {
    AiEventType.observation => c.card,
    AiEventType.lookup => c.lookup.withValues(alpha: 0.08),
    AiEventType.action => c.action.withValues(alpha: 0.12),
  };

  Color _statusColor(AppColorScheme c) => switch (event.status) {
    AiEventStatus.pending => c.warning,
    AiEventStatus.failed => c.error,
    AiEventStatus.skipped => c.textSecondary,
    AiEventStatus.completed => c.success,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final eventColor = _eventColor(c);
    final backgroundColor = _backgroundColor(c);
    final statusColor = _statusColor(c);

    final child = Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border(left: BorderSide(color: eventColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_eventIcon, size: 16, color: eventColor),
              const SizedBox(width: 6),
              Text(
                _eventLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: eventColor,
                  letterSpacing: 0.5,
                ),
              ),
              if (_timestamp != null) ...[
                const SizedBox(width: 8),
                Text(
                  _timestamp!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: c.textSecondary,
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
                    color: statusColor.withValues(alpha: 0.15),
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
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textPrimary),
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
                  _MetaPill(label: event.actionLabel!, color: eventColor),
                if (event.requiresConfirmation)
                  _MetaPill(
                    label: 'Needs confirmation',
                    color: c.warning,
                  ),
                if (event.externalRecordUrl != null)
                  _MetaPill(
                    label: 'Linked record',
                    color: c.info,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    final visual = animate
        ? child.animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0)
        : child;

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: visual,
      );
    }

    return visual;
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
