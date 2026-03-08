import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";

const geminiKey = defineSecret("GEMINI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

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
  "events": [{ "type": "observation|lookup|action", "content": "..." }],
  "referenceCards": [{ "type": "info|contact|task", "title": "...", "content": "..." }]
}`;

    try {
      const result = await model.generateContent(prompt);
      const text = result.response.text();

      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        return {
          message: "I'm sorry, I had trouble processing that. Could you repeat?",
          events: [],
          referenceCards: [],
        };
      }

      const parsed = JSON.parse(jsonMatch[0]);

      // Insert events into Supabase
      if (parsed.events?.length > 0 && sessionId) {
        const eventsToInsert = parsed.events.map((event: any) => ({
          session_id: sessionId,
          type: event.type,
          content: event.content,
          confidence: 0.85,
          metadata: {},
        }));

        await supabase.from("ai_events").insert(eventsToInsert);
      }

      return {
        message: parsed.message || "",
        events: parsed.events || [],
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
