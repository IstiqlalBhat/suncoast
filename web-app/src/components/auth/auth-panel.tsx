"use client";

import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";

type AuthMode = "signin" | "signup";

export function AuthPanel() {
  const router = useRouter();
  const supabase = getSupabaseBrowserClient();
  const [mode, setMode] = useState<AuthMode>("signin");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const title = useMemo(
    () => (mode === "signin" ? "Resume operations" : "Create operator access"),
    [mode],
  );

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      if (mode === "signin") {
        const { error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password,
        });

        if (signInError) {
          throw signInError;
        }
      } else {
        const { error: signUpError } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: {
              name: name.trim(),
            },
          },
        });

        if (signUpError) {
          throw signUpError;
        }
      }

      router.replace("/dashboard");
      router.refresh();
    } catch (submitError) {
      setError(
        submitError instanceof Error
          ? submitError.message
          : "Authentication failed.",
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="grid min-h-screen bg-[linear-gradient(135deg,_#081519_0%,_#10252d_50%,_#d97706_160%)] px-4 py-6 text-stone-100 md:px-6">
      <div className="mx-auto grid w-full max-w-6xl gap-6 lg:grid-cols-[1.2fr_0.8fr]">
        <section className="rounded-[32px] border border-white/10 bg-white/6 p-6 backdrop-blur md:p-10">
          <div className="max-w-2xl">
            <p className="text-xs font-semibold uppercase tracking-[0.35em] text-amber-200/80">
              myEA Web
            </p>
            <h1 className="mt-4 text-5xl font-semibold tracking-tight text-white md:text-6xl">
              Dispatch, document, and summarize field work from the browser.
            </h1>
            <p className="mt-6 max-w-xl text-base leading-7 text-stone-200">
              This web console reuses the live Supabase and Firebase backend already configured in the mobile app, including session history, AI summaries, and browser-based voice workflows.
            </p>
          </div>

          <div className="mt-10 grid gap-4 md:grid-cols-3">
            {[
              ["Realtime sessions", "Track active passive, chat, and media sessions."],
              ["Shared backend", "Supabase auth/data and Firebase Functions stay unchanged."],
              ["Browser voice", "Use mic capture, file upload, and ElevenLabs over the web."],
            ].map(([headline, copy]) => (
              <div
                key={headline}
                className="rounded-[24px] border border-white/10 bg-slate-950/35 p-5"
              >
                <h2 className="text-lg font-semibold text-white">{headline}</h2>
                <p className="mt-3 text-sm leading-6 text-stone-300">{copy}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-[32px] border border-white/10 bg-slate-950/80 p-6 shadow-2xl shadow-black/30 md:p-8">
          <div className="flex gap-2 rounded-full bg-white/5 p-1 text-sm">
            <button
              type="button"
              onClick={() => setMode("signin")}
              className={`flex-1 rounded-full px-4 py-2 transition ${
                mode === "signin"
                  ? "bg-amber-300 text-slate-950"
                  : "text-stone-300"
              }`}
            >
              Sign in
            </button>
            <button
              type="button"
              onClick={() => setMode("signup")}
              className={`flex-1 rounded-full px-4 py-2 transition ${
                mode === "signup"
                  ? "bg-amber-300 text-slate-950"
                  : "text-stone-300"
              }`}
            >
              Sign up
            </button>
          </div>

          <div className="mt-8">
            <h2 className="text-3xl font-semibold tracking-tight text-white">
              {title}
            </h2>
            <p className="mt-3 text-sm leading-6 text-stone-400">
              Use the same Supabase operator account as the mobile app. Face ID enrollment is configured on mobile, while the web console continues to use email and password.
            </p>
          </div>

          <form className="mt-8 space-y-4" onSubmit={handleSubmit}>
            {mode === "signup" ? (
              <label className="block">
                <span className="mb-2 block text-sm text-stone-300">Full name</span>
                <input
                  required
                  value={name}
                  onChange={(event) => setName(event.target.value)}
                  className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none transition focus:border-amber-300/50 focus:bg-white/10"
                />
              </label>
            ) : null}

            <label className="block">
              <span className="mb-2 block text-sm text-stone-300">Email</span>
              <input
                required
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none transition focus:border-amber-300/50 focus:bg-white/10"
              />
            </label>

            <label className="block">
              <span className="mb-2 block text-sm text-stone-300">Password</span>
              <input
                required
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-white outline-none transition focus:border-amber-300/50 focus:bg-white/10"
              />
            </label>

            {error ? (
              <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
                {error}
              </div>
            ) : null}

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full rounded-full bg-amber-300 px-5 py-3 text-sm font-semibold uppercase tracking-[0.25em] text-slate-950 transition hover:bg-amber-200 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isSubmitting
                ? "Working..."
                : mode === "signin"
                  ? "Enter workspace"
                  : "Create account"}
            </button>
          </form>
        </section>
      </div>
    </div>
  );
}
