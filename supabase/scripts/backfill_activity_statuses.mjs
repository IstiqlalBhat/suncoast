const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("SUPABASE_URL and SUPABASE_SERVICE_KEY are required");
  process.exit(1);
}

const headers = {
  apikey: supabaseServiceKey,
  Authorization: `Bearer ${supabaseServiceKey}`,
  "Content-Type": "application/json",
};

async function rest(path, init = {}) {
  const response = await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    ...init,
    headers: {
      ...headers,
      ...(init.headers ?? {}),
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`${response.status} ${response.statusText}: ${body}`);
  }

  return response.status === 204 ? null : response.json();
}

const sessions = await rest(
  "sessions?select=activity_id,status,ended_at&order=started_at.desc&limit=1000",
);

const nextStatusByActivity = new Map();

for (const session of sessions ?? []) {
  const activityId = session.activity_id;
  if (!activityId || nextStatusByActivity.get(activityId) === "in_progress") {
    continue;
  }

  if (session.status === "active" && session.ended_at == null) {
    nextStatusByActivity.set(activityId, "in_progress");
    continue;
  }

  if (
    !nextStatusByActivity.has(activityId) &&
    (session.status === "ended" || session.ended_at != null)
  ) {
    nextStatusByActivity.set(activityId, "completed");
  }
}

let updatedCount = 0;

for (const [activityId, status] of nextStatusByActivity.entries()) {
  await rest(`activities?id=eq.${activityId}`, {
    method: "PATCH",
    headers: {
      Prefer: "return=minimal",
    },
    body: JSON.stringify({
      status,
      updated_at: new Date().toISOString(),
    }),
  });
  updatedCount += 1;
}

console.log(
  `Backfilled ${updatedCount} activities from ${sessions?.length ?? 0} sessions.`,
);
