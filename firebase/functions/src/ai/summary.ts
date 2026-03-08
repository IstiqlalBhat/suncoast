import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";

const geminiKey = defineSecret("GEMINI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

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
      // Fetch session and events from Supabase
      const [sessionResult, eventsResult] = await Promise.all([
        supabase.from("sessions").select("*").eq("id", sessionId).single(),
        supabase
          .from("ai_events")
          .select("*")
          .eq("session_id", sessionId)
          .order("created_at"),
      ]);

      if (sessionResult.error) {
        throw new Error(`Session not found: ${sessionResult.error.message}`);
      }

      const session = sessionResult.data;
      const events = eventsResult.data || [];

      // Calculate duration
      const startedAt = new Date(session.started_at);
      const endedAt = session.ended_at
        ? new Date(session.ended_at)
        : new Date();
      const durationSeconds = Math.floor(
        (endedAt.getTime() - startedAt.getTime()) / 1000
      );

      const model = genAI.getGenerativeModel({ model: "gemini-3.1-pro-preview" });

      const eventsText = events
        .map((e: any) => `[${e.type}] ${e.content}`)
        .join("\n");

      const prompt = `Summarize this field session. The session lasted ${durationSeconds} seconds.

Transcript: ${session.transcript || "No transcript available"}

AI Events detected during session:
${eventsText || "No events recorded"}

Provide a structured summary as JSON:
{
  "key_observations": ["observation 1", "observation 2", ...],
  "actions_taken": ["action 1", "action 2", ...],
  "follow_ups": [
    { "description": "follow-up task", "priority": "high|medium|low", "due_date": null }
  ]
}`;

      const result = await model.generateContent(prompt);
      const text = result.response.text();

      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error("Failed to parse summary response");
      }

      const parsed = JSON.parse(jsonMatch[0]);

      // Insert summary into Supabase
      const summaryData = {
        session_id: sessionId,
        key_observations: parsed.key_observations || [],
        actions_taken: parsed.actions_taken || [],
        follow_ups: parsed.follow_ups || [],
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
