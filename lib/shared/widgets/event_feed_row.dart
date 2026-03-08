import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/models/ai_event_model.dart';

class EventFeedRow extends StatelessWidget {
  final AiEventModel event;

  const EventFeedRow({super.key, required this.event});

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border(
          left: BorderSide(color: _eventColor, width: 3),
        ),
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
              const Spacer(),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}
