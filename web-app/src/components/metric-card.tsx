type MetricCardProps = {
  label: string;
  value: string;
  hint: string;
};

export function MetricCard({ label, value, hint }: MetricCardProps) {
  return (
    <div className="rounded-[24px] border border-white/10 bg-white/5 p-5">
      <p className="text-xs font-semibold uppercase tracking-[0.28em] text-stone-400">
        {label}
      </p>
      <p className="mt-4 text-4xl font-semibold tracking-tight text-white">
        {value}
      </p>
      <p className="mt-2 text-sm text-stone-300">{hint}</p>
    </div>
  );
}
