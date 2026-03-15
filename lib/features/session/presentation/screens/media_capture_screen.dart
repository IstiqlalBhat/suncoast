import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/session_model.dart';
import '../../../../shared/widgets/session_app_bar.dart';
import '../models/conversation_entry.dart';
import '../providers/session_provider.dart';

class MediaCaptureScreen extends ConsumerStatefulWidget {
  final String activityId;

  const MediaCaptureScreen({super.key, required this.activityId});

  @override
  ConsumerState<MediaCaptureScreen> createState() => _MediaCaptureScreenState();
}

class _MediaCaptureScreenState extends ConsumerState<MediaCaptureScreen> {
  bool _isEnding = false;
  bool _isAttachmentPanelExpanded = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(activeSessionProvider.notifier)
          .startSession(activityId: widget.activityId, mode: SessionMode.media);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sessionState = ref.watch(activeSessionProvider);
    final timerText = ref.watch(sessionTimerProvider);

    // Scroll to bottom when new entries arrive
    ref.listen(activeSessionProvider, (prev, next) {
      if ((prev?.conversationEntries.length ?? 0) <
          next.conversationEntries.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: c.background,
      extendBodyBehindAppBar: true,
      appBar: SessionAppBar(
        title: sessionState.activityTitle.isNotEmpty
            ? sessionState.activityTitle
            : 'Media Assistant',
        subtitle: timerText,
        accentColor: c.media,
        onEndSession: () => _endSession(context),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Error banner
                if (sessionState.error != null)
                  _ErrorBanner(message: sessionState.error!),

                // Conversation view
                Expanded(
                  child: _ConversationView(
                    entries: sessionState.conversationEntries,
                    scrollController: _scrollController,
                    voiceStatus: sessionState.voiceStatus,
                  ),
                ),

                if (sessionState.mediaItems.isNotEmpty)
                  _AttachmentPanel(
                    items: sessionState.mediaItems,
                    isExpanded: _isAttachmentPanelExpanded,
                    onToggle: () => setState(
                      () => _isAttachmentPanelExpanded =
                          !_isAttachmentPanelExpanded,
                    ),
                  ),

                // Voice state indicator
                _VoiceStateIndicator(
                  voiceStatus: sessionState.voiceStatus,
                  audioLevel: sessionState.audioLevel,
                  conversationState: sessionState.conversationState,
                ),

                // Tool request card (when AI asks for media)
                if (sessionState.activeToolRequest != null)
                  _ToolRequestCard(
                    request: sessionState.activeToolRequest!,
                    onAddPhoto: () => _handleToolRequestPhoto(),
                    onAddPdf: () => _handleToolRequestPdf(),
                    onDismiss: () => ref
                        .read(activeSessionProvider.notifier)
                        .dismissToolRequest(),
                  ),

                // Bottom controls
                _BottomControls(
                  isMuted: sessionState.isMuted,
                  isProcessing: sessionState.isProcessing,
                  onToggleMute: () =>
                      ref.read(activeSessionProvider.notifier).toggleMute(),
                  onAddMedia: _handleCapture,
                  onEnd: () => _endSession(context),
                ),
              ],
            ),
          ),
          if (_isEnding)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: c.media),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      'Ending session...',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleToolRequestPhoto() async {
    final c = context.colors;
    final request = await showModalBottomSheet<MediaCaptureRequest>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => const _PhotoPickerSheet(),
    );
    if (request == null || !mounted) return;

    await ref.read(activeSessionProvider.notifier).captureMedia(request);
  }

  Future<void> _handleToolRequestPdf() async {
    await ref
        .read(activeSessionProvider.notifier)
        .captureMedia(
          const MediaCaptureRequest(
            captureType: 'pdf',
            source: MediaCaptureSource.filePicker,
          ),
        );
  }

  Future<void> _handleCapture() async {
    final c = context.colors;
    final request = await showModalBottomSheet<MediaCaptureRequest>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => const _CaptureActionSheet(),
    );
    if (request == null || !mounted) return;
    await ref.read(activeSessionProvider.notifier).captureMedia(request);
  }

  Future<void> _endSession(BuildContext context) async {
    if (_isEnding) return;
    setState(() => _isEnding = true);
    final sessionId = await ref
        .read(activeSessionProvider.notifier)
        .endSession();
    if (sessionId != null && context.mounted) {
      context.go('/session/${widget.activityId}/summary?sessionId=$sessionId');
    } else if (mounted) {
      setState(() => _isEnding = false);
    }
  }
}

