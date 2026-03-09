import type { SupabaseClient } from "@supabase/supabase-js";
import { createDefaultSettings } from "@/lib/defaults";
import type {
  Activity,
  ActivityType,
  AiEvent,
  MediaAttachment,
  SessionRecord,
  SessionSummary,
  UserSettings,
} from "@/lib/types";

type QueryOptions = {
  search?: string;
  type?: ActivityType | "all";
};

export async function getActivities(
  supabase: SupabaseClient,
  options: QueryOptions = {},
) {
  let query = supabase.from("activities").select("*");

  if (options.search?.trim()) {
    query = query.ilike("title", `%${options.search.trim()}%`);
  }

  if (options.type && options.type !== "all") {
    query = query.eq("type", options.type);
  }

  const { data, error } = await query
    .order("scheduled_at", { ascending: false })
    .limit(50);

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as Activity[];
}

export async function getActivity(supabase: SupabaseClient, activityId: string) {
  const { data, error } = await supabase
    .from("activities")
    .select("*")
    .eq("id", activityId)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data as Activity;
}

export async function createActivity(
  supabase: SupabaseClient,
  payload: {
    title: string;
    type: ActivityType;
    description?: string;
    location?: string;
  },
) {
  const userId = (await supabase.auth.getUser()).data.user?.id;

  if (!userId) {
    throw new Error("User is not authenticated.");
  }

  const { data: profileRow } = await supabase
    .from("profiles")
    .select("org_id")
    .eq("id", userId)
    .single();

  const { data, error } = await supabase
    .from("activities")
    .insert({
      title: payload.title,
      type: payload.type,
      description: payload.description?.trim() || null,
      location: payload.location?.trim() || null,
      status: "pending",
      assigned_to: userId,
      org_id: profileRow?.org_id ?? null,
      scheduled_at: new Date().toISOString(),
    })
    .select("*")
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data as Activity;
}

export async function getSessionHistory(
  supabase: SupabaseClient,
  userId: string,
) {
  const { data, error } = await supabase
    .from("sessions")
    .select("*, activities(title, type)")
    .eq("user_id", userId)
    .order("started_at", { ascending: false })
    .limit(50);

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as SessionRecord[];
}

export async function deleteSession(supabase: SupabaseClient, sessionId: string) {
  const { error } = await supabase.from("sessions").delete().eq("id", sessionId);

  if (error) {
    throw new Error(error.message);
  }
}

export async function getSettings(
  supabase: SupabaseClient,
  userId: string,
) {
  const { data, error } = await supabase
    .from("user_settings")
    .select("*")
    .eq("user_id", userId)
    .limit(1);

  if (error) {
    throw new Error(error.message);
  }

  return ((data?.[0] as UserSettings | undefined) ?? createDefaultSettings(userId));
}

export async function upsertSettings(
  supabase: SupabaseClient,
  settings: UserSettings,
) {
  const { data, error } = await supabase
    .from("user_settings")
    .upsert(settings)
    .select("*")
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data as UserSettings;
}

export async function createSession(
  supabase: SupabaseClient,
  payload: {
    activityId: string;
    mode: SessionRecord["mode"];
  },
) {
  const userId = (await supabase.auth.getUser()).data.user?.id;

  if (!userId) {
    throw new Error("User is not authenticated.");
  }

  const { data, error } = await supabase
    .from("sessions")
    .insert({
      activity_id: payload.activityId,
      user_id: userId,
      mode: payload.mode,
      started_at: new Date().toISOString(),
      status: "active",
    })
    .select("*")
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data as SessionRecord;
}

export async function updateSession(
  supabase: SupabaseClient,
  sessionId: string,
  fields: Partial<SessionRecord>,
) {
  const { data, error } = await supabase
    .from("sessions")
    .update(fields)
    .eq("id", sessionId)
    .select("*")
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data as SessionRecord;
}

export async function endSession(supabase: SupabaseClient, sessionId: string) {
  return updateSession(supabase, sessionId, {
    ended_at: new Date().toISOString(),
    ended_reason: "user_completed",
    status: "ended",
    updated_at: new Date().toISOString(),
  });
}

export async function getSession(
  supabase: SupabaseClient,
  sessionId: string,
) {
  const { data, error } = await supabase
    .from("sessions")
    .select("*")
    .eq("id", sessionId)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data as SessionRecord;
}

export async function getSessionEvents(
  supabase: SupabaseClient,
  sessionId: string,
) {
  const { data, error } = await supabase
    .from("ai_events")
    .select("*")
    .eq("session_id", sessionId)
    .order("created_at", { ascending: true });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as AiEvent[];
}

export async function getSessionAttachments(
  supabase: SupabaseClient,
  sessionId: string,
) {
  const { data, error } = await supabase
    .from("media_attachments")
    .select("*")
    .eq("session_id", sessionId)
    .order("created_at", { ascending: true });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as MediaAttachment[];
}

export async function getSessionSummary(
  supabase: SupabaseClient,
  sessionId: string,
) {
  const { data, error } = await supabase
    .from("session_summaries")
    .select("*")
    .eq("session_id", sessionId)
    .limit(1);

  if (error) {
    throw new Error(error.message);
  }

  return (data?.[0] as SessionSummary | undefined) ?? null;
}
