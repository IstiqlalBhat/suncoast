"use client";

import { useMemo, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { EmptyState } from "@/components/empty-state";
import { MetricCard } from "@/components/metric-card";
import { PageHeading } from "@/components/page-heading";
import { StatusBadge } from "@/components/status-badge";
import {
  createActivity,
  deleteActivity,
  getActivity,
  getActivities,
  getLatestCompletedSessionForActivity,
  updateActivityStatus,
} from "@/lib/data";
import { formatDate } from "@/lib/date";
import { routeForActivityType } from "@/lib/routes";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";
import type { Activity, ActivityType } from "@/lib/types";

type DashboardClientProps = {
  initialActivities: Activity[];
  operatorName: string;
};

type FilterValue = ActivityType | "all";

const filterOptions: Array<{ label: string; value: FilterValue }> = [
  { label: "All", value: "all" },
  { label: "Passive", value: "passive" },
  { label: "Chat", value: "twoway" },
  { label: "Media", value: "media" },
];

export function DashboardClient({
  initialActivities,
  operatorName,
}: DashboardClientProps) {
  const router = useRouter();
  const supabase = getSupabaseBrowserClient();
  const [activities, setActivities] = useState(initialActivities);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<FilterValue>("all");
  const [showForm, setShowForm] = useState(false);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [location, setLocation] = useState("");
  const [newType, setNewType] = useState<ActivityType>("passive");
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const stats = useMemo(() => {
    const pending = activities.filter((activity) => activity.status === "pending");
    const inProgress = activities.filter(
      (activity) => activity.status === "in_progress",
    );

    return {
      total: String(activities.length),
      pending: String(pending.length),
      active: String(inProgress.length),
    };
  }, [activities]);

  async function refresh(nextSearch = search, nextFilter = filter) {
    try {
      const nextActivities = await getActivities(supabase, {
        search: nextSearch,
        type: nextFilter,
      });
      setActivities(nextActivities);
    } catch (refreshError) {
      setError(
        refreshError instanceof Error
          ? refreshError.message
          : "Failed to refresh activities.",
      );
    }
  }

  function handleSearchChange(value: string) {
    setSearch(value);
    startTransition(() => {
      void refresh(value, filter);
    });
  }

  function handleFilterChange(nextFilter: FilterValue) {
    setFilter(nextFilter);
    startTransition(() => {
      void refresh(search, nextFilter);
    });
  }

  async function handleCreateActivity(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);

    try {
      const activity = await createActivity(supabase, {
        title,
        type: newType,
        description,
        location,
      });

      setShowForm(false);
      setTitle("");
      setDescription("");
      setLocation("");
      setActivities((previous) => [activity, ...previous]);
      router.push(`/session/${activity.id}/${routeForActivityType(activity.type)}`);
      router.refresh();
    } catch (createError) {
      setError(
        createError instanceof Error
          ? createError.message
          : "Failed to create activity.",
      );
    }
  }

  async function handleOpenActivity(activity: Activity) {
    let latestActivity = activity;

    try {
      latestActivity = await getActivity(supabase, activity.id);
    } catch (openError) {
      setError(
        openError instanceof Error
          ? openError.message
          : "Failed to refresh activity state.",
      );
      return;
    }

    try {
      const session = await getLatestCompletedSessionForActivity(
        supabase,
        latestActivity.id,
      );

      if (session) {
        router.push(`/session/${latestActivity.id}/summary?sessionId=${session.id}`);
        return;
      }
    } catch (openError) {
      setError(
        openError instanceof Error
          ? openError.message
          : "Failed to open activity summary.",
      );
      return;
    }

    if (latestActivity.status === "completed") {
      setError("No completed session summary found for this activity.");
      return;
    }

    router.push(
      `/session/${latestActivity.id}/${routeForActivityType(latestActivity.type)}`,
    );
  }

  async function handleDeleteActivity(activityId: string) {
    const confirmed = window.confirm(
      "Delete this activity and all sessions linked to it? This cannot be undone.",
    );
    if (!confirmed) {
      return;
    }

    setError(null);
    setDeletingId(activityId);

    try {
      await deleteActivity(supabase, activityId);
      setActivities((previous) =>
        previous.filter((activity) => activity.id !== activityId),
      );
      router.refresh();
    } catch (deleteError) {
      setError(
        deleteError instanceof Error
          ? deleteError.message
          : "Failed to delete activity.",
      );
    } finally {
      setDeletingId(null);
    }
  }

  async function handleMarkCompleted(activityId: string) {
    const confirmed = window.confirm(
      "Mark this activity as completed? If a finished session exists, opening the activity will go to its summary.",
    );
    if (!confirmed) {
      return;
    }

    setError(null);

    try {
      const updated = await updateActivityStatus(
        supabase,
        activityId,
        "completed",
      );
      setActivities((previous) =>
        previous.map((activity) =>
          activity.id === activityId ? updated : activity,
        ),
      );
      router.refresh();
    } catch (updateError) {
      setError(
        updateError instanceof Error
          ? updateError.message
          : "Failed to mark activity completed.",
      );
    }
  }

  return (
    <div className="space-y-8">
      <PageHeading
        eyebrow="Operations"
        title={`Good shift, ${operatorName}`}
        description="Create a field activity, filter active work, and launch the browser-native session flow that matches the mobile product."
        actions={
          <button
            type="button"
            onClick={() => setShowForm((previous) => !previous)}
            className="rounded-full bg-amber-300 px-5 py-3 text-sm font-semibold uppercase tracking-[0.24em] text-slate-950 transition hover:bg-amber-200"
          >
            {showForm ? "Close panel" : "New activity"}
          </button>
        }
      />

      <section className="grid gap-4 md:grid-cols-3">
        <MetricCard label="Total" value={stats.total} hint="All scheduled and historical activities." />
        <MetricCard label="Pending" value={stats.pending} hint="Work items ready to start." />
        <MetricCard label="Active" value={stats.active} hint="Sessions currently running in the field." />
      </section>

      <section className="grid gap-4 rounded-[28px] border border-white/10 bg-white/4 p-5 lg:grid-cols-[1.15fr_0.85fr]">
        <div>
          <div className="flex flex-col gap-3 md:flex-row md:items-center">
            <input
              value={search}
              onChange={(event) => handleSearchChange(event.target.value)}
              placeholder="Search activities"
              className="w-full rounded-2xl border border-white/10 bg-slate-950/40 px-4 py-3 text-white outline-none transition focus:border-amber-300/50"
            />
            <div className="flex flex-wrap gap-2">
              {filterOptions.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => handleFilterChange(option.value)}
                  className={`rounded-full px-4 py-2 text-sm transition ${
                    filter === option.value
                      ? "bg-amber-300 text-slate-950"
                      : "bg-white/6 text-stone-200 hover:bg-white/10"
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>

          {error ? (
            <div className="mt-4 rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
              {error}
            </div>
          ) : null}

          <div className="mt-6 space-y-3">
            {activities.length === 0 ? (
              <EmptyState
                title="No activities found"
                description="Try adjusting your filters or create a new field activity to start a passive, chat, or media session."
              />
            ) : (
              activities.map((activity) => (
                <article
                  key={activity.id}
                  className="block rounded-[24px] border border-white/10 bg-slate-950/35 p-5 transition hover:border-amber-200/30 hover:bg-white/8"
                >
                  <div className="flex items-start justify-between gap-4">
                    <button
                      type="button"
                      onClick={() => void handleOpenActivity(activity)}
                      className="min-w-0 flex-1 text-left"
                    >
                      <div className="flex flex-wrap gap-2">
                        <StatusBadge
                          label={activity.type === "twoway" ? "chat" : activity.type}
                          tone={activity.type === "media" ? "accent" : "warning"}
                        />
                        <StatusBadge label={activity.status.replace("_", " ")} />
                      </div>
                      <h3 className="mt-4 text-2xl font-semibold text-white">
                        {activity.title}
                      </h3>
                      <p className="mt-2 max-w-2xl text-sm leading-6 text-stone-300">
                        {activity.description || "No description provided yet."}
                      </p>
                    </button>
                    <div className="flex flex-col items-end gap-3 text-sm text-stone-400">
                      <div className="text-right">
                        <p>{activity.location || "No location"}</p>
                        <p className="mt-1">{formatDate(activity.scheduled_at)}</p>
                      </div>
                      {activity.status !== "completed" ? (
                        <button
                          type="button"
                          onClick={() => void handleMarkCompleted(activity.id)}
                          className="rounded-full border border-emerald-400/30 px-3 py-2 text-xs font-semibold uppercase tracking-[0.2em] text-emerald-100 transition hover:bg-emerald-400/10"
                        >
                          Complete
                        </button>
                      ) : null}
                      <button
                        type="button"
                        onClick={() => void handleDeleteActivity(activity.id)}
                        disabled={deletingId === activity.id}
                        className="rounded-full border border-rose-400/30 px-3 py-2 text-xs font-semibold uppercase tracking-[0.2em] text-rose-200 transition hover:bg-rose-400/10 disabled:cursor-not-allowed disabled:opacity-50"
                      >
                        {deletingId === activity.id ? "Deleting" : "Delete"}
                      </button>
                    </div>
                  </div>
                </article>
              ))
            )}
          </div>

          {isPending ? (
            <p className="mt-4 text-sm text-stone-400">Refreshing…</p>
          ) : null}
        </div>

        {showForm ? (
          <form
            onSubmit={handleCreateActivity}
            className="rounded-[24px] border border-white/10 bg-slate-950/60 p-5"
          >
            <h3 className="text-2xl font-semibold text-white">Create activity</h3>
            <p className="mt-2 text-sm leading-6 text-stone-400">
              Start with the same activity types the mobile app supports and jump straight into the matching web session.
            </p>

            <div className="mt-6 space-y-4">
              <label className="block">
                <span className="mb-2 block text-sm text-stone-300">Title</span>
                <input
                  required
                  value={title}
                  onChange={(event) => setTitle(event.target.value)}
                  className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none transition focus:border-amber-300/50"
                />
              </label>

              <label className="block">
                <span className="mb-2 block text-sm text-stone-300">Mode</span>
                <select
                  value={newType}
                  onChange={(event) => setNewType(event.target.value as ActivityType)}
                  className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none transition focus:border-amber-300/50"
                >
                  <option value="passive">Passive Listen</option>
                  <option value="twoway">Voice Chat</option>
                  <option value="media">Media Capture</option>
                </select>
              </label>

              <label className="block">
                <span className="mb-2 block text-sm text-stone-300">Description</span>
                <textarea
                  rows={4}
                  value={description}
                  onChange={(event) => setDescription(event.target.value)}
                  className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none transition focus:border-amber-300/50"
                />
              </label>

              <label className="block">
                <span className="mb-2 block text-sm text-stone-300">Location</span>
                <input
                  value={location}
                  onChange={(event) => setLocation(event.target.value)}
                  className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none transition focus:border-amber-300/50"
                />
              </label>
            </div>

            <button
              type="submit"
              className="mt-6 w-full rounded-full bg-amber-300 px-4 py-3 text-sm font-semibold uppercase tracking-[0.25em] text-slate-950"
            >
              Launch session
            </button>
          </form>
        ) : (
          <div className="rounded-[24px] border border-dashed border-white/10 bg-white/3 p-5">
            <h3 className="text-xl font-semibold text-white">Ready queue</h3>
            <p className="mt-3 text-sm leading-6 text-stone-300">
              Use the create panel to spin up a new activity. Each activity routes directly into the appropriate browser workflow and reuses the live backend records.
            </p>
          </div>
        )}
      </section>
    </div>
  );
}
