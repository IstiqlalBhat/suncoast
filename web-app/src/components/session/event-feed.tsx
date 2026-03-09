"use client";

import { useEffect, useState } from "react";
import { formatDate } from "@/lib/date";
import { getSessionEvents } from "@/lib/data";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";
import type { AiEvent } from "@/lib/types";

type EventFeedProps = {
  sessionId: string | null;
  initialEvents?: AiEvent[];
};

export function EventFeed({ sessionId, initialEvents = [] }: EventFeedProps) {
  const supabase = getSupabaseBrowserClient();
  const [events, setEvents] = useState<AiEvent[]>(initialEvents);

  useEffect(() => {
    if (!sessionId) {
      return;
    }

    let cancelled = false;
    const activeSessionId = sessionId;

    async function load() {
      const latest = await getSessionEvents(supabase, activeSessionId);
      if (!cancelled) {
        setEvents(latest);
      }
    }

    void load();

    const channel = supabase
      .channel(`ai-events-${sessionId}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "ai_events",
          filter: `session_id=eq.${activeSessionId}`,
        },
        () => {
          void load();
        },
      )
      .subscribe();

    return () => {
      cancelled = true;
      void supabase.removeChannel(channel);
    };
  }, [sessionId, supabase]);

  const visibleEvents = sessionId ? events : [];

  return (
    <div className="rounded-[24px] border border-white/10 bg-white/4 p-5">
      <div className="flex items-center justify-between">
        <h3 className="text-xl font-semibold text-white">AI event feed</h3>
        <span className="text-xs uppercase tracking-[0.28em] text-stone-400">
          {visibleEvents.length} event{visibleEvents.length === 1 ? "" : "s"}
        </span>
      </div>

      {visibleEvents.length === 0 ? (
        <p className="mt-4 text-sm leading-6 text-stone-400">
          Session events will appear here as transcript processing, image analysis, or agent tools write to Supabase.
        </p>
      ) : (
        <div className="mt-4 space-y-3">
          {visibleEvents.map((event) => (
            <div
              key={event.id}
              className="rounded-[20px] border border-white/10 bg-slate-950/35 p-4"
            >
              <div className="flex flex-wrap gap-2">
                <span className="rounded-full border border-sky-400/20 bg-sky-400/10 px-3 py-1 text-xs uppercase tracking-[0.25em] text-sky-100">
                  {event.type}
                </span>
                <span className="rounded-full border border-white/10 bg-white/8 px-3 py-1 text-xs uppercase tracking-[0.25em] text-stone-200">
                  {event.status}
                </span>
              </div>
              <p className="mt-3 text-sm leading-6 text-stone-200">{event.content}</p>
              <div className="mt-3 flex flex-wrap gap-3 text-xs uppercase tracking-[0.22em] text-stone-500">
                <span>{formatDate(event.created_at)}</span>
                {event.external_record_url ? <span>External link</span> : null}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
