import { MediaSessionClient } from "@/components/session/media-session-client";
import { requireUser } from "@/lib/auth";
import { getActivity } from "@/lib/data";

export default async function MediaSessionPage({
  params,
}: {
  params: Promise<{ activityId: string }>;
}) {
  const { activityId } = await params;
  const { supabase } = await requireUser();
  const activity = await getActivity(supabase, activityId);

  return <MediaSessionClient activity={activity} />;
}
