import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";

const geminiKey = defineSecret("GEMINI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

type EventRecord = {
  type?: string;
  status?: string | null;
  content?: string;
  external_record_url?: string | null;
  action_label?: string | null;
};

type AttachmentRecord = {
  type?: string;
  storage_path?: string;
  ai_analysis?: string | null;
};

type SummaryActionStatus = {
  label?: string;
  description?: string;
  status?: string;
  external_label?: string | null;
  external_url?: string | null;
};

type SummaryExternalRecord = {
  label?: string;
  url?: string | null;
};

type SummaryResponse = {
  observation_summary?: string;
  key_observations?: string[];
  actions_taken?: string[];
  action_statuses?: SummaryActionStatus[];
  follow_ups?: unknown[];
  external_records?: SummaryExternalRecord[];
};

export const generateSummary = onCall(
  { secrets: [geminiKey, supabaseUrl, supabaseServiceKey] },
  async (request) => {
    const genAI = new GoogleGenerativeAI(geminiKey.value());
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { sessionId } = request.data;

    if (!sessionId) {
      throw new HttpsError("invalid-argument", "Session ID is required");
    }

    logger.info("generateSummary request received", {
      sessionId,
    });

    try {
      const [sessionResult, eventsResult, attachmentsResult] = await Promise.all([
        supabase.from("sessions").select("*").eq("id", sessionId).single(),
        supabase
          .from("ai_events")
          .select("*")
          .eq("session_id", sessionId)
          .order("created_at"),
        supabase
          .from("media_attachments")
          .select("*")
          .eq("session_id", sessionId)
          .order("uploaded_at"),
      ]);

      if (sessionResult.error) {
        throw new Error(`Session not found: ${sessionResult.error.message}`);
      }

      const session = sessionResult.data;
      const events = (eventsResult.data || []) as EventRecord[];
      const attachments = (attachmentsResult.data || []) as AttachmentRecord[];

      // Calculate duration
      const startedAt = new Date(session.started_at);
      const endedAt = session.ended_at
        ? new Date(session.ended_at)
        : new Date();
      const durationSeconds = Math.floor(
        (endedAt.getTime() - startedAt.getTime()) / 1000
      );

      const model = genAI.getGenerativeModel({ model: "gemini-3.1-pro-preview" });

      const activityResult = await supabase
        .from("activities")
        .select("*")
        .eq("id", session.activity_id)
        .maybeSingle();

      if (activityResult.error) {
        logger.warn("Failed to fetch activity for summary", { error: activityResult.error.message });
      }
      const activity = activityResult.data;
      const eventsText = events
        .map((event) =>
          `[${event.type}|${event.status ?? "completed"}] ${event.content}${
            event.external_record_url ? ` (external: ${event.external_record_url})` : ""
          }`
        )
        .join("\n");
      const attachmentsText = attachments
        .map((attachment) =>
          `[${attachment.type}] ${attachment.storage_path}${
            attachment.ai_analysis ? ` | analysis: ${attachment.ai_analysis}` : ""
          }`
        )
        .join("\n");

      const prompt = `You are generating the final structured summary for a field session.

Activity title: ${activity?.title || "Unknown activity"}
Activity description: ${activity?.description || "No description"}
Activity type: ${activity?.type || session.mode}
Location: ${activity?.location || "Unknown"}

The session lasted ${durationSeconds} seconds.

Transcript: ${session.transcript || "No transcript available"}

AI Events detected during session:
${eventsText || "No events recorded"}

Attachments captured during session:
${attachmentsText || "No attachments captured"}

Provide a structured summary as JSON:
{
  "observation_summary": "A concise paragraph describing what happened during the session",
  "key_observations": ["observation 1", "observation 2", ...],
  "actions_taken": ["action 1", "action 2", ...],
  "action_statuses": [
    {
      "label": "Created maintenance ticket",
      "status": "completed|in_progress|pending|failed",
      "external_label": "ClickUp task",
      "external_url": null
    }
  ],
  "follow_ups": [
    { "description": "follow-up task", "priority": "high|medium|low", "due_date": null }
  ],
  "external_records": [
    { "label": "Created task", "url": null }
  ]
}

Return valid JSON only. Keep dates in ISO-8601 or null.`;

      const result = await model.generateContent(prompt);
      const text = result.response.text();

      const jsonMatch = text.match(/\{[\s\S]*?\}(?=[^}]*$)/s) || text.match(/\{[\s\S]*\}/);
      const parsed: SummaryResponse = jsonMatch ?
        JSON.parse(jsonMatch[0]) as SummaryResponse :
        buildFallbackSummary(events, durationSeconds);

      // Insert summary into Supabase
      const summaryData = {
        session_id: sessionId,
        observation_summary: parsed.observation_summary || "",
        key_observations: parsed.key_observations || [],
        actions_taken: parsed.actions_taken || [],
        action_statuses: normalizeActionStatuses(
          parsed.action_statuses,
          events
        ),
        follow_ups: parsed.follow_ups || [],
        external_records: normalizeExternalRecords(
          parsed.external_records,
          events
        ),
        duration_seconds: durationSeconds,
      };

      const { data: summary, error } = await supabase
        .from("session_summaries")
        .upsert(summaryData, { onConflict: "session_id" })
        .select()
        .single();

      if (error) {
        throw new Error(`Failed to save summary: ${error.message}`);
      }

      return { summary };
    } catch (error) {
      logFunctionError("generateSummary", error, { sessionId });
      throw new HttpsError("internal", "Summary generation failed");
    }
  }
);

