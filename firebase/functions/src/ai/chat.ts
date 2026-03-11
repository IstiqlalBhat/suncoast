import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI, SchemaType } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";
import { assertSessionOwnership, authenticateCallableRequest } from "../utils/auth";

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
    const { user, payload } = await authenticateCallableRequest(request, supabase);
    const message = typeof payload.message === "string" ? payload.message : "";
    const sessionContext =
      typeof payload.sessionContext === "string" ? payload.sessionContext : undefined;
    const sessionId =
      typeof payload.sessionId === "string" ? payload.sessionId : undefined;

    if (!message) {
      throw new HttpsError("invalid-argument", "Message is required");
    }

    if (sessionId) {
      await assertSessionOwnership(supabase, sessionId, user.id);
    }

    logger.info("chat request received", {
      hasSessionContext: Boolean(sessionContext),
      hasSessionId: Boolean(sessionId),
      messageLength: typeof message === "string" ? message.length : 0,
    });

    const model = genAI.getGenerativeModel({
      model: "gemini-3.1-pro-preview",
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: {
          type: SchemaType.OBJECT,
          required: ["message", "events", "referenceCards"],
          properties: {
            message: {
              type: SchemaType.STRING,
            },
            events: {
              type: SchemaType.ARRAY,
              items: {
                type: SchemaType.OBJECT,
                properties: {
                  type: { type: SchemaType.STRING },
                  content: { type: SchemaType.STRING },
                  status: { type: SchemaType.STRING },
                  actionLabel: { type: SchemaType.STRING, nullable: true },
                  externalRecordUrl: {
                    type: SchemaType.STRING,
                    nullable: true,
                  },
                },
              },
            },
            referenceCards: {
              type: SchemaType.ARRAY,
              items: {
                type: SchemaType.OBJECT,
                properties: {
                  type: { type: SchemaType.STRING },
                  title: { type: SchemaType.STRING },
                  content: { type: SchemaType.STRING },
                  subtitle: { type: SchemaType.STRING, nullable: true },
                },
              },
            },
          },
        },
      },
    });

    const prompt = `You are myEA (my Executive Assistant), a helpful AI voice assistant. You help with tasks, planning, assessments, and documentation.

Session Context: ${sessionContext || "General session"}

User said: "${message}"

Treat the full session context as active working memory.
- Maintain continuity across turns instead of answering each turn as a fresh conversation.
- If the session context includes image or media findings, use those findings directly when they are relevant.
- If the user asks a follow-up like "what about that" or "does it matter", resolve it using the session context before asking the user to repeat details.
- Keep the spoken response concise and natural.
- Also extract any events (observations, lookups, actions) from the conversation.

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
      const text = result.response.text().trim();
      const parsed = JSON.parse(text) as ChatResponse;

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
        userId: user.id,
      });
      throw new HttpsError("internal", "Chat processing failed");
    }
  }
);
