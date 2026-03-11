import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI, SchemaType } from "@google/generative-ai";
import { createClient } from "@supabase/supabase-js";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { logFunctionError } from "../utils/logging";
import {
  assertAttachmentOwnership,
  assertSessionOwnership,
  authenticateCallableRequest,
} from "../utils/auth";

const geminiKey = defineSecret("GEMINI_API_KEY");
const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

export const analyzeImage = onCall(
  { secrets: [geminiKey, supabaseUrl, supabaseServiceKey] },
  async (request) => {
    const genAI = new GoogleGenerativeAI(geminiKey.value());
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { user, payload } = await authenticateCallableRequest(request, supabase);
    const image = typeof payload.image === "string" ? payload.image : "";
    const context = typeof payload.context === "string" ? payload.context : undefined;
    const sessionId =
      typeof payload.sessionId === "string" ? payload.sessionId : undefined;
    const attachmentId =
      typeof payload.attachmentId === "string" ? payload.attachmentId : undefined;
    const mimeType =
      typeof payload.mimeType === "string" ? payload.mimeType : undefined;

    if (!image) {
      throw new HttpsError("invalid-argument", "Image is required");
    }

    if (sessionId) {
      await assertSessionOwnership(supabase, sessionId, user.id);
    }

    if (attachmentId) {
      await assertAttachmentOwnership(supabase, attachmentId, user.id);
    }

    logger.info("analyzeImage request received", {
      hasContext: Boolean(context),
      hasSessionId: Boolean(sessionId),
      imageLength: typeof image === "string" ? image.length : 0,
    });

    const model = genAI.getGenerativeModel({
      model: "gemini-3-flash-preview",
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: {
          type: SchemaType.OBJECT,
          required: ["description", "contextRelation", "event"],
          properties: {
            description: {
              type: SchemaType.STRING,
            },
            contextRelation: {
              type: SchemaType.STRING,
            },
            event: {
              type: SchemaType.OBJECT,
              required: ["type", "content"],
              properties: {
                type: {
                  type: SchemaType.STRING,
                },
                content: {
                  type: SchemaType.STRING,
                },
              },
            },
          },
        },
      },
    });

    const prompt = `You are a field inspection AI assistant. Review the image for a field worker.

Context: ${context || "Field inspection"}

Return JSON only.
- description: what is visible in the image, including any notable issue, condition, or observation.
- contextRelation: how the image relates to the provided field context.
- event: a concise observation event with type and content.

Keep the output practical, specific, and concise.`;

    try {
      const imagePart = {
        inlineData: {
          data: image,
          mimeType: mimeType || "image/jpeg",
        },
      };

      const result = await model.generateContent([prompt, imagePart]);
      const text = result.response.text().trim();
      const parsed = JSON.parse(text) as {
        description?: string;
        contextRelation?: string;
        event?: { type?: string; content?: string };
      };

      const description = parsed.description?.trim() || "";
      const contextRelation = parsed.contextRelation?.trim() || "";
      const analysis = [description, contextRelation]
        .filter((section) => section.length > 0)
        .join("\n\n");

      if (!analysis) {
        throw new Error("Vision response did not include analysis text");
      }

      if (attachmentId) {
        const { error: updateError } = await supabase
          .from("media_attachments")
          .update({
            ai_analysis: analysis,
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
          content: parsed.event.content || description,
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
        analysis,
        event: parsed.event || null,
        contextRelation,
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
        userId: user.id,
      });
      throw new HttpsError("internal", "Image analysis failed");
    }
  }
);
