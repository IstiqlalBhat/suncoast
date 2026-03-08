import { onCall, HttpsError } from "firebase-functions/v2/https";
import axios from "axios";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";

const elevenLabsKey = defineSecret("ELEVENLABS_API_KEY");

export const elevenLabsTts = onCall(
  { secrets: [elevenLabsKey] },
  async (request) => {
    const { text, voiceId } = request.data;

    if (!text) {
      throw new HttpsError("invalid-argument", "Text is required");
    }

    logger.info("elevenLabsTts request received", {
      hasVoiceId: Boolean(voiceId),
      textLength: typeof text === "string" ? text.length : 0,
    });

    const apiKey = elevenLabsKey.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "ElevenLabs API key not configured"
      );
    }

    const selectedVoiceId = voiceId || "21m00Tcm4TlvDq8ikWAM"; // Default Rachel voice

    try {
      const response = await axios.post(
        `https://api.elevenlabs.io/v1/text-to-speech/${selectedVoiceId}`,
        {
          text,
          model_id: "eleven_monolingual_v1",
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
          },
        },
        {
          headers: {
            "xi-api-key": apiKey,
            "Content-Type": "application/json",
            Accept: "audio/mpeg",
          },
          responseType: "arraybuffer",
        }
      );

      // Convert to base64 for transfer
      const audioBase64 = Buffer.from(response.data).toString("base64");

      return { audio: audioBase64, contentType: "audio/mpeg" };
    } catch (error) {
      logFunctionError("elevenLabsTts", error, {
        hasVoiceId: Boolean(voiceId),
      });
      throw new HttpsError("internal", "TTS generation failed");
    }
  }
);
