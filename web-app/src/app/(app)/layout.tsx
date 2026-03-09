import { AppShell } from "@/components/app-shell";
import { requireUser } from "@/lib/auth";

export default async function ProtectedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user } = await requireUser();
  const userName =
    typeof user.user_metadata?.name === "string"
      ? user.user_metadata.name
      : user.email?.split("@")[0] ?? "Operator";

  return (
    <AppShell userName={userName} userEmail={user.email ?? ""}>
      {children}
    </AppShell>
  );
}
