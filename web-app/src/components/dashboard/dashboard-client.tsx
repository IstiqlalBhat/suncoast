"use client";

import Link from "next/link";
import { useMemo, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { EmptyState } from "@/components/empty-state";
import { MetricCard } from "@/components/metric-card";
import { PageHeading } from "@/components/page-heading";
import { StatusBadge } from "@/components/status-badge";
import { createActivity, getActivities } from "@/lib/data";
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
                <Link
                  key={activity.id}
                  href={`/session/${activity.id}/${routeForActivityType(activity.type)}`}
                  className="block rounded-[24px] border border-white/10 bg-slate-950/35 p-5 transition hover:border-amber-200/30 hover:bg-white/8"
                >
                  <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                    <div>
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
                    </div>
                    <div className="text-sm text-stone-400">
                      <p>{activity.location || "No location"}</p>
                      <p className="mt-1">{formatDate(activity.scheduled_at)}</p>
                    </div>
                  </div>
                </Link>
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
