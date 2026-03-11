"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { appNavigation } from "@/lib/routes";

type AppShellProps = {
  userName: string;
  userEmail: string;
  children: React.ReactNode;
};

export function AppShell({ userName, userEmail, children }: AppShellProps) {
  const pathname = usePathname();

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(242,166,90,0.22),_transparent_38%),linear-gradient(180deg,_#0e1b1f_0%,_#071014_52%,_#04161a_100%)] text-stone-100">
      <div className="mx-auto flex min-h-screen max-w-7xl flex-col gap-6 px-4 py-4 lg:flex-row lg:px-6 lg:py-6">
        <aside className="rounded-[28px] border border-white/10 bg-white/6 p-4 backdrop-blur md:p-5 lg:sticky lg:top-6 lg:h-[calc(100vh-3rem)] lg:w-80">
          <div className="mb-8">
            <div className="mb-4 inline-flex rounded-full border border-amber-200/20 bg-amber-400/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.3em] text-amber-100/80">
              myEA
            </div>
            <h1 className="text-3xl font-semibold tracking-tight text-white">
              Field operations, live.
            </h1>
            <p className="mt-3 text-sm leading-6 text-stone-300">
              Web control room for voice sessions, summaries, and field activity tracking.
            </p>
          </div>

          <nav className="space-y-2">
            {appNavigation.map((item) => {
              const isActive = pathname.startsWith(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex items-center justify-between rounded-2xl px-4 py-3 text-sm transition ${
                    isActive
                      ? "bg-amber-300 text-slate-900"
                      : "bg-white/5 text-stone-200 hover:bg-white/10"
                  }`}
                >
                  <span>{item.label}</span>
                  <span className="text-xs uppercase tracking-[0.25em]">
                    {isActive ? "Live" : "Open"}
                  </span>
                </Link>
              );
            })}
          </nav>

          <div className="mt-8 rounded-[24px] border border-white/10 bg-slate-950/40 p-4">
            <p className="text-xs uppercase tracking-[0.25em] text-stone-400">
              Operator
            </p>
            <p className="mt-2 text-lg font-semibold text-white">{userName}</p>
            <p className="text-sm text-stone-400">{userEmail}</p>
          </div>
        </aside>

        <div className="flex-1 rounded-[32px] border border-white/10 bg-slate-950/55 p-4 shadow-2xl shadow-black/20 backdrop-blur md:p-6">
          {children}
        </div>
      </div>
    </div>
  );
}
