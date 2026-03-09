import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";

const geminiKey = defineSecret("GEMINI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

export const analyzeImage = onCall(
  { secrets: [geminiKey, supabaseUrl, supabaseServiceKey] },
  async (request) => {
    const genAI = new GoogleGenerativeAI(geminiKey.value());
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { image, context, sessionId, attachmentId, mimeType } = request.data;

    if (!image) {
      throw new HttpsError("invalid-argument", "Image is required");
    }

    logger.info("analyzeImage request received", {
      hasContext: Boolean(context),
      hasSessionId: Boolean(sessionId),
      imageLength: typeof image === "string" ? image.length : 0,
    });

    const model = genAI.getGenerativeModel({ model: "gemini-3.1-pro-preview" });

    const prompt = `You are a field inspection AI assistant. Analyze this image and provide a detailed condition report.

Context: ${context || "Field inspection"}

Provide your analysis as JSON:
{
  "analysis": "Detailed description of what you see, any issues, conditions, or notable observations",
  "event": {
    "type": "observation",
    "content": "Brief summary of the key finding from this image"
  }
}`;

    try {
      const imagePart = {
        inlineData: {
          data: image,
          mimeType: mimeType || "image/jpeg",
        },
      };

      const result = await model.generateContent([prompt, imagePart]);
      const text = result.response.text();

      const jsonMatch = text.match(/\{[\s\S]*?\}(?=[^}]*$)/s) || text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error("Failed to parse vision response");
      }

      const parsed = JSON.parse(jsonMatch[0]);

      if (attachmentId) {
        const { error: updateError } = await supabase
          .from("media_attachments")
          .update({
            ai_analysis: parsed.analysis || "",
            analysis_status: "completed",
          })
          .eq("id", attachmentId);
        if (updateError) {
          logger.error("Failed to update attachment analysis", { error: updateError.message });
        }
      }

      // Insert event into Supabase
      if (parsed.event && sessionId) {
        const { error: insertError } = await supabase.from("ai_events").insert({
          session_id: sessionId,
          type: parsed.event.type || "observation",
          content: parsed.event.content,
          confidence: 0.9,
          source: "ai",
          metadata: {
            source: "vision",
            attachmentId: attachmentId || null,
          },
        });
        if (insertError) {
          logger.error("Failed to insert vision event", { error: insertError.message });
        }
      }

      return {
        analysis: parsed.analysis || "",
        event: parsed.event || null,
      };
    } catch (error) {
      if (attachmentId) {
        await supabase
          .from("media_attachments")
          .update({ analysis_status: "failed" })
          .eq("id", attachmentId);
      }
      logFunctionError("analyzeImage", error, {
        hasSessionId: Boolean(sessionId),
      });
      throw new HttpsError("internal", "Image analysis failed");
    }
  }
);
