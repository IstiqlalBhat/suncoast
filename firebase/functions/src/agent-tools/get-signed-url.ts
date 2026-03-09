import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { createClient } from "@supabase/supabase-js";

const elevenLabsApiKey = defineSecret("ELEVENLABS_API_KEY");
const elevenLabsAgentId = defineSecret("ELEVENLABS_AGENT_ID");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

/**
 * Returns a signed WebSocket URL for ElevenLabs Conversational AI.
 * Uses onRequest (not onCall) to avoid Cloud Run IAM issues.
 * Auth is verified via Supabase Bearer token.
 */
export const getSignedConversationUrl = onRequest(
  {
    secrets: [elevenLabsApiKey, elevenLabsAgentId, supabaseUrl, supabaseServiceKey],
    cors: true,
  },
  async (req, res) => {
    // Verify Supabase auth token
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({ error: "Missing or invalid authorization header" });
      return;
    }

    try {
      const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
      const { data, error } = await supabase.auth.getUser(
        authHeader.split("Bearer ")[1]
      );
      if (error || !data.user) {
        res.status(401).json({ error: "Invalid authentication token" });
        return;
      }
    } catch {
      res.status(401).json({ error: "Authentication verification failed" });
      return;
    }

    const agentId = elevenLabsAgentId.value().trim();
    const apiKey = elevenLabsApiKey.value().trim();

    if (!agentId || !apiKey) {
      res.status(500).json({ error: "ElevenLabs credentials not configured" });
      return;
    }

    try {
      const response = await fetch(
        `https://api.elevenlabs.io/v1/convai/conversation/get_signed_url?agent_id=${agentId}`,
        {
          method: "GET",
          headers: { "xi-api-key": apiKey },
        }
      );

      if (!response.ok) {
        const errorText = await response.text();
        logger.error("ElevenLabs signed URL request failed", {
          status: response.status,
          error: errorText,
        });
        res.status(response.status).json({ error: "ElevenLabs API error" });
        return;
      }

      const result = (await response.json()) as { signed_url: string };

      logger.info("Signed conversation URL generated", { agentId });

      res.json({ signed_url: result.signed_url });
    } catch (error) {
      logger.error("Failed to get signed URL", { error });
      res.status(500).json({ error: "Failed to create conversation session" });
    }
  }
);
