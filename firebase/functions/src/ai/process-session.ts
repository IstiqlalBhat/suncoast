import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";

const geminiKey = defineSecret("GEMINI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

type TranscriptEvent = {
  type?: string;
  content?: string;
  confidence?: number;
};

type ProcessTranscriptResponse = {
  events?: TranscriptEvent[];
};

export const processTranscript = onCall(
  { secrets: [geminiKey, supabaseUrl, supabaseServiceKey] },
  async (request) => {
    const genAI = new GoogleGenerativeAI(geminiKey.value());
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { transcript, activityContext, sessionId } = request.data;

    if (!transcript) {
      throw new HttpsError("invalid-argument", "Transcript is required");
    }

    logger.info("processTranscript request received", {
      hasActivityContext: Boolean(activityContext),
      hasSessionId: Boolean(sessionId),
      transcriptLength: typeof transcript === "string" ? transcript.length : 0,
    });

    const model = genAI.getGenerativeModel({ model: "gemini-3.1-pro-preview" });

    const prompt = `You are an AI assistant for field workers. Analyze the following transcript from a field session and extract structured observations.

Activity Context: ${activityContext || "General field work"}

Transcript:
${transcript}

Extract the following as a JSON array of events. Each event should have:
- "type": one of "observation", "lookup", or "action"
- "content": a concise description
- "confidence": a number between 0 and 1

Observations: Things the worker noted or described about the environment, equipment, or conditions.
Lookups: Information requests, references to documents, or data the worker mentioned needing.
Actions: Tasks completed, decisions made, or steps taken during the session.

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
          confidence: event.confidence || 0.8,
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
      });
      throw new HttpsError("internal", "Failed to process transcript");
    }
  }
);
