import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";
import { createClient } from "@supabase/supabase-js";

const openaiKey = defineSecret("OPENAI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

export const whisperProxy = onRequest(
  { secrets: [openaiKey, supabaseUrl, supabaseServiceKey], cors: true },
  async (req, res) => {
    // Verify Supabase auth token
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({ error: "Missing or invalid authorization header" });
      return;
    }
    try {
      const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
      const { data, error } = await supabase.auth.getUser(authHeader.split("Bearer ")[1]);
      if (error || !data.user) {
        res.status(401).json({ error: "Invalid authentication token" });
        return;
      }
    } catch {
      res.status(401).json({ error: "Authentication verification failed" });
      return;
    }

    const apiKey = openaiKey.value();
    if (!apiKey) {
      logger.error("whisperProxy missing OPENAI_API_KEY");
      res.status(500).json({ error: "OpenAI API key not configured" });
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const rawBody = req.rawBody ?? req.body;
      if (!rawBody || (Buffer.isBuffer(rawBody) && rawBody.length === 0)) {
        res.status(400).json({ error: "Empty audio body" });
        return;
      }

      const audioBuffer = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody);

      logger.info("whisperProxy forwarding audio", {
        bodySize: audioBuffer.length,
        contentType: req.headers["content-type"],
      });

      // Build multipart form for OpenAI Whisper API
      const blob = new Blob([audioBuffer as unknown as BlobPart], { type: "audio/wav" });
      const formData = new FormData();
      formData.append("file", blob, "audio.wav");
      formData.append("model", "whisper-1");
      formData.append("language", "en");
      formData.append("response_format", "json");

      const response = await fetch(
        "https://api.openai.com/v1/audio/transcriptions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${apiKey}`,
          },
          body: formData,
        }
      );

      const result = await response.json();

      if (!response.ok) {
        logger.error("whisperProxy upstream error", {
          status: response.status,
          result,
        });
        res.status(response.status).json(result);
        return;
      }

      // Whisper returns { "text": "..." } — normalize to { "transcript": "..." }
      res.json({ transcript: result.text || "" });
    } catch (error) {
      logFunctionError("whisperProxy", error);
      res.status(500).json({ error: "Transcription failed" });
    }
  }
);
