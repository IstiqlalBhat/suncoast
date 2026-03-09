"use client";

import Image from "next/image";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { EventFeed } from "@/components/session/event-feed";
import { SessionShell } from "@/components/session/session-shell";
import { callFunction } from "@/lib/firebase-functions";
import {
  createSession,
  endSession,
  getSessionAttachments,
} from "@/lib/data";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";
import { createSignedFileUrl, uploadSessionFile } from "@/lib/storage";
import type { Activity, MediaAttachment } from "@/lib/types";

type MediaSessionClientProps = {
  activity: Activity;
};

type PreviewAttachment = MediaAttachment & {
  preview_url?: string;
};

export function MediaSessionClient({ activity }: MediaSessionClientProps) {
  const router = useRouter();
  const supabase = getSupabaseBrowserClient();
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [attachments, setAttachments] = useState<PreviewAttachment[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function ensureSession() {
    if (sessionId) return sessionId;

    const session = await createSession(supabase, {
      activityId: activity.id,
      mode: "media",
    });
    await callFunction("syncActivityStatus", {
      sessionId: session.id,
      status: "in_progress",
    });
    setSessionId(session.id);
    return session.id;
  }

  async function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;

    setIsUploading(true);
    setError(null);

    try {
      const activeSessionId = await ensureSession();
      const attachment = await uploadSessionFile(activeSessionId, file);
      const imageBase64 = await fileToBase64(file);

      await callFunction("analyzeImage", {
        image: imageBase64,
        context: `${activity.title} ${activity.description ?? ""}`.trim(),
        sessionId: activeSessionId,
        attachmentId: attachment.id,
        mimeType: file.type,
      });

      const nextAttachments = await getSessionAttachments(supabase, activeSessionId);
      const withSignedUrls = await Promise.all(
        nextAttachments.map(async (item) => ({
          ...item,
          preview_url:
            item.mime_type?.startsWith("image/") && item.storage_path
              ? await createSignedFileUrl(item.storage_path)
              : undefined,
        })),
      );

      setAttachments(withSignedUrls);
    } catch (uploadError) {
      setError(
        uploadError instanceof Error
          ? uploadError.message
          : "Failed to analyze media.",
      );
    } finally {
      setIsUploading(false);
      event.target.value = "";
    }
  }

  async function finish() {
    if (!sessionId) return;

    try {
      await endSession(supabase, sessionId);
      await callFunction("syncActivityStatus", {
        sessionId,
        status: "completed",
      });
      router.push(`/session/${activity.id}/summary?sessionId=${sessionId}`);
      router.refresh();
    } catch (finishError) {
      setError(
        finishError instanceof Error
          ? finishError.message
          : "Failed to finish media session.",
      );
    }
  }

  return (
    <SessionShell
      eyebrow="Media Capture"
      title="Image-based field analysis"
      description="Upload camera or gallery images to the shared storage bucket, trigger Gemini image analysis through the existing function, and roll findings into the standard summary flow."
      activity={activity}
      status={isUploading ? "processing" : "ready"}
    >
      <div className="grid gap-5 lg:grid-cols-[1.05fr_0.95fr]">
        <div className="space-y-5">
          <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
            <h3 className="text-2xl font-semibold text-white">Upload media</h3>
            <p className="mt-2 text-sm leading-6 text-stone-300">
              Use the browser camera or file picker. Uploaded files go to the same `media-attachments` storage bucket used by mobile.
            </p>

            <label className="mt-6 flex cursor-pointer items-center justify-center rounded-[26px] border border-dashed border-white/15 bg-slate-950/35 px-6 py-14 text-center">
              <div>
                <p className="text-lg font-semibold text-white">
                  {isUploading ? "Analyzing..." : "Select a photo"}
                </p>
                <p className="mt-2 text-sm text-stone-400">
                  JPG, PNG, HEIC, or a camera capture from a supported browser.
                </p>
              </div>
              <input
                type="file"
                accept="image/*"
                capture="environment"
                onChange={handleFileChange}
                className="hidden"
              />
            </label>

            <button
              type="button"
              onClick={() => void finish()}
              disabled={!sessionId || attachments.length === 0 || isUploading}
              className="mt-6 rounded-full border border-white/10 px-5 py-3 text-sm uppercase tracking-[0.25em] text-stone-100 disabled:cursor-not-allowed disabled:opacity-60"
            >
              End session
            </button>

            {error ? (
              <div className="mt-4 rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
                {error}
              </div>
            ) : null}
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            {attachments.map((attachment) => (
              <div
                key={attachment.id}
                className="overflow-hidden rounded-[24px] border border-white/10 bg-slate-950/40"
              >
                {attachment.preview_url ? (
                  <div className="relative aspect-[4/3]">
                    <Image
                      src={attachment.preview_url}
                      alt="Attachment preview"
                      fill
                      className="object-cover"
                    />
                  </div>
                ) : null}
                <div className="p-4">
                  <p className="text-sm font-semibold text-white">
                    {attachment.metadata?.originalName
                      ? String(attachment.metadata.originalName)
                      : attachment.storage_path}
                  </p>
                  <p className="mt-2 text-sm leading-6 text-stone-300">
                    {attachment.ai_analysis || "AI analysis will appear after processing."}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <EventFeed sessionId={sessionId} />
      </div>
    </SessionShell>
  );
}

async function fileToBase64(file: File) {
  const buffer = await file.arrayBuffer();
  let binary = "";

  new Uint8Array(buffer).forEach((byte) => {
    binary += String.fromCharCode(byte);
  });

  return window.btoa(binary);
}
