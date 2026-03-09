import { PassiveSessionClient } from "@/components/session/passive-session-client";
import { requireUser } from "@/lib/auth";
import { getActivity } from "@/lib/data";

export default async function PassiveSessionPage({
  params,
}: {
  params: Promise<{ activityId: string }>;
}) {
  const { activityId } = await params;
  const { supabase } = await requireUser();
  const activity = await getActivity(supabase, activityId);

  return <PassiveSessionClient activity={activity} />;
}
