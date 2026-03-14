import 'package:flutter/material.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/models/ai_event_model.dart';
import 'event_feed_row.dart';

class EventFeed extends StatefulWidget {
  final List<AiEventModel> events;
  final ScrollController? scrollController;
  final Future<void> Function(AiEventModel event, Map<String, dynamic> fields)?
      onEditEvent;
  final Future<void> Function(AiEventModel event)? onDeleteEvent;

  const EventFeed({
    super.key,
    required this.events,
    this.scrollController,
    this.onEditEvent,
    this.onDeleteEvent,
  });

  @override
  State<EventFeed> createState() => _EventFeedState();
}

class _EventFeedState extends State<EventFeed> {
  late final ScrollController _internalController;
  final Set<String> _seenEventIds = {};
  final Set<String> _newEventIds = {};

  ScrollController get _controller =>
      widget.scrollController ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = ScrollController();
    // Seed with initial events so they don't all animate on first load.
    for (final e in widget.events) {
      _seenEventIds.add(e.id);
    }
  }

  @override
  void didUpdateWidget(covariant EventFeed oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Identify newly arrived events — mark for animation, then add to seen.
    _newEventIds.clear();
    for (final e in widget.events) {
      if (!_seenEventIds.contains(e.id)) {
        _newEventIds.add(e.id);
        _seenEventIds.add(e.id);
      }
    }

    if (_newEventIds.isNotEmpty) {
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

  Future<bool?> _confirmDelete(BuildContext context) {
    final c = context.colors;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.card,
        title: const Text('Delete Event'),
        content: const Text(
          'This will permanently delete this event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: c.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (widget.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: c.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'AI events will appear here',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: c.textTertiary),
            ),
          ],
        ),
      );
    }

    // Sort by created_at ascending; nulls go last.
    final sorted = List<AiEventModel>.of(widget.events)
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return a.createdAt!.compareTo(b.createdAt!);
      });

    return ListView.separated(
      controller: _controller,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      itemCount: sorted.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.paddingS),
      itemBuilder: (context, index) {
        final event = sorted[index];
        final isNew = _newEventIds.contains(event.id);
        Widget row = EventFeedRow(
          event: event,
          animate: isNew,
          onTap: widget.onEditEvent != null
              ? () => _showEditDialog(event)
              : null,
        );

        if (widget.onDeleteEvent != null) {
          row = Dismissible(
            key: ValueKey(event.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppDimensions.paddingL),
              decoration: BoxDecoration(
                color: c.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(Icons.delete_outline, color: c.error),
            ),
            confirmDismiss: (_) => _confirmDelete(context),
            onDismissed: (_) => widget.onDeleteEvent!(event),
            child: row,
          );
        }

        return row;
      },
    );
  }

  void _showEditDialog(AiEventModel event) {
    final contentController = TextEditingController(text: event.content);
    String? selectedStatus =
        event.type == AiEventType.action ? event.status.name : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.colors.card,
          title: const Text('Edit Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
              ),
              if (event.type == AiEventType.action) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: 'skipped',
                      child: Text('Skipped'),
                    ),
                    DropdownMenuItem(
                      value: 'failed',
                      child: Text('Failed'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedStatus = value),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final fields = <String, dynamic>{
                  'content': contentController.text,
                };
                if (selectedStatus != null) {
                  fields['status'] = selectedStatus;
                }
                widget.onEditEvent!(event, fields);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    // Dispose controller when dialog closes
    contentController.dispose;
  }
}