// ── Conversation View ────────────────────────────────────────────

class _ConversationView extends StatelessWidget {
  final List<ConversationEntry> entries;
  final ScrollController scrollController;
  final RealtimeVoiceStatus voiceStatus;

  const _ConversationView({
    required this.entries,
    required this.scrollController,
    required this.voiceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                voiceStatus == RealtimeVoiceStatus.connecting
                    ? Icons.wifi_calling_3
                    : voiceStatus == RealtimeVoiceStatus.disconnected
                    ? Icons.mic_off_outlined
                    : Icons.graphic_eq_rounded,
                color: c.media.withValues(alpha: 0.5),
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                voiceStatus == RealtimeVoiceStatus.connecting
                    ? 'Connecting to voice assistant...'
                    : voiceStatus == RealtimeVoiceStatus.disconnected
                    ? 'Starting session...'
                    : 'Voice assistant is ready.\nSpeak or add media to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingS,
        AppDimensions.paddingM,
        AppDimensions.paddingS,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ConversationBubble(entry: entry),
        );
      },
    );
  }
}

// ── Attachment Panel ─────────────────────────────────────────────

class _AttachmentPanel extends StatelessWidget {
  final List<SessionMediaItem> items;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AttachmentPanel({
    required this.items,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visibleItems = items.reversed.toList(growable: false);
    final displayStates = <String, _AttachmentDisplayState>{
      for (final item in visibleItems)
        item.attachment.id: _AttachmentDisplayState.fromItem(item, c),
    };

    SessionMediaItem? featuredItem;
    for (final item in visibleItems) {
      final code = displayStates[item.attachment.id]!.code;
      if (code == 'failed' || code == 'uploading' || code == 'processing') {
        featuredItem = item;
        break;
      }
    }
    featuredItem ??= visibleItems.isEmpty ? null : visibleItems.first;

    final recentItems = [
      for (final item in visibleItems)
        if (!identical(item, featuredItem)) item,
    ].take(2).toList(growable: false);

    final inFlightCount = visibleItems.where((item) {
      final code = displayStates[item.attachment.id]!.code;
      return code == 'uploading' || code == 'processing';
    }).length;
    final readyCount = visibleItems.where((item) {
      final code = displayStates[item.attachment.id]!.code;
      return code == 'analyzed' || code == 'uploaded';
    }).length;
    final failedCount = visibleItems.where((item) {
      return displayStates[item.attachment.id]!.code == 'failed';
    }).length;
    final collapsedSummary = _buildCollapsedAttachmentSummary(
      visibleItems: visibleItems,
      displayStates: displayStates,
      inFlightCount: inFlightCount,
      readyCount: readyCount,
      failedCount: failedCount,
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppDimensions.paddingM,
          0,
          AppDimensions.paddingM,
          AppDimensions.paddingS,
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.card, c.surface.withValues(alpha: 0.72)],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: c.media.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c.media.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.attach_file_rounded,
                        color: c.media,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachment Status',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isExpanded
                                ? 'Tap to hide this panel when you need the session view.'
                                : collapsedSummary,
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.media.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${visibleItems.length}',
                        style: TextStyle(
                          color: c.media,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              if (visibleItems.isEmpty)
                _AttachmentEmptyState()
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 310),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (inFlightCount > 0)
                              _AttachmentSummaryChip(
                                color: c.media,
                                icon: Icons.autorenew_rounded,
                                text: '$inFlightCount active',
                              ),
                            if (readyCount > 0)
                              _AttachmentSummaryChip(
                                color: c.success,
                                icon: Icons.check_circle_outline_rounded,
                                text: '$readyCount ready',
                              ),
                            if (failedCount > 0)
                              _AttachmentSummaryChip(
                                color: c.error,
                                icon: Icons.error_outline_rounded,
                                text: '$failedCount failed',
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FeaturedAttachmentCard(
                          item: featuredItem!,
                          displayState:
                              displayStates[featuredItem.attachment.id]!,
                        ),
                        if (recentItems.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                'Recent',
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${visibleItems.length - 1} other ${visibleItems.length - 1 == 1 ? 'file' : 'files'}',
                                style: TextStyle(
                                  color: c.textTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...recentItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _AttachmentHistoryRow(
                                item: item,
                                displayState:
                                    displayStates[item.attachment.id]!,
                              ),
                            ),
                          ),
                          if (visibleItems.length > recentItems.length + 1)
                            Text(
                              '+${visibleItems.length - recentItems.length - 1} older attachments',
                              style: TextStyle(
                                color: c.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _buildCollapsedAttachmentSummary({
  required List<SessionMediaItem> visibleItems,
  required Map<String, _AttachmentDisplayState> displayStates,
  required int inFlightCount,
  required int readyCount,
  required int failedCount,
}) {
  if (visibleItems.isEmpty) {
    return 'No attachments yet.';
  }

  if (failedCount > 0) {
    return '$failedCount failed, $inFlightCount active, $readyCount ready';
  }

  if (inFlightCount > 0) {
    return '$inFlightCount active, $readyCount ready';
  }

  final latest = visibleItems.first;
  final latestState = displayStates[latest.attachment.id];
  final latestName = _attachmentDisplayName(latest);
  if (latestState == null) {
    return latestName;
  }

  return '$latestName • ${latestState.label}';
}

class _AttachmentEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: c.divider.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.media.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.upload_file_rounded, color: c.media, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add a photo or PDF and its upload state will stay visible here until it is ready or fails.',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentSummaryChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _AttachmentSummaryChip({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedAttachmentCard extends StatelessWidget {
  final SessionMediaItem item;
  final _AttachmentDisplayState displayState;

  const _FeaturedAttachmentCard({
    required this.item,
    required this.displayState,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final detailText = _attachmentDetailText(item, displayState);
    final metaLine = _attachmentMetaLine(item, displayState);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [displayState.color.withValues(alpha: 0.16), c.card],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: displayState.color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _attachmentEyebrow(displayState),
                style: TextStyle(
                  color: displayState.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              _AttachmentStatusChip(displayState: displayState),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AttachmentPreview(
                item: item,
                displayState: displayState,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _attachmentDisplayName(item),
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metaLine,
                      style: TextStyle(
                        color: c.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _attachmentStatusMessage(item, displayState),
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AttachmentStagePill(
                  label: 'Upload',
                  state: _uploadStageFor(displayState),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AttachmentStagePill(
                  label: 'AI result',
                  state: _analysisStageFor(displayState),
                ),
              ),
            ],
          ),
          if (displayState.showProgress) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: LinearProgressIndicator(
                minHeight: 6,
                color: displayState.color,
                backgroundColor: displayState.color.withValues(alpha: 0.14),
              ),
            ),
          ],
          if (detailText != null) ...[
            const SizedBox(height: 12),
            _AttachmentDetailBox(
              title: displayState.code == 'failed' ? 'Issue' : 'AI output',
              text: detailText,
              accentColor: displayState.color,
              emphasizeError: displayState.code == 'failed',
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentHistoryRow extends StatelessWidget {
  final SessionMediaItem item;
  final _AttachmentDisplayState displayState;

  const _AttachmentHistoryRow({required this.item, required this.displayState});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: displayState.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: displayState.color,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
          const SizedBox(width: 10),
          _AttachmentPreview(item: item, displayState: displayState, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _attachmentDisplayName(item),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _attachmentMetaLine(item, displayState),
                  style: TextStyle(color: c.textTertiary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _AttachmentStatusChip(displayState: displayState),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final SessionMediaItem item;
  final _AttachmentDisplayState displayState;
  final double size;

  const _AttachmentPreview({
    required this.item,
    required this.displayState,
    this.size = 58,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = item.attachment.mimeType?.startsWith('image/') ?? false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: displayState.color.withValues(alpha: 0.12),
        child: isImage
            ? _buildImagePreview()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.attachment.mimeType == 'application/pdf'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.insert_drive_file_outlined,
                    color: displayState.color,
                    size: size * 0.38,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.attachment.mimeType == 'application/pdf'
                        ? 'PDF'
                        : 'FILE',
                    style: TextStyle(
                      color: displayState.color,
                      fontSize: size < 50 ? 8 : 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (item.previewBytes != null) {
      return Image.memory(item.previewBytes!, fit: BoxFit.cover);
    }

    if (item.signedUrl != null && item.signedUrl!.isNotEmpty) {
      return Image.network(
        item.signedUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildImageFallback(),
      );
    }

    return _buildImageFallback();
  }

  Widget _buildImageFallback() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: displayState.color,
        size: size * 0.34,
      ),
    );
  }
}

class _AttachmentDetailBox extends StatelessWidget {
  final String title;
  final String text;
  final Color accentColor;
  final bool emphasizeError;

  const _AttachmentDetailBox({
    required this.title,
    required this.text,
    required this.accentColor,
    required this.emphasizeError,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: emphasizeError ? 0.08 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              color: emphasizeError ? c.error : c.textPrimary,
              fontSize: 12,
              height: 1.35,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AttachmentStagePill extends StatelessWidget {
  final String label;
  final _AttachmentStageState state;

  const _AttachmentStagePill({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visual = _AttachmentStageVisual.fromState(state, c);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: visual.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(visual.icon, color: visual.color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  visual.label,
                  style: TextStyle(
                    color: visual.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentStatusChip extends StatelessWidget {
  final _AttachmentDisplayState displayState;

  const _AttachmentStatusChip({required this.displayState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: displayState.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(displayState.icon, color: displayState.color, size: 11),
          const SizedBox(width: 4),
          Text(
            displayState.shortLabel,
            style: TextStyle(
              color: displayState.color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _AttachmentStageState { pending, active, done, failed, skipped }

class _AttachmentStageVisual {
  final String label;
  final Color color;
  final IconData icon;

  const _AttachmentStageVisual({
    required this.label,
    required this.color,
    required this.icon,
  });

  factory _AttachmentStageVisual.fromState(
    _AttachmentStageState state,
    AppColorScheme c,
  ) {
    return switch (state) {
      _AttachmentStageState.pending => _AttachmentStageVisual(
        label: 'Waiting',
        color: c.textTertiary,
        icon: Icons.schedule_outlined,
      ),
      _AttachmentStageState.active => _AttachmentStageVisual(
        label: 'Working',
        color: c.media,
        icon: Icons.autorenew_rounded,
      ),
      _AttachmentStageState.done => _AttachmentStageVisual(
        label: 'Done',
        color: c.success,
        icon: Icons.check_circle_outline_rounded,
      ),
      _AttachmentStageState.failed => _AttachmentStageVisual(
        label: 'Failed',
        color: c.error,
        icon: Icons.error_outline_rounded,
      ),
      _AttachmentStageState.skipped => _AttachmentStageVisual(
        label: 'Skipped',
        color: c.info,
        icon: Icons.skip_next_rounded,
      ),
    };
  }
}

class _AttachmentDisplayState {
  final String code;
  final String label;
  final String shortLabel;
  final Color color;
  final IconData icon;
  final bool showProgress;

  const _AttachmentDisplayState({
    required this.code,
    required this.label,
    required this.shortLabel,
    required this.color,
    required this.icon,
    required this.showProgress,
  });

  factory _AttachmentDisplayState.fromItem(
    SessionMediaItem item,
    AppColorScheme c,
  ) {
    final status = item.attachment.analysisStatus.trim().toLowerCase();

    if (status == 'uploading') {
      return _AttachmentDisplayState(
        code: 'uploading',
        label: 'Uploading',
        shortLabel: 'Uploading',
        color: c.info,
        icon: Icons.upload_rounded,
        showProgress: true,
      );
    }

    if (item.isAnalyzing || status == 'processing' || status == 'pending') {
      return _AttachmentDisplayState(
        code: 'processing',
        label: 'Analyzing',
        shortLabel: 'Analyzing',
        color: c.media,
        icon: Icons.autorenew_rounded,
        showProgress: true,
      );
    }

    if (status == 'completed') {
      return _AttachmentDisplayState(
        code: 'analyzed',
        label: 'Analysis Ready',
        shortLabel: 'Ready',
        color: c.success,
        icon: Icons.check_circle_outline_rounded,
        showProgress: false,
      );
    }

    if (status == 'failed') {
      return _AttachmentDisplayState(
        code: 'failed',
        label: 'Processing Failed',
        shortLabel: 'Failed',
        color: c.error,
        icon: Icons.error_outline_rounded,
        showProgress: false,
      );
    }

    if (status == 'skipped') {
      return _AttachmentDisplayState(
        code: 'uploaded',
        label: 'Uploaded',
        shortLabel: 'Uploaded',
        color: c.info,
        icon: Icons.cloud_done_outlined,
        showProgress: false,
      );
    }

    return _AttachmentDisplayState(
      code: 'pending',
      label: 'Pending',
      shortLabel: 'Pending',
      color: c.textSecondary,
      icon: Icons.schedule_outlined,
      showProgress: false,
    );
  }
}

String _attachmentDisplayName(SessionMediaItem item) {
  final metadataName = item.attachment.metadata['original_name']?.toString();
  if (metadataName != null && metadataName.trim().isNotEmpty) {
    return metadataName.trim();
  }

  final localPath = item.localPath;
  if (localPath != null && localPath.trim().isNotEmpty) {
    return localPath.split('/').last;
  }

  final storagePath = item.attachment.storagePath.trim();
  if (storagePath.isNotEmpty) {
    return storagePath.split('/').last;
  }

  return item.attachment.mimeType == 'application/pdf'
      ? 'PDF document'
      : 'Attachment';
}

String _attachmentKindLabel(SessionMediaItem item) {
  final mimeType = item.attachment.mimeType ?? '';
  if (mimeType == 'application/pdf') {
    return 'PDF';
  }
  if (mimeType.startsWith('image/')) {
    return 'Image';
  }
  return 'File';
}

String? _attachmentFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) {
    return null;
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _attachmentMetaLine(
  SessionMediaItem item,
  _AttachmentDisplayState displayState,
) {
  final fileSize = _attachmentFileSize(item.attachment.fileSizeBytes);
  return [
    _attachmentKindLabel(item),
    ...(fileSize == null ? const <String>[] : [fileSize]),
    displayState.label,
  ].join(' • ');
}

String _attachmentEyebrow(_AttachmentDisplayState displayState) {
  return switch (displayState.code) {
    'uploading' => 'UPLOADING NOW',
    'processing' => 'ANALYZING NOW',
    'analyzed' => 'ANALYSIS COMPLETE',
    'failed' => 'ACTION NEEDED',
    'uploaded' => 'UPLOADED',
    _ => 'QUEUED',
  };
}

String _attachmentStatusMessage(
  SessionMediaItem item,
  _AttachmentDisplayState displayState,
) {
  final kind = _attachmentKindLabel(item).toLowerCase();
  return switch (displayState.code) {
    'uploading' => 'Sending this $kind to the session.',
    'processing' => 'Upload finished. AI is reading this $kind now.',
    'analyzed' => 'This $kind passed processing and its output is ready below.',
    'failed' =>
      'This $kind did not finish processing. Upload it again to retry.',
    'uploaded' => 'This $kind was attached, but no AI output was generated.',
    _ => 'This $kind is waiting to start processing.',
  };
}

String? _attachmentAnalysisText(SessionMediaItem item) {
  final analysis = (item.analysis ?? item.attachment.aiAnalysis ?? '').trim();
  return analysis.isEmpty ? null : analysis;
}

String? _attachmentDetailText(
  SessionMediaItem item,
  _AttachmentDisplayState displayState,
) {
  final analysis = _attachmentAnalysisText(item);
  if (analysis != null) {
    return analysis;
  }
  if (displayState.code == 'failed') {
    return item.attachment.mimeType == 'application/pdf'
        ? 'The PDF could not be processed. Try re-uploading it, or use a smaller text-based PDF.'
        : 'The image could not be processed. Try re-uploading it or use a clearer image.';
  }
  if (displayState.code == 'uploaded') {
    return 'The file is attached successfully, but the AI service did not return analysis for it.';
  }
  return null;
}

_AttachmentStageState _uploadStageFor(_AttachmentDisplayState displayState) {
  return switch (displayState.code) {
    'uploading' => _AttachmentStageState.active,
    'processing' ||
    'analyzed' ||
    'failed' ||
    'uploaded' => _AttachmentStageState.done,
    _ => _AttachmentStageState.pending,
  };
}

_AttachmentStageState _analysisStageFor(_AttachmentDisplayState displayState) {
  return switch (displayState.code) {
    'processing' => _AttachmentStageState.active,
    'analyzed' => _AttachmentStageState.done,
    'failed' => _AttachmentStageState.failed,
    'uploaded' => _AttachmentStageState.skipped,
    _ => _AttachmentStageState.pending,
  };
}

// ── Conversation Bubble ──────────────────────────────────────────

class _ConversationBubble extends StatelessWidget {
  final ConversationEntry entry;

  const _ConversationBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isUser = entry.role == ConversationRole.user;
    final isToolRequest = entry.type == ConversationEntryType.toolRequest;
    final isMedia = entry.type == ConversationEntryType.mediaAttachment;

    if (isToolRequest) {
      return _buildToolRequestBubble(context, c);
    }

    if (isMedia) {
      return _buildMediaBubble(context, c, isUser);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? c.surface : c.media.withValues(alpha: 0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimensions.radiusM),
            topRight: const Radius.circular(AppDimensions.radiusM),
            bottomLeft: Radius.circular(isUser ? AppDimensions.radiusM : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppDimensions.radiusM),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.text,
              style: TextStyle(color: c.textPrimary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(entry.timestamp),
              style: TextStyle(color: c.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolRequestBubble(BuildContext context, AppColorScheme c) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.media.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: c.media.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            entry.toolRequest?.toolName == 'request_pdf'
                ? Icons.picture_as_pdf_outlined
                : Icons.add_a_photo_outlined,
            color: c.media,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBubble(
    BuildContext context,
    AppColorScheme c,
    bool isUser,
  ) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: c.media.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              entry.text.toLowerCase().contains('pdf')
                  ? Icons.picture_as_pdf_outlined
                  : Icons.photo_outlined,
              color: c.media,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              entry.text,
              style: TextStyle(color: c.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// ── Voice State Indicator ────────────────────────────────────────

class _VoiceStateIndicator extends StatelessWidget {
  final RealtimeVoiceStatus voiceStatus;
  final double audioLevel;
  final SessionConversationState conversationState;

  const _VoiceStateIndicator({
    required this.voiceStatus,
    required this.audioLevel,
    required this.conversationState,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (voiceStatus == RealtimeVoiceStatus.disconnected) {
      return const SizedBox(height: 16);
    }

    final isListening =
        voiceStatus == RealtimeVoiceStatus.connected ||
        voiceStatus == RealtimeVoiceStatus.listening;
    final isSpeaking =
        voiceStatus == RealtimeVoiceStatus.aiSpeaking ||
        conversationState == SessionConversationState.aiSpeaking;
    final isConnecting = voiceStatus == RealtimeVoiceStatus.connecting;

    final label = isConnecting
        ? 'Connecting...'
        : isSpeaking
        ? 'AI Speaking'
        : conversationState == SessionConversationState.processing
        ? 'Processing...'
        : 'Listening';

    final orbSize = 48.0 + (isListening ? audioLevel * 16.0 : 0.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow ring
                if (!isConnecting)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: orbSize + 20,
                    height: orbSize + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.media.withValues(
                            alpha: isSpeaking ? 0.3 : 0.15,
                          ),
                          blurRadius: isSpeaking ? 24 : 12,
                          spreadRadius: isSpeaking ? 4 : 1,
                        ),
                      ],
                    ),
                  ),
                // Main orb
                AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: orbSize,
                      height: orbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            c.media.withValues(alpha: 0.7),
                            c.media.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: isConnecting
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              isSpeaking ? Icons.graphic_eq_rounded : Icons.mic,
                              color: Colors.white,
                              size: 22,
                            ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .then(delay: Duration.zero)
                    .shimmer(
                      duration: isSpeaking
                          ? const Duration(milliseconds: 1200)
                          : const Duration(milliseconds: 2400),
                      color: c.media.withValues(alpha: 0.15),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: c.media.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tool Request Card ────────────────────────────────────────────

class _ToolRequestCard extends StatelessWidget {
  final ToolCallRequest request;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddPdf;
  final VoidCallback onDismiss;

  const _ToolRequestCard({
    required this.request,
    required this.onAddPhoto,
    required this.onAddPdf,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isImageRequest = request.toolName == 'request_image';

    return Container(
          margin: const EdgeInsets.fromLTRB(
            AppDimensions.paddingM,
            0,
            AppDimensions.paddingM,
            AppDimensions.paddingS,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: c.media.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isImageRequest
                        ? Icons.add_a_photo_outlined
                        : Icons.picture_as_pdf_outlined,
                    color: c.media,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      request.reason.isNotEmpty
                          ? request.reason
                          : isImageRequest
                          ? 'I need a photo to help you.'
                          : 'I need a PDF document.',
                      style: TextStyle(color: c.textPrimary, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isImageRequest ? onAddPhoto : onAddPdf,
                      icon: Icon(
                        isImageRequest
                            ? Icons.camera_alt_outlined
                            : Icons.upload_file_outlined,
                        size: 16,
                      ),
                      label: Text(isImageRequest ? 'Add Photo' : 'Add PDF'),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.media,
                        foregroundColor: c.background,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      side: BorderSide(color: c.divider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: 0.2, end: 0);
  }
}

// ── Error Banner ─────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingS,
        AppDimensions.paddingM,
        0,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: c.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: c.error.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Controls ──────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final bool isMuted;
  final bool isProcessing;
  final VoidCallback onToggleMute;
  final VoidCallback onAddMedia;
  final VoidCallback onEnd;

  const _BottomControls({
    required this.isMuted,
    required this.isProcessing,
    required this.onToggleMute,
    required this.onAddMedia,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingL,
            AppDimensions.paddingM,
            AppDimensions.paddingL,
            AppDimensions.paddingS,
          ),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(color: c.divider.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: isMuted ? Icons.mic_off_outlined : Icons.mic_none,
                label: isMuted ? 'Unmute' : 'Mute',
                color: isMuted ? c.error : c.media,
                onTap: onToggleMute,
              ),
              _ControlButton(
                icon: Icons.add_photo_alternate_outlined,
                label: 'Add Media',
                color: c.media,
                onTap: isProcessing ? null : onAddMedia,
                isLarge: true,
              ),
              _ControlButton(
                icon: Icons.stop_circle_outlined,
                label: 'End',
                color: c.error,
                onTap: onEnd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLarge;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = isLarge ? 56.0 : 48.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: onTap == null ? 0.06 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: onTap == null ? 0.1 : 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: onTap == null ? color.withValues(alpha: 0.4) : color,
              size: isLarge ? 26 : 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: onTap == null ? c.textTertiary : c.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Capture Action Sheet (3 options) ─────────────────────────────

class _CaptureActionSheet extends StatelessWidget {
  const _CaptureActionSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingM,
          10,
          AppDimensions.paddingM,
          AppDimensions.paddingM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add media',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Share a photo or document with the voice assistant.',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const _CaptureActionTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take photo',
              subtitle: 'Open the camera to capture an image.',
              request: MediaCaptureRequest(
                captureType: 'photo',
                source: MediaCaptureSource.camera,
              ),
            ),
            const SizedBox(height: 8),
            const _CaptureActionTile(
              icon: Icons.photo_library_outlined,
              title: 'Upload photo',
              subtitle: 'Choose an existing image from your library.',
              request: MediaCaptureRequest(
                captureType: 'photo',
                source: MediaCaptureSource.gallery,
              ),
            ),
            const SizedBox(height: 8),
            const _CaptureActionTile(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Upload PDF',
              subtitle: 'Share a PDF document for analysis.',
              request: MediaCaptureRequest(
                captureType: 'pdf',
                source: MediaCaptureSource.filePicker,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo Picker Sheet (for tool call image requests) ────────────

class _PhotoPickerSheet extends StatelessWidget {
  const _PhotoPickerSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingM,
          10,
          AppDimensions.paddingM,
          AppDimensions.paddingM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add a photo',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const _CaptureActionTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take photo',
              subtitle: 'Open the camera.',
              request: MediaCaptureRequest(
                captureType: 'photo',
                source: MediaCaptureSource.camera,
              ),
            ),
            const SizedBox(height: 8),
            const _CaptureActionTile(
              icon: Icons.photo_library_outlined,
              title: 'Upload photo',
              subtitle: 'Choose from your library.',
              request: MediaCaptureRequest(
                captureType: 'photo',
                source: MediaCaptureSource.gallery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Capture Action Tile ──────────────────────────────────────────

class _CaptureActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final MediaCaptureRequest request;

  const _CaptureActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Material(
      color: c.surface.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        onTap: () => Navigator.of(context).pop(request),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.media.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: c.media, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