function buildFallbackSummary(
  events: EventRecord[],
  durationSeconds: number
): SummaryResponse {
  const observations = events
    .filter((event) => event.type === "observation")
    .map((event) => event.content)
    .filter((content): content is string => Boolean(content));
  const actions = events
    .filter((event) => event.type === "action")
    .map((event) => event.content)
    .filter((content): content is string => Boolean(content));
  const lookups = events
    .filter((event) => event.type === "lookup")
    .map((event) => event.content)
    .filter((content): content is string => Boolean(content));

  const overviewParts = [
    `Session duration: ${durationSeconds} seconds.`,
    observations.length > 0
      ? `${observations.length} observations were captured.`
      : "No observations were captured.",
    actions.length > 0
      ? `${actions.length} actions were identified.`
      : "No actions were identified.",
    lookups.length > 0
      ? `${lookups.length} lookups were surfaced.`
      : null,
  ].filter(Boolean);

  return {
    observation_summary: overviewParts.join(" "),
    key_observations: observations.slice(0, 5),
    actions_taken: actions.slice(0, 5),
    action_statuses: actions.slice(0, 5).map((action) => ({
      label: action,
      status: "completed",
      external_label: null,
      external_url: null,
    })),
    follow_ups: [],
    external_records: [],
  };
}

function normalizeActionStatuses(
  actionStatuses: SummaryActionStatus[] | undefined,
  events: EventRecord[]
) {
  if (Array.isArray(actionStatuses) && actionStatuses.length > 0) {
    return actionStatuses.map((item) => ({
      label: item?.label || item?.description || "Action",
      status: item?.status || "completed",
      external_label: item?.external_label || null,
      external_url: item?.external_url || null,
    }));
  }

  return events
    .filter((event) => event.type === "action")
    .map((event) => ({
      label: event.content,
      status: event.status || "completed",
      external_label: event.action_label || null,
      external_url: event.external_record_url || null,
    }));
}

function normalizeExternalRecords(
  externalRecords: SummaryExternalRecord[] | undefined,
  events: EventRecord[]
) {
  if (Array.isArray(externalRecords) && externalRecords.length > 0) {
    return externalRecords.map((item) => ({
      label: item?.label || "External record",
      url: item?.url || null,
    }));
  }

  return events
    .filter((event) => Boolean(event.external_record_url))
    .map((event) => ({
      label: event.action_label || event.content,
      url: event.external_record_url,
    }));
}
