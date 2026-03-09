import { env } from "@/lib/env";
import type { SessionSummary } from "@/lib/types";

export async function generateSummaryServer(
  sessionId: string,
  accessToken: string,
): Promise<SessionSummary | null> {
  const response = await fetch(`${env.firebaseFunctionsUrl}/generateSummary`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      data: { sessionId, accessToken },
    }),
    cache: "no-store",
  });

  const payload = (await response.json().catch(() => null)) as
    | {
        result?: { summary?: SessionSummary };
        data?: { summary?: SessionSummary };
      }
    | null;

  if (!response.ok) {
    throw new Error("Failed to generate summary on the server.");
  }

  if (payload?.result?.summary) {
    return payload.result.summary;
  }

  if (payload?.data?.summary) {
    return payload.data.summary;
  }

  return null;
}
