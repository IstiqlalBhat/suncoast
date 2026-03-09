"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { EventFeed } from "@/components/session/event-feed";
import { SessionShell } from "@/components/session/session-shell";
import { BrowserPcmRecorder } from "@/lib/audio/browser-recorder";
import { wrapPcmAsWav } from "@/lib/audio/wav";
import { supportsBrowserRecording } from "@/lib/browser-capabilities";
import { callAuthorizedFunction, callFunction } from "@/lib/firebase-functions";
import { createSession, endSession, updateSession } from "@/lib/data";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";
import type { Activity } from "@/lib/types";

type PassiveSessionClientProps = {
  activity: Activity;
};

type Phase = "idle" | "starting" | "recording" | "processing" | "finishing" | "error";

export function PassiveSessionClient({ activity }: PassiveSessionClientProps) {
  const router = useRouter();
  const supabase = getSupabaseBrowserClient();
  const recorderRef = useRef<BrowserPcmRecorder | null>(null);
  const flushTimerRef = useRef<number | null>(null);
  const transcriptRef = useRef("");
  const [phase, setPhase] = useState<Phase>("idle");
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [transcript, setTranscript] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [level, setLevel] = useState(0);

  useEffect(() => {
    transcriptRef.current = transcript;
  }, [transcript]);

  useEffect(() => {
    return () => {
      if (flushTimerRef.current) {
        window.clearInterval(flushTimerRef.current);
      }
      void recorderRef.current?.stop();
    };
  }, []);

  async function ensureSession() {
    if (sessionId) return sessionId;

    const session = await createSession(supabase, {
      activityId: activity.id,
      mode: "passive",
    });
    setSessionId(session.id);
    return session.id;
  }

  async function flushPendingAudio(force = false) {
    const recorder = recorderRef.current;
    if (!recorder) return;

    const pcm = recorder.consume();
    if (pcm.length < 3200 && !force) {
      return;
    }

    const activeSessionId = await ensureSession();
    setPhase((current) => (current === "finishing" ? current : "processing"));

    const response = await callAuthorizedFunction("whisperProxy", "POST", {
      headers: {
        "Content-Type": "audio/wav",
      },
      body: wrapPcmAsWav(pcm),
    });

    const payload = (await response.json()) as { transcript?: string };
    const nextSegment = payload.transcript?.trim();

    if (!nextSegment) {
      setPhase("recording");
      return;
    }

    const nextTranscript = [transcriptRef.current, nextSegment]
      .filter(Boolean)
      .join("\n");
    setTranscript(nextTranscript);

    await updateSession(supabase, activeSessionId, {
      transcript: nextTranscript,
      updated_at: new Date().toISOString(),
    });

    await callFunction("processTranscript", {
      transcript: nextSegment,
      activityContext: `${activity.title} ${activity.description ?? ""}`.trim(),
      sessionId: activeSessionId,
    });

    setPhase("recording");
  }

  async function startListening() {
    if (!supportsBrowserRecording()) {
      setPhase("error");
      setError("This browser does not support microphone recording.");
      return;
    }

    setError(null);
    setPhase("starting");

    try {
      await ensureSession();
      const recorder = new BrowserPcmRecorder({
        onLevel(nextLevel) {
          setLevel(nextLevel);
        },
      });

      await recorder.start();
      recorderRef.current = recorder;

      flushTimerRef.current = window.setInterval(() => {
        void flushPendingAudio();
      }, 7000);

      setPhase("recording");
    } catch (startError) {
      setPhase("error");
      setError(
        startError instanceof Error
          ? startError.message
          : "Failed to start listening.",
      );
    }
  }

  async function finishSession() {
    if (!sessionId) return;

    setPhase("finishing");

    try {
      if (flushTimerRef.current) {
        window.clearInterval(flushTimerRef.current);
      }

      await flushPendingAudio(true);
      await recorderRef.current?.stop();
      await endSession(supabase, sessionId);
      router.push(`/session/${activity.id}/summary?sessionId=${sessionId}`);
      router.refresh();
    } catch (finishError) {
      setPhase("error");
      setError(
        finishError instanceof Error
          ? finishError.message
          : "Failed to end passive session.",
      );
    }
  }

  return (
    <SessionShell
      eyebrow="Passive Listen"
      title="Ambient field capture"
      description="Record a browser microphone feed, push chunks through the existing Whisper proxy, and watch AI events stream into Supabase."
      activity={activity}
      status={phase}
    >
      <div className="grid gap-5 lg:grid-cols-[1.05fr_0.95fr]">
        <div className="space-y-5">
          <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h3 className="text-2xl font-semibold text-white">Microphone</h3>
                <p className="mt-2 text-sm leading-6 text-stone-300">
                  Start capture to create a new passive session. Transcript chunks are processed every few seconds.
                </p>
              </div>
              <div className="text-right">
                <p className="text-xs uppercase tracking-[0.3em] text-stone-500">
                  Input level
                </p>
                <p className="mt-2 font-mono text-2xl text-white">
                  {level.toFixed(2)}
                </p>
              </div>
            </div>

            <div className="mt-6 flex flex-wrap gap-3">
              <button
                type="button"
                onClick={() => void startListening()}
                disabled={phase === "recording" || phase === "starting"}
                className="rounded-full bg-amber-300 px-5 py-3 text-sm font-semibold uppercase tracking-[0.25em] text-slate-950 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {phase === "recording" ? "Listening" : "Start"}
              </button>
              <button
                type="button"
                onClick={() => void finishSession()}
                disabled={!sessionId || phase === "starting" || phase === "finishing"}
                className="rounded-full border border-white/10 px-5 py-3 text-sm uppercase tracking-[0.25em] text-stone-100 disabled:cursor-not-allowed disabled:opacity-60"
              >
                End session
              </button>
            </div>

            {error ? (
              <div className="mt-4 rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
                {error}
              </div>
            ) : null}
          </div>

          <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
            <h3 className="text-2xl font-semibold text-white">Transcript</h3>
            <p className="mt-2 text-sm leading-6 text-stone-400">
              New transcript segments are appended here as the Whisper proxy returns them.
            </p>
            <pre className="mt-6 min-h-72 whitespace-pre-wrap rounded-[24px] bg-slate-950/40 p-5 font-mono text-sm leading-7 text-stone-200">
              {transcript || "Waiting for microphone input…"}
            </pre>
          </div>
        </div>

        <EventFeed sessionId={sessionId} />
      </div>
    </SessionShell>
  );
}
