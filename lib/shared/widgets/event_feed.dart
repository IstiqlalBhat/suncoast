import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/models/ai_event_model.dart';
import 'event_feed_row.dart';

class EventFeed extends StatefulWidget {
  final List<AiEventModel> events;
  final ScrollController? scrollController;

  const EventFeed({super.key, required this.events, this.scrollController});

  @override
  State<EventFeed> createState() => _EventFeedState();
}

class _EventFeedState extends State<EventFeed> {
  late final ScrollController _internalController;

  ScrollController get _controller =>
      widget.scrollController ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant EventFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events.length > oldWidget.events.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _controller,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      itemCount: widget.events.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.paddingS),
      itemBuilder: (context, index) {
        return EventFeedRow(event: widget.events[index]);
      },
    );
  }
}
