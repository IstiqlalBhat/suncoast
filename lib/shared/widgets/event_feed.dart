import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/models/ai_event_model.dart';
import 'event_feed_row.dart';

class EventFeed extends StatelessWidget {
  final List<AiEventModel> events;
  final ScrollController? scrollController;

  const EventFeed({
    super.key,
    required this.events,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'AI events will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.paddingS),
      itemBuilder: (context, index) {
        return EventFeedRow(event: events[index]);
      },
    );
  }
}
