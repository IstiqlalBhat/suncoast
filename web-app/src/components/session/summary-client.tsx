"use client";

import { useEffect, useState } from "react";
import { PageHeading } from "@/components/page-heading";
import { StatusBadge } from "@/components/status-badge";
import { callFunction } from "@/lib/firebase-functions";
import { formatDurationSeconds } from "@/lib/date";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";
import type { Activity, SessionSummary } from "@/lib/types";

type SummaryClientProps = {
  activity: Activity;
  sessionId: string;
  initialSummary: SessionSummary | null;
};

export function SummaryClient({
  activity,
  sessionId,
  initialSummary,
}: SummaryClientProps) {
  const supabase = getSupabaseBrowserClient();
  const [summary, setSummary] = useState<SessionSummary | null>(initialSummary);
  const [isGenerating, setIsGenerating] = useState(!initialSummary);
  const [isConfirming, setIsConfirming] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (initialSummary) return;

    let cancelled = false;

    async function generate() {
      setIsGenerating(true);
      setError(null);

      try {
        const response = await callFunction<{ summary?: SessionSummary }>(
          "generateSummary",
          { sessionId },
        );

        if (!cancelled) {
          setSummary(response.summary ?? null);
        }
      } catch (generationError) {
        if (!cancelled) {
          setError(
            generationError instanceof Error
              ? generationError.message
              : "Failed to generate summary.",
          );
        }
      } finally {
        if (!cancelled) {
          setIsGenerating(false);
        }
      }
    }

    void generate();

    return () => {
      cancelled = true;
    };
  }, [initialSummary, sessionId]);

  async function confirmSummary() {
    setIsConfirming(true);
    setError(null);

    try {
      const { data, error: updateError } = await supabase
        .from("session_summaries")
        .update({
          confirmed_at: new Date().toISOString(),
        })
        .eq("session_id", sessionId)
        .select("*")
        .limit(1);

      if (updateError) {
        throw updateError;
      }

      const nextSummary = (data?.[0] as SessionSummary | undefined) ?? null;

      if (!nextSummary) {
        throw new Error("Summary confirmation did not return an updated row.");
      }

      setSummary(nextSummary);
    } catch (confirmError) {
      setError(
        confirmError instanceof Error
          ? confirmError.message
          : "Failed to confirm summary.",
      );
    } finally {
      setIsConfirming(false);
    }
  }

  return (
    <div className="space-y-8">
      <PageHeading
        eyebrow="Summary"
        title={activity.title}
        description="This is the shared session summary flow. It reads the same `session_summaries` records as mobile and generates on demand if the row does not exist yet."
        actions={
          <button
            type="button"
            onClick={() => void confirmSummary()}
            disabled={!summary || isGenerating || isConfirming}
            className="rounded-full bg-amber-300 px-5 py-3 text-sm font-semibold uppercase tracking-[0.25em] text-slate-950 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {summary?.confirmed_at ? "Confirmed" : isConfirming ? "Saving..." : "Confirm summary"}
          </button>
        }
      />

      {error ? (
        <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
          {error}
        </div>
      ) : null}

      {isGenerating ? (
        <div className="rounded-[28px] border border-white/10 bg-white/4 px-6 py-16 text-center text-stone-300">
          Generating session summary...
        </div>
      ) : null}

      {!isGenerating && !summary ? (
        <div className="rounded-[28px] border border-dashed border-white/15 bg-white/4 px-6 py-16 text-center text-stone-300">
          No summary is available for this session.
        </div>
      ) : null}

      {summary ? (
        <div className="grid gap-5 lg:grid-cols-[1.1fr_0.9fr]">
          <section className="space-y-5">
            <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
              <div className="flex flex-wrap gap-2">
                <StatusBadge label={activity.type === "twoway" ? "chat" : activity.type} tone="accent" />
                <StatusBadge
                  label={summary.confirmed_at ? "confirmed" : "pending review"}
                  tone={summary.confirmed_at ? "success" : "warning"}
                />
              </div>
              <h3 className="mt-5 text-2xl font-semibold text-white">
                Observation summary
              </h3>
              <p className="mt-4 text-sm leading-7 text-stone-200">
                {summary.observation_summary || "No observation summary generated."}
              </p>
            </div>

            <ListCard
              title="Key observations"
              items={summary.key_observations}
              empty="No key observations available."
            />
            <ListCard
              title="Actions taken"
              items={
                summary.action_statuses.length > 0
                  ? summary.action_statuses.map(
                      (item) => `${item.label} (${item.status})`,
                    )
                  : summary.actions_taken
              }
              empty="No actions were recorded."
            />
            <ListCard
              title="Follow-ups"
              items={summary.follow_ups.map(
                (item) =>
                  `${item.description} [${item.priority}]${
                    item.due_date ? ` due ${item.due_date}` : ""
                  }`,
              )}
              empty="No follow-up items."
            />
          </section>

          <aside className="space-y-5">
            <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
              <p className="text-xs font-semibold uppercase tracking-[0.3em] text-stone-400">
                Duration
              </p>
              <p className="mt-4 text-4xl font-semibold text-white">
                {formatDurationSeconds(summary.duration_seconds)}
              </p>
            </div>
            <ListCard
              title="External records"
              items={summary.external_records.map((record) =>
                record.url ? `${record.label} - ${record.url}` : record.label,
              )}
              empty="No external records linked."
            />
          </aside>
        </div>
      ) : null}
    </div>
  );
}

type ListCardProps = {
  title: string;
  items: string[];
  empty: string;
};

function ListCard({ title, items, empty }: ListCardProps) {
  return (
    <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
      <h3 className="text-2xl font-semibold text-white">{title}</h3>
      {items.length === 0 ? (
        <p className="mt-4 text-sm leading-6 text-stone-400">{empty}</p>
      ) : (
        <ul className="mt-4 space-y-3">
          {items.map((item) => (
            <li
              key={`${title}-${item}`}
              className="rounded-[20px] bg-slate-950/40 px-4 py-3 text-sm leading-6 text-stone-200"
            >
              {item}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
