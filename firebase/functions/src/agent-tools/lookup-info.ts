import { onRequest } from "firebase-functions/v2/https";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

/**
 * ElevenLabs Agent Tool: lookup_info
 *
 * Looks up reference information, procedures, contacts, or past observations.
 * Called by the ElevenLabs Conversational AI agent via webhook.
 *
 * Expected JSON body:
 * {
 *   "query": "string (required) - What the user wants to know about",
 *   "type": "string (optional) - procedure | contact | history | general",
 *   "session_id": "string (required) - The active session ID"
 * }
 */
export const agentLookupInfo = onRequest(
  { secrets: [supabaseUrl, supabaseServiceKey], cors: true, invoker: "public" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const { query, lookup_type, type, session_id: sessionId } = req.body;

      if (!query || !sessionId) {
        res.status(400).json({
          error: "Missing required fields: query, session_id",
        });
        return;
      }

      const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
      const lookupType = lookup_type || type || "general";

      // Look up recent events from this session for context
      const { data: sessionEvents } = await supabase
        .from("ai_events")
        .select("type, content, status, metadata, created_at")
        .eq("session_id", sessionId)
        .order("created_at", { ascending: false })
        .limit(20);

      // Look up past sessions for historical context
      const { data: pastEvents } = await supabase
        .from("ai_events")
        .select("type, content, status, metadata, created_at")
        .ilike("content", `%${query}%`)
        .order("created_at", { ascending: false })
        .limit(10);

      const results = {
        current_session: sessionEvents || [],
        related_history: pastEvents || [],
        lookup_type: lookupType,
      };

      const hasResults =
        (results.current_session.length > 0) ||
        (results.related_history.length > 0);

      logger.info("Lookup completed", {
        query,
        type: lookupType,
        sessionId,
        currentEvents: results.current_session.length,
        historyEvents: results.related_history.length,
      });

      if (!hasResults) {
        res.json({
          success: true,
          message: `No records found for: ${query}`,
          results: [],
        });
        return;
      }

      // Format results for the agent to speak back
      const summaryLines: string[] = [];

      if (results.current_session.length > 0) {
        summaryLines.push(
          `Found ${results.current_session.length} events in current session.`
        );
        for (const event of results.current_session.slice(0, 5)) {
          summaryLines.push(`- ${event.type}: ${event.content}`);
        }
      }

      if (results.related_history.length > 0) {
        summaryLines.push(
          `Found ${results.related_history.length} related past records.`
        );
        for (const event of results.related_history.slice(0, 5)) {
          summaryLines.push(`- ${event.type}: ${event.content}`);
        }
      }

      res.json({
        success: true,
        message: summaryLines.join("\n"),
        results,
      });
    } catch (error) {
      logger.error("agentLookupInfo failed", { error });
      res.status(500).json({ error: "Internal server error" });
    }
  }
);
