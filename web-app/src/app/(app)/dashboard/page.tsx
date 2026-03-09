import { DashboardClient } from "@/components/dashboard/dashboard-client";
import { requireUser } from "@/lib/auth";
import { getActivities } from "@/lib/data";

export default async function DashboardPage() {
  const { supabase, user } = await requireUser();
  const activities = await getActivities(supabase);
  const operatorName =
    typeof user.user_metadata?.name === "string"
      ? user.user_metadata.name
      : user.email?.split("@")[0] ?? "Operator";

  return (
    <DashboardClient initialActivities={activities} operatorName={operatorName} />
  );
}
