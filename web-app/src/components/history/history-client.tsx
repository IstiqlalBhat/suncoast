"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { EmptyState } from "@/components/empty-state";
import { PageHeading } from "@/components/page-heading";
import { StatusBadge } from "@/components/status-badge";
import { deleteSession } from "@/lib/data";
import { formatDate, formatDurationFromRange } from "@/lib/date";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";
import type { SessionRecord } from "@/lib/types";

type HistoryClientProps = {
  initialSessions: SessionRecord[];
};

export function HistoryClient({ initialSessions }: HistoryClientProps) {
  const supabase = getSupabaseBrowserClient();
  const [sessions, setSessions] = useState(initialSessions);
  const [error, setError] = useState<string | null>(null);

  const stats = useMemo(
    () => ({
      total: sessions.length,
      active: sessions.filter((session) => session.ended_at === null).length,
    }),
    [sessions],
  );

  async function handleDelete(sessionId: string) {
    const confirmed = window.confirm(
      "Delete this session and all related events, media, and summary records?",
    );

    if (!confirmed) return;

    try {
      await deleteSession(supabase, sessionId);
      setSessions((previous) =>
        previous.filter((session) => session.id !== sessionId),
      );
    } catch (deleteError) {
      setError(
        deleteError instanceof Error
          ? deleteError.message
          : "Failed to delete session.",
      );
    }
  }

  return (
    <div className="space-y-8">
      <PageHeading
        eyebrow="History"
        title="Session archive"
        description={`Review ${stats.total} captured sessions, reopen summaries, and remove stale runs when needed. ${stats.active} session${stats.active === 1 ? "" : "s"} still appear active.`}
      />

      {error ? (
        <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
          {error}
        </div>
      ) : null}

      {sessions.length === 0 ? (
        <EmptyState
          title="No sessions yet"
          description="Start an activity from the operations dashboard to create the first passive, chat, or media session."
        />
      ) : (
        <div className="space-y-3">
          {sessions.map((session) => (
            <div
              key={session.id}
              className="rounded-[24px] border border-white/10 bg-white/4 p-5"
            >
              <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                <div>
                  <div className="flex flex-wrap gap-2">
                    <StatusBadge label={session.mode} tone="accent" />
                    <StatusBadge
                      label={session.ended_at ? "complete" : "active"}
                      tone={session.ended_at ? "success" : "warning"}
                    />
                  </div>
                  <h3 className="mt-4 text-2xl font-semibold text-white">
                    {session.activities?.title || "Session"}
                  </h3>
                  <div className="mt-3 flex flex-wrap gap-4 text-sm text-stone-400">
                    <span>{formatDate(session.started_at)}</span>
                    <span>{formatDurationFromRange(session.started_at, session.ended_at)}</span>
                  </div>
                </div>

                <div className="flex flex-wrap gap-3">
                  <Link
                    href={`/session/${session.activity_id}/summary?sessionId=${session.id}`}
                    className="rounded-full border border-white/10 px-4 py-2 text-sm text-stone-100 transition hover:bg-white/10"
                  >
                    Open summary
                  </Link>
                  <button
                    type="button"
                    onClick={() => handleDelete(session.id)}
                    className="rounded-full border border-rose-400/20 bg-rose-400/10 px-4 py-2 text-sm text-rose-100 transition hover:bg-rose-400/20"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
