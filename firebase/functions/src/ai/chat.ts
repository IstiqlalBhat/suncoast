import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";

const geminiKey = defineSecret("GEMINI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

type ChatEvent = {
  type?: string;
  content?: string;
  status?: string;
  actionLabel?: string | null;
  externalRecordUrl?: string | null;
};

type ReferenceCard = {
  type?: string;
  title?: string;
  content?: string;
  subtitle?: string | null;
};

type ChatResponse = {
  message?: string;
  events?: ChatEvent[];
  referenceCards?: ReferenceCard[];
};

export const chat = onCall(
  { secrets: [geminiKey, supabaseUrl, supabaseServiceKey] },
  async (request) => {
    const genAI = new GoogleGenerativeAI(geminiKey.value());
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { message, sessionContext, sessionId } = request.data;

    if (!message) {
      throw new HttpsError("invalid-argument", "Message is required");
    }

    logger.info("chat request received", {
      hasSessionContext: Boolean(sessionContext),
      hasSessionId: Boolean(sessionId),
      messageLength: typeof message === "string" ? message.length : 0,
    });

    const model = genAI.getGenerativeModel({ model: "gemini-3.1-pro-preview" });

    const prompt = `You are FieldFlow AI, a helpful voice assistant for field workers. You help with inspections, assessments, and documentation.

Session Context: ${sessionContext || "General field session"}

User said: "${message}"

Respond conversationally and helpfully. Also extract any events (observations, lookups, actions) from the conversation.

Respond with JSON:
{
  "message": "Your spoken response to the user",
  "events": [
    {
      "type": "observation|lookup|action",
      "content": "...",
      "status": "pending|completed|failed",
      "actionLabel": null,
      "externalRecordUrl": null
    }
  ],
  "referenceCards": [
    {
      "type": "info|contact|task|suggestion",
      "title": "...",
      "content": "...",
      "subtitle": null
    }
  ]
}

Return valid JSON only.`;

    try {
      const result = await model.generateContent(prompt);
      const text = result.response.text();

      const jsonMatch = text.match(/\{[\s\S]*?\}(?=[^}]*$)/s) || text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        return {
          message: "I'm sorry, I had trouble processing that. Could you repeat?",
          events: [],
          referenceCards: [],
        };
      }

      const parsed = JSON.parse(jsonMatch[0]) as ChatResponse;

      const events = Array.isArray(parsed.events) ? parsed.events : [];

      // Insert events into Supabase
      if (events.length > 0 && sessionId) {
        const eventsToInsert = events.map((event) => ({
          session_id: sessionId,
          type: event.type,
          content: event.content,
          status: event.status || "completed",
          action_label: event.actionLabel || null,
          external_record_url: event.externalRecordUrl || null,
          confidence: 0.85,
          metadata: {},
        }));

        const { error: insertError } = await supabase.from("ai_events").insert(eventsToInsert);
        if (insertError) {
          logger.error("Failed to insert chat events", { error: insertError.message });
        }
      }

      return {
        message: parsed.message || "",
        events,
        referenceCards: parsed.referenceCards || [],
      };
    } catch (error) {
      logFunctionError("chat", error, {
        hasSessionId: Boolean(sessionId),
      });
      throw new HttpsError("internal", "Chat processing failed");
    }
  }
);
