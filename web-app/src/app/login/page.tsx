import { redirect } from "next/navigation";
import { AuthPanel } from "@/components/auth/auth-panel";
import { getOptionalUser } from "@/lib/auth";

export default async function LoginPage() {
  const { user } = await getOptionalUser();

  if (user) {
    redirect("/dashboard");
  }

  return <AuthPanel />;
}
