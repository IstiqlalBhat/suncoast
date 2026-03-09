import { redirect } from "next/navigation";
import { SummaryClient } from "@/components/session/summary-client";
import { requireUser } from "@/lib/auth";
import { getActivity, getSessionSummary } from "@/lib/data";
import { generateSummaryServer } from "@/lib/server-functions";

export default async function SummaryPage({
  params,
  searchParams,
}: {
  params: Promise<{ activityId: string }>;
  searchParams: Promise<{ sessionId?: string }>;
}) {
  const { activityId } = await params;
  const { sessionId } = await searchParams;

  if (!sessionId) {
    redirect("/history");
  }

  const { supabase } = await requireUser();
  const activity = await getActivity(supabase, activityId);
  const summary =
    (await getSessionSummary(supabase, sessionId)) ??
    (await generateSummaryServer(sessionId));

  return (
    <SummaryClient
      activity={activity}
      sessionId={sessionId}
      initialSummary={summary}
    />
  );
}
