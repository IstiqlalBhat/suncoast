import { onRequest } from "firebase-functions/v2/https";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { getSessionOwnerId } from "../utils/auth";

const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

/**
 * ElevenLabs Agent Tool: create_observation
 *
 * Records a field observation from the user's voice input.
 * Called by the ElevenLabs Conversational AI agent via webhook.
 *
 * Expected JSON body:
 * {
 *   "description": "string (required) - What the user observed",
 *   "severity": "string (optional) - low | medium | high | critical",
 *   "category": "string (optional) - safety | maintenance | quality | environmental",
 *   "session_id": "string (required) - The active session ID"
 * }
 */
export const agentCreateObservation = onRequest(
  { secrets: [supabaseUrl, supabaseServiceKey], cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const { description, severity, category, session_id: sessionId } = req.body;

      if (!description || !sessionId) {
        res.status(400).json({
          error: "Missing required fields: description, session_id",
        });
        return;
      }

      const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
      const session = await getSessionOwnerId(supabase, sessionId);

      if (session.status !== "active" && session.status !== "processing") {
        res.status(400).json({ error: "Session is not active" });
        return;
      }

      const { data, error } = await supabase.from("ai_events").insert({
        session_id: sessionId,
        type: "observation",
        content: description,
        status: "completed",
        metadata: {
          source: "elevenlabs_agent",
          severity: severity || "medium",
          category: category || "general",
        },
      }).select().single();

      if (error) {
        logger.error("Failed to create observation", { error: error.message });
        res.status(500).json({ error: "Failed to save observation" });
        return;
      }

      logger.info("Observation created", { id: data.id, sessionId, userId: session.user_id });

      res.json({
        success: true,
        message: `Observation recorded: ${description}`,
        event_id: data.id,
      });
    } catch (error) {
      logger.error("agentCreateObservation failed", { error });
      res.status(500).json({ error: "Internal server error" });
    }
  }
);
