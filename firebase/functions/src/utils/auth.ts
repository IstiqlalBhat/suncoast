import { HttpsError } from "firebase-functions/v2/https";
import type { SupabaseClient, User } from "@supabase/supabase-js";

type CallableRequestLike = {
  data?: Record<string, unknown>;
};

export type AuthenticatedCallableData = {
  user: User;
  payload: Record<string, unknown>;
};

export async function authenticateCallableRequest(
  request: CallableRequestLike,
  supabase: SupabaseClient,
): Promise<AuthenticatedCallableData> {
  const payload = request.data && typeof request.data === "object"
    ? { ...request.data }
    : {};
  const accessToken = typeof payload.accessToken === "string"
    ? payload.accessToken
    : null;

  delete payload.accessToken;

  if (!accessToken) {
    throw new HttpsError("unauthenticated", "Supabase access token is required");
  }

  const { data, error } = await supabase.auth.getUser(accessToken);
  if (error || !data.user) {
    throw new HttpsError("unauthenticated", "Invalid Supabase access token");
  }

  return {
    user: data.user,
    payload,
  };
}

export async function authenticateBearerRequest(
  authorizationHeader: string | undefined,
  supabase: SupabaseClient,
): Promise<User> {
  if (!authorizationHeader?.startsWith("Bearer ")) {
    throw new HttpsError("unauthenticated", "Missing or invalid authorization header");
  }

  const accessToken = authorizationHeader.split("Bearer ")[1];
  const { data, error } = await supabase.auth.getUser(accessToken);

  if (error || !data.user) {
    throw new HttpsError("unauthenticated", "Invalid Supabase access token");
  }

  return data.user;
}

export async function assertSessionOwnership(
  supabase: SupabaseClient,
  sessionId: string,
  userId: string,
) {
  const { data, error } = await supabase
    .from("sessions")
    .select("id, user_id, activity_id, status")
    .eq("id", sessionId)
    .maybeSingle();

  if (error || !data) {
    throw new HttpsError("not-found", "Session not found");
  }

  if (data.user_id !== userId) {
    throw new HttpsError("permission-denied", "You do not have access to this session");
  }

  return data;
}

export async function assertAttachmentOwnership(
  supabase: SupabaseClient,
  attachmentId: string,
  userId: string,
) {
  const { data, error } = await supabase
    .from("media_attachments")
    .select("id, session_id")
    .eq("id", attachmentId)
    .maybeSingle();

  if (error || !data) {
    throw new HttpsError("not-found", "Attachment not found");
  }

  await assertSessionOwnership(supabase, data.session_id, userId);
  return data;
}

export async function getSessionOwnerId(
  supabase: SupabaseClient,
  sessionId: string,
) {
  const { data, error } = await supabase
    .from("sessions")
    .select("id, user_id, status")
    .eq("id", sessionId)
    .maybeSingle();

  if (error || !data) {
    throw new HttpsError("not-found", "Session not found");
  }

  return data;
}
