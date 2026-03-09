type StatusBadgeProps = {
  label: string;
  tone?: "neutral" | "success" | "warning" | "danger" | "accent";
};

const tones: Record<NonNullable<StatusBadgeProps["tone"]>, string> = {
  neutral: "border-white/10 bg-white/8 text-stone-200",
  success: "border-emerald-400/20 bg-emerald-400/12 text-emerald-100",
  warning: "border-amber-300/20 bg-amber-300/12 text-amber-100",
  danger: "border-rose-400/20 bg-rose-400/12 text-rose-100",
  accent: "border-sky-400/20 bg-sky-400/12 text-sky-100",
};

export function StatusBadge({
  label,
  tone = "neutral",
}: StatusBadgeProps) {
  return (
    <span
      className={`inline-flex rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.22em] ${tones[tone]}`}
    >
      {label}
    </span>
  );
}
