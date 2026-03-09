export type ActivityType = "passive" | "twoway" | "media";
export type ActivityStatus = "pending" | "in_progress" | "completed" | "cancelled";
export type SessionMode = "passive" | "chat" | "media";
export type SessionStatus = "active" | "ended" | "processing" | "failed";
export type AiEventType = "observation" | "lookup" | "action";
export type AiEventStatus = "pending" | "completed" | "skipped" | "failed";
export type MediaType = "photo" | "video" | "file";
export type ConfirmationMode = "always" | "smart" | "off";

export type Activity = {
  id: string;
  title: string;
  description: string | null;
  type: ActivityType;
  status: ActivityStatus;
  location: string | null;
  scheduled_at: string | null;
  assigned_to: string | null;
  org_id: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string | null;
};

export type SessionRecord = {
  id: string;
  activity_id: string;
  user_id: string;
  mode: SessionMode;
  status: SessionStatus;
  started_at: string;
  ended_at: string | null;
  ended_reason: string | null;
  processing_error: string | null;
  transcript: string | null;
  created_at: string | null;
  updated_at: string | null;
  activities?: Pick<Activity, "title" | "type"> | null;
};

export type AiEvent = {
  id: string;
  session_id: string;
  type: AiEventType;
  content: string;
  source: string;
  status: AiEventStatus;
  requires_confirmation: boolean;
  external_record_id: string | null;
  external_record_url: string | null;
  action_label: string | null;
  metadata: Record<string, unknown> | null;
  confidence: number | null;
  created_at: string | null;
};

export type MediaAttachment = {
  id: string;
  session_id: string;
  type: MediaType;
  storage_path: string;
  thumbnail_path: string | null;
  ai_analysis: string | null;
  mime_type: string | null;
  file_size_bytes: number | null;
  analysis_status: string;
  metadata: Record<string, unknown> | null;
  uploaded_at: string | null;
  created_at: string | null;
};

export type FollowUp = {
  description: string;
  priority: "high" | "medium" | "low";
  due_date: string | null;
};

export type ActionStatusSummary = {
  label: string;
  status: string;
  external_label: string | null;
  external_url: string | null;
};

export type ExternalRecord = {
  label: string;
  url: string | null;
};

export type SessionSummary = {
  id: string;
  session_id: string;
  observation_summary: string;
  key_observations: string[];
  actions_taken: string[];
  follow_ups: FollowUp[];
  action_statuses: ActionStatusSummary[];
  external_records: ExternalRecord[];
  duration_seconds: number | null;
  confirmed_at: string | null;
  created_at: string | null;
};

export type UserSettings = {
  id: string;
  user_id: string;
  face_id_enabled: boolean;
  voice_output_enabled: boolean;
  voice_id: string | null;
  voice_speed: number;
  confirmation_mode: ConfirmationMode;
  language: string;
  use_premium_tts: boolean;
};

export type ReferenceCard = {
  type?: string;
  title?: string;
  content?: string;
  subtitle?: string | null;
};

export type ChatFunctionResponse = {
  message?: string;
  events?: Array<{
    type?: AiEventType;
    content?: string;
    status?: string;
    actionLabel?: string | null;
    externalRecordUrl?: string | null;
  }>;
  referenceCards?: ReferenceCard[];
};
