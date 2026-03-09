import { onRequest } from "firebase-functions/v2/https";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { getSessionOwnerId } from "../utils/auth";

const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

/**
 * ElevenLabs Agent Tool: create_action
 *
 * Logs an action the user performed or plans to perform.
 * Called by the ElevenLabs Conversational AI agent via webhook.
 *
 * Expected JSON body:
 * {
 *   "description": "string (required) - What the user did or will do",
 *   "status": "string (optional) - completed | in_progress | planned",
 *   "session_id": "string (required) - The active session ID"
 * }
 */
export const agentCreateAction = onRequest(
  { secrets: [supabaseUrl, supabaseServiceKey], cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const { description, status, session_id: sessionId } = req.body;

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

      // Normalize status to match DB check constraint (pending|completed|skipped|failed)
      const validStatuses = ["pending", "completed", "skipped", "failed"];
      const rawStatus = (status || "completed").toLowerCase().trim();
      const normalizedStatus = validStatuses.includes(rawStatus)
        ? rawStatus
        : rawStatus.includes("progress") || rawStatus.includes("plan")
          ? "pending"
          : "completed";

      const { data, error } = await supabase.from("ai_events").insert({
        session_id: sessionId,
        type: "action",
        content: description,
        status: normalizedStatus,
        confidence: 0.9,
        metadata: {
          source: "elevenlabs_agent",
        },
      }).select().single();

      if (error) {
        logger.error("Failed to create action", { error: error.message });
        res.status(500).json({ error: "Failed to save action" });
        return;
      }

      logger.info("Action created", { id: data.id, sessionId, userId: session.user_id });

      res.json({
        success: true,
        message: `Action logged: ${description}`,
        event_id: data.id,
      });
    } catch (error) {
      logger.error("agentCreateAction failed", { error });
      res.status(500).json({ error: "Internal server error" });
    }
  }
);
