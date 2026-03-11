import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { createClient } from "@supabase/supabase-js";
import { authenticateCallableRequest, assertSessionOwnership } from "../utils/auth";
import { logFunctionError } from "../utils/logging";
import { PDFParse } from "pdf-parse";

const supabaseUrl = defineSecret("SUPABASE_URL");
const supabaseServiceKey = defineSecret("SUPABASE_SERVICE_KEY");

const MAX_TEXT_LENGTH = 30000;

export const extractPdfText = onCall(
  { secrets: [supabaseUrl, supabaseServiceKey] },
  async (request) => {
    const supabase = createClient(supabaseUrl.value(), supabaseServiceKey.value());
    const { user, payload } = await authenticateCallableRequest(request, supabase);
    const sessionId = typeof payload.sessionId === "string" ? payload.sessionId.trim() : "";
    const pdfBase64 = typeof payload.pdfBase64 === "string" ? payload.pdfBase64 : "";

    if (!sessionId) {
      throw new HttpsError("invalid-argument", "sessionId is required");
    }

    if (!pdfBase64) {
      throw new HttpsError("invalid-argument", "pdfBase64 is required");
    }

    await assertSessionOwnership(supabase, sessionId, user.id);

    try {
      const buffer = Buffer.from(pdfBase64, "base64");
      const parser = new PDFParse({ data: buffer });
      const info = await parser.getInfo();
      const textResult = await parser.getText();
      await parser.destroy();

      let text = (textResult.text || "").trim();
      let truncated = false;

      if (text.length > MAX_TEXT_LENGTH) {
        text = text.substring(0, MAX_TEXT_LENGTH);
        truncated = true;
      }

      const pageCount = info.pages || 0;

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
      };
    } catch (error) {
      logFunctionError("extractPdfText", error, {
        sessionId,
        userId: user.id,
      });
      throw new HttpsError("internal", "Failed to extract PDF text");
    }
  },
);
