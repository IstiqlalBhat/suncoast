#!/usr/bin/env node

const defaultBuckets = ["media-attachments", "avatars"];

function readEnv(name) {
  const value = process.env[name]?.trim();
  return value ? value : null;
}

async function emptyBucket(baseUrl, serviceKey, bucket) {
  const endpoint = new URL(`/storage/v1/bucket/${bucket}/empty`, baseUrl).toString();
  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
    },
    body: "{}",
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`Failed to empty bucket "${bucket}" (${response.status}): ${details}`);
  }
}

async function main() {
  const baseUrl = readEnv("SUPABASE_URL");
  const serviceKey = readEnv("SUPABASE_SERVICE_KEY");
  const buckets = process.argv.slice(2);

  if (!baseUrl || !serviceKey) {
    throw new Error(
      "Missing SUPABASE_URL or SUPABASE_SERVICE_KEY. Export them before running this script.",
    );
  }

  const targetBuckets = buckets.length > 0 ? buckets : defaultBuckets;

  for (const bucket of targetBuckets) {
    await emptyBucket(baseUrl, serviceKey, bucket);
    console.log(`Emptied bucket: ${bucket}`);
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
