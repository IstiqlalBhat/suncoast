import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { createClient } from "@supabase/supabase-js";
import { authenticateCallableRequest, assertSessionOwnership } from "../utils/auth";
import { logFunctionError } from "../utils/logging";

const openaiKey = defineSecret("OPENAI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

function buildMediaInstructions(activityContext: string) {
  const trimmedContext = activityContext.trim() || "General session";

  return [
    "You are myEA (my Executive Assistant), a voice-first realtime media assistant.",
    "You communicate primarily through voice. Speak naturally, concisely, and practically.",
    "When the session starts, greet the user briefly and ask how you can help.",
    "",
    "Your capabilities:",
    "- Analyze photos the user shares with you and describe what you see",
    "- Read and discuss PDF documents the user uploads",
    "- Answer questions about the session context",
    "- Provide practical, operational guidance",
    "",
    "When you need visual context, call the request_image tool.",
    "When you need document context, call the request_pdf tool.",
    "Do not ask the user to take a photo in text — use the tools so the app can show a proper UI.",
    "",
    "Keep responses concise and operational, not chatty.",
    "If analyzing media, describe what is clearly visible, explain relevance to the context,",
    "call out defects or risks, and suggest follow-up if needed.",
    "",
    "Use this session context:",
    trimmedContext,
  ].join("\n");
}

export const createRealtimeMediaSession = onCall(
  { secrets: [openaiKey, supabaseUrl, supabaseServiceKey], timeoutSeconds: 120 },
  async (request) => {
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { user, payload } = await authenticateCallableRequest(request, supabase);
    const sessionId = typeof payload.sessionId === "string" ? payload.sessionId.trim() : "";
    const activityContext = typeof payload.activityContext === "string"
      ? payload.activityContext
      : "General session";

    if (!sessionId) {
      throw new HttpsError("invalid-argument", "sessionId is required");
    }

    await assertSessionOwnership(supabase, sessionId, user.id);

    const apiKey = openaiKey.value().trim();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "OpenAI API key not configured");
    }

    const instructions = buildMediaInstructions(activityContext);

    try {
      const controller = new AbortController();
      const fetchTimeout = setTimeout(() => controller.abort(), 60000);
      const response = await fetch("https://api.openai.com/v1/realtime/sessions", {
        signal: controller.signal,
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o-realtime-preview",
          modalities: ["text", "audio"],
          instructions,
          input_audio_format: "pcm16",
          output_audio_format: "pcm16",
          turn_detection: {
            type: "server_vad",
            threshold: 0.5,
            prefix_padding_ms: 300,
            silence_duration_ms: 500,
          },
          max_response_output_tokens: 4096,
          tools: [
            {
              type: "function",
              name: "request_image",
              description: "Request the user to take or upload a photo. Call this when you need visual context to help the user.",
              parameters: {
                type: "object",
                properties: {
                  reason: { type: "string", description: "Why you need an image" },
                },
                required: ["reason"],
              },
            },
            {
              type: "function",
              name: "request_pdf",
              description: "Request the user to upload a PDF document. Call this when you need document context.",
              parameters: {
                type: "object",
                properties: {
                  reason: { type: "string", description: "Why you need a PDF" },
                },
                required: ["reason"],
              },
            },
          ],
        }),
      });

      clearTimeout(fetchTimeout);
      const rawBody = await response.text();
      let body: Record<string, unknown>;
      try {
        body = rawBody ? JSON.parse(rawBody) as Record<string, unknown> : {};
      } catch {
        logger.error("createRealtimeMediaSession non-JSON response", {
          rawBody: rawBody.substring(0, 200),
          status: response.status,
        });
        throw new Error(`OpenAI returned non-JSON: ${rawBody.substring(0, 100)}`);
      }

      if (!response.ok) {
        logger.error("createRealtimeMediaSession upstream error", {
          status: response.status,
          body,
          userId: user.id,
          sessionId,
        });
        throw new Error(`OpenAI returned ${response.status}`);
      }

      const clientSecretSource = body.client_secret;
      const clientSecret = typeof clientSecretSource === "string"
        ? clientSecretSource
        : clientSecretSource &&
            typeof clientSecretSource === "object" &&
            typeof (clientSecretSource as { value?: unknown }).value === "string"
        ? (clientSecretSource as { value: string }).value
        : "";

      if (!clientSecret) {
        throw new Error("OpenAI session response did not include a client secret");
      }

      logger.info("createRealtimeMediaSession succeeded", {
        userId: user.id,
        sessionId,
        model: typeof body.model === "string" ? body.model : "gpt-4o-realtime-preview",
      });

      return {
        clientSecret,
        model: typeof body.model === "string" ? body.model : "gpt-4o-realtime-preview",
        sessionId: typeof body.id === "string" ? body.id : null,
        instructions,
        expiresAt:
          clientSecretSource &&
              typeof clientSecretSource === "object" &&
              typeof (clientSecretSource as { expires_at?: unknown }).expires_at === "number"
            ? (clientSecretSource as { expires_at: number }).expires_at
            : null,
      };
    } catch (error) {
      logFunctionError("createRealtimeMediaSession", error, {
        sessionId,
        userId: user.id,
      });
      throw new HttpsError("internal", "Failed to create OpenAI realtime session");
    }
  },
);
