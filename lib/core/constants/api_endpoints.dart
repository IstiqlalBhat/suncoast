abstract final class ApiEndpoints {
  // Firebase Function Endpoints
  static const processTranscript = '/processTranscript';
  static const chat = '/chat';
  static const analyzeImage = '/analyzeImage';
  static const generateSummary = '/generateSummary';
  static const whisperProxy = '/whisperProxy';
  static const openaiTts = '/openaiTts';
  static const getSignedConversationUrl = '/getSignedConversationUrl';

  // Supabase Tables
  static const profilesTable = 'profiles';
  static const organizationsTable = 'organizations';
  static const activitiesTable = 'activities';
  static const sessionsTable = 'sessions';
  static const aiEventsTable = 'ai_events';
  static const mediaAttachmentsTable = 'media_attachments';
  static const sessionSummariesTable = 'session_summaries';
  static const userSettingsTable = 'user_settings';

  // Supabase Storage Buckets
  static const mediaAttachmentsBucket = 'media-attachments';
  static const avatarsBucket = 'avatars';
}
