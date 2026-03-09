"use client";

import { env } from "@/lib/env";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";

type HttpMethod = "GET" | "POST";
type AuthorizedOptions = {
  headers?: Record<string, string>;
  body?: BodyInit;
};

export async function callFunction<T>(
  functionName: string,
  data?: Record<string, unknown>,
) {
  const supabase = getSupabaseBrowserClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();

  const response = await fetch(`${env.firebaseFunctionsUrl}/${functionName}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      data: {
        ...(data ?? {}),
        ...(session?.access_token
          ? { accessToken: session.access_token }
          : {}),
      },
    }),
  });

  const payload = await response.json().catch(() => null);

  if (!response.ok) {
    const message =
      payload?.error?.message ||
      payload?.error ||
      `Function ${functionName} failed with ${response.status}`;
    throw new Error(message);
  }

  return normalizeCallablePayload<T>(payload);
}

export async function callAuthorizedFunction(
  functionName: string,
  method: HttpMethod,
  options: AuthorizedOptions = {},
) {
  const supabase = getSupabaseBrowserClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();

  if (!session?.access_token) {
    throw new Error("You must be signed in to call this endpoint.");
  }

  const response = await fetch(`${env.firebaseFunctionsUrl}/${functionName}`, {
    method,
    headers: {
      Authorization: `Bearer ${session.access_token}`,
      ...options.headers,
    },
    body: options.body,
  });

  if (!response.ok) {
    const payload = await response.json().catch(() => null);
    throw new Error(
      payload?.error || `Authorized function ${functionName} failed`,
    );
  }

  return response;
}

function normalizeCallablePayload<T>(payload: unknown) {
  if (payload && typeof payload === "object") {
    if ("result" in payload) {
      return (payload as { result: T }).result;
    }

    if ("data" in payload) {
      return (payload as { data: T }).data;
    }
  }

  return payload as T;
}
