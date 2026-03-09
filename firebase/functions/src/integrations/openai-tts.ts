import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";
import { createClient } from "@supabase/supabase-js";
import { authenticateCallableRequest } from "../utils/auth";

const openaiKey = defineSecret("OPENAI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

export const openaiTts = onCall(
  { secrets: [openaiKey, supabaseUrl, supabaseServiceKey] },
  async (request) => {
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { user, payload } = await authenticateCallableRequest(request, supabase);
    const text = typeof payload.text === "string" ? payload.text : "";
    const voice = typeof payload.voice === "string" ? payload.voice : undefined;

    if (!text) {
      throw new HttpsError("invalid-argument", "Text is required");
    }

    const apiKey = openaiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "OpenAI API key not configured"
      );
    }

    // OpenAI TTS voices: alloy, echo, fable, onyx, nova, shimmer
    const selectedVoice = voice || "nova";

    logger.info("openaiTts request received", {
      userId: user.id,
      voice: selectedVoice,
      textLength: typeof text === "string" ? text.length : 0,
    });

    try {
      const response = await fetch("https://api.openai.com/v1/audio/speech", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "tts-1",
          input: text,
          voice: selectedVoice,
          response_format: "mp3",
        }),
      });

      if (!response.ok) {
        const errorBody = await response.text();
        logger.error("openaiTts upstream error", {
          status: response.status,
          body: errorBody,
        });
        throw new Error(`OpenAI TTS returned ${response.status}`);
      }

      const arrayBuffer = await response.arrayBuffer();
      const audioBase64 = Buffer.from(arrayBuffer).toString("base64");

      return { audio: audioBase64, contentType: "audio/mpeg" };
    } catch (error) {
      logFunctionError("openaiTts", error);
      throw new HttpsError("internal", "TTS generation failed");
    }
  }
);
