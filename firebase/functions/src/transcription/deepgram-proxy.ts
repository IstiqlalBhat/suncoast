import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";
import * as admin from "firebase-admin";

const deepgramSecret = defineSecret("DEEPGRAM_API_KEY");

export const deepgramProxy = onRequest(
  { secrets: [deepgramSecret], cors: true },
  async (req, res) => {
    // Verify Firebase Auth token
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({ error: "Missing or invalid authorization header" });
      return;
    }
    try {
      await admin.auth().verifyIdToken(authHeader.split("Bearer ")[1]);
    } catch {
      res.status(401).json({ error: "Invalid authentication token" });
      return;
    }

    const deepgramApiKey = deepgramSecret.value();

    if (!deepgramApiKey) {
      logger.error("deepgramProxy missing API key");
      res.status(500).json({ error: "Deepgram API key not configured" });
      return;
    }

    if (req.method !== "POST") {
      logger.warn("deepgramProxy invalid method", { method: req.method });
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const rawBody = req.rawBody || req.body;
      const audioData: BodyInit = rawBody instanceof Buffer
        ? new Uint8Array(rawBody) as unknown as BodyInit
        : rawBody as BodyInit;

      const response = await fetch(
        "https://api.deepgram.com/v1/listen?model=nova-2&smart_format=true&language=en",
        {
          method: "POST",
          headers: {
            Authorization: `Token ${deepgramApiKey}`,
            "Content-Type": "audio/raw;encoding=linear16;sample_rate=16000;channels=1",
          },
          body: audioData,
        }
      );

      const result = await response.json();
      if (!response.ok) {
        logger.error("deepgramProxy upstream error", {
          status: response.status,
          result,
        });
        res.status(response.status).json(result);
        return;
      }

      res.json(result);
    } catch (error) {
      logFunctionError("deepgramProxy", error);
      res.status(500).json({ error: "Transcription failed" });
    }
  }
);
