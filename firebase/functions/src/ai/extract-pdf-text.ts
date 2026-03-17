import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { createClient } from "@supabase/supabase-js";
import {
  assertAttachmentOwnership,
  assertSessionOwnership,
  authenticateCallableRequest,
} from "../utils/auth";
import { logFunctionError } from "../utils/logging";
import PDFParse from "pdf-parse";

const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

const MAX_TEXT_LENGTH = 30000;
const MAX_ATTACHMENT_ANALYSIS_LENGTH = 6000;
const MAX_EVENT_SNIPPET_LENGTH = 320;

export const extractPdfText = onCall(
  { secrets: [supabaseUrl, supabaseServiceKey] },
  async (request) => {
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { user, payload } = await authenticateCallableRequest(request, supabase);
    const sessionId = typeof payload.sessionId === "string" ? payload.sessionId.trim() : "";
    const pdfBase64 = typeof payload.pdfBase64 === "string" ? payload.pdfBase64 : "";
    const attachmentId =
      typeof payload.attachmentId === "string" ? payload.attachmentId.trim() : "";

    if (!sessionId) {
      throw new HttpsError("invalid-argument", "sessionId is required");
    }

    if (!pdfBase64) {
      throw new HttpsError("invalid-argument", "pdfBase64 is required");
    }

    await assertSessionOwnership(supabase, sessionId, user.id);
    if (attachmentId) {
      await assertAttachmentOwnership(supabase, attachmentId, user.id);
    }

    try {
      const buffer = Buffer.from(pdfBase64, "base64");
      const data = await PDFParse(buffer);

      let text = (data.text || "").trim();
      let truncated = false;

      if (text.length > MAX_TEXT_LENGTH) {
        text = text.substring(0, MAX_TEXT_LENGTH);
        truncated = true;
      }

      const pageCount = data.numpages || 0;
      const analysis = buildAttachmentAnalysis(text, pageCount, truncated);

      if (attachmentId) {
        const { error: updateError } = await supabase
          .from("media_attachments")
          .update({
            ai_analysis: analysis,
            analysis_status: "completed",
          })
          .eq("id", attachmentId)
          .eq("user_id", user.id);

        if (updateError) {
          logger.error("Failed to update PDF attachment analysis", {
            attachmentId,
            error: updateError.message,
          });
        }
      }

      const { error: insertError } = await supabase.from("ai_events").insert({
        session_id: sessionId,
        type: "observation",
        content: buildPdfObservation(text, pageCount, truncated),
        source: "pdf_extract",
        metadata: {
          source: "pdf_extract",
          attachmentId: attachmentId || null,
          pageCount,
          truncated,
        },
      });

      if (insertError) {
        logger.error("Failed to insert PDF extraction event", {
          sessionId,
          error: insertError.message,
        });
      }

      logger.info("extractPdfText succeeded", {
        userId: user.id,
        sessionId,
        pageCount,
        textLength: text.length,
        truncated,
      });

      return {
        text,
        pageCount,
        truncated,
        analysis,
      };
    } catch (error) {
      if (attachmentId) {
        await supabase
          .from("media_attachments")
          .update({ analysis_status: "failed" })
          .eq("id", attachmentId)
          .eq("user_id", user.id);
      }
      logFunctionError("extractPdfText", error, {
        sessionId,
        userId: user.id,
      });
      throw new HttpsError("internal", "Failed to extract PDF text");
    }
  },
);

function buildAttachmentAnalysis(text: string, pageCount: number, truncated: boolean) {
  const header = `PDF extracted successfully (${pageCount} pages${truncated ? ", truncated" : ""}).`;
  const normalizedText = normalizeWhitespace(text);
  if (!normalizedText) {
    return header;
  }

  const remaining = Math.max(MAX_ATTACHMENT_ANALYSIS_LENGTH - header.length - 2, 0);
  const excerpt = normalizedText.slice(0, remaining).trim();
  return excerpt ? `${header}\n\n${excerpt}` : header;
}

function buildPdfObservation(text: string, pageCount: number, truncated: boolean) {
  const header = `PDF uploaded (${pageCount} pages${truncated ? ", extracted text truncated" : ""}).`;
  const normalizedText = normalizeWhitespace(text);
  if (!normalizedText) {
    return header;
  }

  const excerpt = normalizedText.slice(0, MAX_EVENT_SNIPPET_LENGTH).trim();
  return `${header} ${excerpt}`;
}

function normalizeWhitespace(value: string) {
  return value.replace(/\s+/g, " ").trim();
}
