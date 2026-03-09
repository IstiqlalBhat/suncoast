export function formatDate(value: string | null | undefined) {
  if (!value) return "Unknown";

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Unknown";

  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(date);
}

export function formatDurationFromRange(start: string | null, end: string | null) {
  if (!start) return "0m";

  const started = new Date(start);
  const ended = end ? new Date(end) : new Date();
  const seconds = Math.max(
    0,
    Math.floor((ended.getTime() - started.getTime()) / 1000),
  );

  return formatDurationSeconds(seconds);
}

export function formatDurationSeconds(seconds: number | null | undefined) {
  if (!seconds || seconds <= 0) return "0m";

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }

  return `${Math.max(1, minutes)}m`;
}
