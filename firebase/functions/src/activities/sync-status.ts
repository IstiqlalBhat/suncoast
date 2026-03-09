import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { createClient } from "@supabase/supabase-js";
import * as logger from "firebase-functions/logger";
import { authenticateCallableRequest, assertSessionOwnership } from "../utils/auth";
import { logFunctionError } from "../utils/logging";

const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

const validStatuses = new Set([
  "pending",
  "in_progress",
  "completed",
  "cancelled",
]);

export const syncActivityStatus = onCall(
  { secrets: [supabaseUrl, supabaseServiceKey], timeoutSeconds: 60 },
  async (request) => {
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { user, payload } = await authenticateCallableRequest(request, supabase);
    const sessionId = typeof payload.sessionId === "string" ? payload.sessionId : "";
    const status = typeof payload.status === "string" ? payload.status : "";

    if (!sessionId) {
      throw new HttpsError("invalid-argument", "Session ID is required");
    }

    if (!validStatuses.has(status)) {
      throw new HttpsError("invalid-argument", "Invalid activity status");
    }

    try {
      const session = await assertSessionOwnership(supabase, sessionId, user.id);
      const { data, error } = await supabase
        .from("activities")
        .update({
          status,
          updated_at: new Date().toISOString(),
        })
        .eq("id", session.activity_id)
        .eq("assigned_to", user.id)
        .select("id, status")
        .single();

      if (error || !data) {
        throw new Error(error?.message || "Activity update failed");
      }

      logger.info("Activity status synced", {
        sessionId,
        activityId: session.activity_id,
        status,
        userId: user.id,
      });

      return { activity: data };
    } catch (error) {
      logFunctionError("syncActivityStatus", error, {
        sessionId,
        userId: user.id,
        status,
      });
      throw new HttpsError("internal", "Failed to sync activity status");
    }
  },
);
