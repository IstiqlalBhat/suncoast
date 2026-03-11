enum ConversationRole { user, ai, system }

enum ConversationEntryType { text, mediaAttachment, toolRequest }

class ToolCallRequest {
  final String callId;
  final String toolName;
  final String reason;

  const ToolCallRequest({
    required this.callId,
    required this.toolName,
    required this.reason,
  });
}

class ConversationEntry {
  final String id;
  final ConversationRole role;
  final ConversationEntryType type;
  final String text;
  final DateTime timestamp;
  final String? mediaUrl;
  final ToolCallRequest? toolRequest;

  const ConversationEntry({
    required this.id,
    required this.role,
    required this.type,
    required this.text,
    required this.timestamp,
    this.mediaUrl,
    this.toolRequest,
  });
}
