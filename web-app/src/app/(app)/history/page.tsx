import { HistoryClient } from "@/components/history/history-client";
import { requireUser } from "@/lib/auth";
import { getSessionHistory } from "@/lib/data";

export default async function HistoryPage() {
  const { supabase, user } = await requireUser();
  const sessions = await getSessionHistory(supabase, user.id);

  return <HistoryClient initialSessions={sessions} />;
}
