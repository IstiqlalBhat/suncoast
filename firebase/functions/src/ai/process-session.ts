import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";
import { assertSessionOwnership, authenticateCallableRequest } from "../utils/auth";

const geminiKey = defineSecret("GEMINI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

type TranscriptEvent = {
  type?: string;
  content?: string;
};

type ProcessTranscriptResponse = {
  events?: TranscriptEvent[];
};

export const processTranscript = onCall(
  { secrets: [geminiKey, supabaseUrl, supabaseServiceKey] },
  async (request) => {
    const genAI = new GoogleGenerativeAI(geminiKey.value());
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { user, payload } = await authenticateCallableRequest(request, supabase);
    const transcript = typeof payload.transcript === "string" ? payload.transcript : "";
    const activityContext =
      typeof payload.activityContext === "string" ? payload.activityContext : undefined;
    const sessionId =
      typeof payload.sessionId === "string" ? payload.sessionId : undefined;

    if (!transcript) {
      throw new HttpsError("invalid-argument", "Transcript is required");
    }

    if (sessionId) {
      await assertSessionOwnership(supabase, sessionId, user.id);
    }

    logger.info("processTranscript request received", {
      hasActivityContext: Boolean(activityContext),
      hasSessionId: Boolean(sessionId),
      transcriptLength: typeof transcript === "string" ? transcript.length : 0,
    });

    const model = genAI.getGenerativeModel({ model: "gemini-3.1-pro-preview" });

    const prompt = `You are an AI assistant for field sessions. Analyze the following transcript from a field session and extract ONLY operationally meaningful events.

Activity Context: ${activityContext || "General field work"}

Transcript:
${transcript}

Extract events as a JSON array. Each event should have:
- "type": one of "observation", "lookup", or "action"
- "content": a concise, self-contained description

QUALITY RULES:
Transcripts often contain greetings, small talk, filler, thinking out loud, and casual conversation between people. Do NOT create events for any of these. Only create events that would be useful to someone reviewing the session log who was not present.

If the transcript contains no meaningful operational content, return an empty array: { "events": [] }

IMPORTANT: Evaluate statements in the context of the full conversation. If a person says something brief like "looks good" or "that's fine" right after discussing a specific item or task, that IS a meaningful confirmation — log it as an observation with enough context to stand on its own (e.g., "Confirmed [the thing discussed] is in acceptable condition").

OBSERVATION — A specific finding, condition, measurement, procedure, limitation, or requirement noticed or stated on site.
  Create when a person describes something concrete about their activity.
  When a person describes HOW they did something (the method) and WHAT they found (the result), those are two separate observations — do not merge them.
  When a person states what something can or cannot do, or is or is not designed for, that is its own observation.
  When a person states a rule or prerequisite, capture it even if it sounds like general knowledge.
  If something is repeated or emphasized, it is important.
  Skip when there is nothing specific being referenced.

ACTION — A specific task completed, started, or decided with a clear outcome.
  Create when a person names what they did or will do concretely.
  Skip when someone expresses vague intent without naming the actual task.

LOOKUP — A specific request for information, procedures, data, or contacts.
  Create when a person asks about something specific they need for their activity.
  Skip for conversational questions or questions about the AI.

Write each event's content to be self-contained — someone reading just the event should understand what it refers to without needing the full transcript.

Respond with ONLY valid JSON: { "events": [...] }`;

    try {
      const result = await model.generateContent(prompt);
      const text = result.response.text();

      const jsonMatch = text.match(/\{[\s\S]*?\}(?=[^}]*$)/s) || text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error("Failed to parse AI response");
      }

      const parsed = JSON.parse(jsonMatch[0]) as ProcessTranscriptResponse;
      const events = Array.isArray(parsed.events) ? parsed.events : [];

      // Insert events into Supabase
      if (events.length > 0 && sessionId) {
        const eventsToInsert = events.map((event) => ({
          session_id: sessionId,
          type: event.type,
          content: event.content,
          metadata: {},
        }));

        const { error: insertError } = await supabase.from("ai_events").insert(eventsToInsert);
        if (insertError) {
          logger.error("Failed to insert transcript events", { error: insertError.message });
        }
      }

      return { events };
    } catch (error) {
      logFunctionError("processTranscript", error, {
        hasSessionId: Boolean(sessionId),
        userId: user.id,
      });
      throw new HttpsError("internal", "Failed to process transcript");
    }
  }
);
