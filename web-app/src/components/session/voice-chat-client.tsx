"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { EventFeed } from "@/components/session/event-feed";
import { SessionShell } from "@/components/session/session-shell";
import { BrowserPcmRecorder } from "@/lib/audio/browser-recorder";
import { uint8ArrayToBase64, mergeUint8Arrays } from "@/lib/audio/pcm";
import { wrapPcmAsWav } from "@/lib/audio/wav";
import { supportsLiveVoiceChat } from "@/lib/browser-capabilities";
import { callAuthorizedFunction, callFunction } from "@/lib/firebase-functions";
import {
  createSession,
  endSession,
  updateSession,
} from "@/lib/data";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";
import type { Activity } from "@/lib/types";

type VoiceChatClientProps = {
  activity: Activity;
};

type VoicePhase = "idle" | "connecting" | "connected" | "unsupported" | "finishing" | "error";

type TranscriptLine = {
  speaker: "user" | "agent";
  text: string;
};

export function VoiceChatClient({ activity }: VoiceChatClientProps) {
  const router = useRouter();
  const supabase = getSupabaseBrowserClient();
  const recorderRef = useRef<BrowserPcmRecorder | null>(null);
  const socketRef = useRef<WebSocket | null>(null);
  const transcriptRef = useRef("");
  const sessionIdRef = useRef<string | null>(null);
  const audioBufferRef = useRef<Uint8Array[]>([]);
  const audioTimerRef = useRef<number | null>(null);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [phase, setPhase] = useState<VoicePhase>(
    supportsLiveVoiceChat() ? "idle" : "unsupported",
  );
  const [lines, setLines] = useState<TranscriptLine[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [agentSpeaking, setAgentSpeaking] = useState(false);
  const [sampleRate, setSampleRate] = useState(16000);

  useEffect(() => {
    return () => {
      if (audioTimerRef.current) {
        window.clearTimeout(audioTimerRef.current);
      }
      void recorderRef.current?.stop();
      socketRef.current?.close();
    };
  }, []);

  async function ensureSession() {
    if (sessionId) return sessionId;

    const session = await createSession(supabase, {
      activityId: activity.id,
      mode: "chat",
    });
    await callFunction("syncActivityStatus", {
      sessionId: session.id,
      status: "in_progress",
    });
    setSessionId(session.id);
    sessionIdRef.current = session.id;
    return session.id;
  }

  async function appendTranscriptLine(line: TranscriptLine) {
    setLines((previous) => [...previous, line]);

    const nextTranscript = `${transcriptRef.current}\n${line.speaker}: ${line.text}`.trim();
    transcriptRef.current = nextTranscript;

    if (sessionIdRef.current) {
      await updateSession(supabase, sessionIdRef.current, {
        transcript: nextTranscript,
        updated_at: new Date().toISOString(),
      });
    }
  }

  async function flushAudioPlayback() {
    if (audioBufferRef.current.length === 0) return;

    const merged = mergeUint8Arrays(audioBufferRef.current);
    audioBufferRef.current = [];
    const audioUrl = URL.createObjectURL(wrapPcmAsWav(merged, sampleRate));
    const audio = new Audio(audioUrl);
    audio.onended = () => {
      setAgentSpeaking(false);
      URL.revokeObjectURL(audioUrl);
    };
    setAgentSpeaking(true);
    await audio.play().catch(() => {
      setAgentSpeaking(false);
      URL.revokeObjectURL(audioUrl);
    });
  }

  async function connect() {
    if (!supportsLiveVoiceChat()) {
      setPhase("unsupported");
      return;
    }

    setError(null);
    setPhase("connecting");

    try {
      const activeSessionId = await ensureSession();
      const response = await callAuthorizedFunction(
        "getSignedConversationUrl",
        "GET",
      );
      const { signed_url } = (await response.json()) as { signed_url: string };

      const socket = new WebSocket(signed_url);
      socketRef.current = socket;

      socket.onopen = async () => {
        socket.send(
          JSON.stringify({
            type: "conversation_initiation_client_data",
            conversation_config_override: {
              agent: {
                prompt: {},
                first_message: null,
                language: "en",
              },
            },
            dynamic_variables: {
              session_id: activeSessionId,
              activity_context: `${activity.title} ${activity.description ?? ""}`.trim(),
            },
          }),
        );

        const recorder = new BrowserPcmRecorder({
          onChunk(chunk) {
            if (socket.readyState === WebSocket.OPEN) {
              socket.send(
                JSON.stringify({
                  user_audio_chunk: uint8ArrayToBase64(chunk),
                }),
              );
            }
          },
        });

        await recorder.start();
        recorderRef.current = recorder;
        setPhase("connected");
      };

      socket.onmessage = (event) => {
        const payload = JSON.parse(event.data as string) as Record<string, unknown>;
        const type = payload.type as string | undefined;

        switch (type) {
          case "conversation_initiation_metadata": {
            const metadata = payload.conversation_initiation_metadata_event as
              | { agent_output_audio_format?: string }
              | undefined;
            const format = metadata?.agent_output_audio_format;
            const detectedRate = format?.match(/(\d{4,6})/)?.[1];
            if (detectedRate) {
              setSampleRate(Number(detectedRate));
            }
            break;
          }
          case "audio": {
            const audioEvent = payload.audio_event as
              | { audio_base_64?: string }
              | undefined;
            if (audioEvent?.audio_base_64) {
              audioBufferRef.current.push(
                Uint8Array.from(atob(audioEvent.audio_base_64), (char) =>
                  char.charCodeAt(0),
                ),
              );

              if (audioTimerRef.current) {
                window.clearTimeout(audioTimerRef.current);
              }

              audioTimerRef.current = window.setTimeout(() => {
                void flushAudioPlayback();
              }, 220);
            }
            break;
          }
          case "user_transcript": {
            const transcriptEvent = payload.user_transcription_event as
              | { user_transcript?: string }
              | undefined;
            if (transcriptEvent?.user_transcript?.trim()) {
              void appendTranscriptLine({
                speaker: "user",
                text: transcriptEvent.user_transcript.trim(),
              });
            }
            break;
          }
          case "agent_response": {
            const agentEvent = payload.agent_response_event as
              | { agent_response?: string }
              | undefined;
            if (agentEvent?.agent_response?.trim()) {
              void appendTranscriptLine({
                speaker: "agent",
                text: agentEvent.agent_response.trim(),
              });
            }
            void flushAudioPlayback();
            break;
          }
          case "ping": {
            const pingEvent = payload.ping_event as { event_id?: string } | undefined;
            if (pingEvent?.event_id) {
              socket.send(
                JSON.stringify({ type: "pong", event_id: pingEvent.event_id }),
              );
            }
            break;
          }
          case "interruption": {
            audioBufferRef.current = [];
            setAgentSpeaking(false);
            break;
          }
          default:
            break;
        }
      };

      socket.onerror = () => {
        setPhase("error");
        setError("Voice chat connection failed.");
      };

      socket.onclose = () => {
        setPhase((current) => (current === "finishing" ? current : "idle"));
      };
    } catch (connectError) {
      setPhase("error");
      setError(
        connectError instanceof Error
          ? connectError.message
          : "Failed to connect to voice chat.",
      );
    }
  }

  async function finish() {
    if (!sessionId) return;

    setPhase("finishing");

    try {
      socketRef.current?.close();
      await recorderRef.current?.stop();
      await endSession(supabase, sessionId);
      await callFunction("syncActivityStatus", {
        sessionId,
        status: "completed",
      });
      router.push(`/session/${activity.id}/summary?sessionId=${sessionId}`);
      router.refresh();
    } catch (finishError) {
      setPhase("error");
      setError(
        finishError instanceof Error
          ? finishError.message
          : "Failed to end voice session.",
      );
    }
  }

  return (
    <SessionShell
      eyebrow="Voice Chat"
      title="Live conversational session"
      description="Connect the browser microphone to ElevenLabs through the existing signed URL flow. Transcripts persist back into the shared session record."
      activity={activity}
      status={phase}
    >
      <div className="grid gap-5 lg:grid-cols-[1.05fr_0.95fr]">
        <div className="space-y-5">
          <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <h3 className="text-2xl font-semibold text-white">Connection</h3>
                <p className="mt-2 text-sm leading-6 text-stone-300">
                  Browser-native audio capture with direct WebSocket streaming to ElevenLabs.
                </p>
              </div>
              <div className="text-sm text-stone-300">
                Agent speaking: {agentSpeaking ? "yes" : "no"}
              </div>
            </div>

            <div className="mt-6 flex flex-wrap gap-3">
              <button
                type="button"
                onClick={() => void connect()}
                disabled={phase === "connected" || phase === "connecting" || phase === "unsupported"}
                className="rounded-full bg-amber-300 px-5 py-3 text-sm font-semibold uppercase tracking-[0.25em] text-slate-950 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {phase === "connected" ? "Connected" : "Connect"}
              </button>
              <button
                type="button"
                onClick={() => void finish()}
                disabled={!sessionId || phase === "connecting" || phase === "unsupported"}
                className="rounded-full border border-white/10 px-5 py-3 text-sm uppercase tracking-[0.25em] text-stone-100 disabled:cursor-not-allowed disabled:opacity-60"
              >
                End session
              </button>
            </div>

            {phase === "unsupported" ? (
              <div className="mt-4 rounded-2xl border border-amber-300/20 bg-amber-300/10 px-4 py-3 text-sm text-amber-100">
                This browser does not support the microphone, WebSocket, or AudioContext stack required for live voice chat.
              </div>
            ) : null}

            {error ? (
              <div className="mt-4 rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
                {error}
              </div>
            ) : null}
          </div>

          <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
            <h3 className="text-2xl font-semibold text-white">Transcript stream</h3>
            <div className="mt-5 space-y-3">
              {lines.length === 0 ? (
                <p className="rounded-[20px] bg-slate-950/40 p-4 text-sm text-stone-400">
                  Connect to the session to begin receiving user and agent transcript events.
                </p>
              ) : (
                lines.map((line, index) => (
                  <div
                    key={`${line.speaker}-${index}`}
                    className={`rounded-[22px] p-4 text-sm leading-6 ${
                      line.speaker === "agent"
                        ? "bg-amber-300/12 text-amber-50"
                        : "bg-slate-950/45 text-stone-100"
                    }`}
                  >
                    <p className="mb-2 text-xs uppercase tracking-[0.3em] text-stone-400">
                      {line.speaker}
                    </p>
                    <p>{line.text}</p>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        <EventFeed sessionId={sessionId} />
      </div>
    </SessionShell>
  );
}
