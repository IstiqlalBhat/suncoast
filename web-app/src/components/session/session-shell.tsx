import Link from "next/link";
import { PageHeading } from "@/components/page-heading";
import { StatusBadge } from "@/components/status-badge";
import type { Activity } from "@/lib/types";

type SessionShellProps = {
  eyebrow: string;
  title: string;
  description: string;
  activity: Activity;
  status: string;
  children: React.ReactNode;
};

export function SessionShell({
  eyebrow,
  title,
  description,
  activity,
  status,
  children,
}: SessionShellProps) {
  return (
    <div className="space-y-8">
      <PageHeading
        eyebrow={eyebrow}
        title={title}
        description={description}
        actions={
          <Link
            href="/dashboard"
            className="rounded-full border border-white/10 px-4 py-2 text-sm text-stone-100 transition hover:bg-white/10"
          >
            Back to operations
          </Link>
        }
      />

      <div className="flex flex-wrap gap-3 rounded-[24px] border border-white/10 bg-white/4 p-4 text-sm text-stone-200">
        <StatusBadge label={activity.type === "twoway" ? "chat" : activity.type} tone="accent" />
        <StatusBadge label={status} tone="warning" />
        <span>{activity.title}</span>
        {activity.location ? <span>{activity.location}</span> : null}
      </div>

      {children}
    </div>
  );
}
