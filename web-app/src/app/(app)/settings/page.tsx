import { SettingsClient } from "@/components/settings/settings-client";
import { requireUser } from "@/lib/auth";
import { getSettings } from "@/lib/data";

export default async function SettingsPage() {
  const { supabase, user } = await requireUser();
  const settings = await getSettings(supabase, user.id);
  const userName =
    typeof user.user_metadata?.name === "string"
      ? user.user_metadata.name
      : user.email?.split("@")[0] ?? "Operator";

  return (
    <SettingsClient
      initialSettings={settings}
      userName={userName}
      email={user.email ?? ""}
    />
  );
}
