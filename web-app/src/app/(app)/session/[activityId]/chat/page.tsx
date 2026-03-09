import { VoiceChatClient } from "@/components/session/voice-chat-client";
import { requireUser } from "@/lib/auth";
import { getActivity } from "@/lib/data";

export default async function VoiceChatPage({
  params,
}: {
  params: Promise<{ activityId: string }>;
}) {
  const { activityId } = await params;
  const { supabase } = await requireUser();
  const activity = await getActivity(supabase, activityId);

  return <VoiceChatClient activity={activity} />;
}
