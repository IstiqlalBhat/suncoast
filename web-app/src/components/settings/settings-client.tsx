"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { PageHeading } from "@/components/page-heading";
import { upsertSettings } from "@/lib/data";
import { getSupabaseBrowserClient } from "@/lib/supabase/browser";
import type { ConfirmationMode, UserSettings } from "@/lib/types";

type SettingsClientProps = {
  initialSettings: UserSettings;
  userName: string;
  email: string;
};

const confirmationModes: ConfirmationMode[] = ["always", "smart", "off"];

export function SettingsClient({
  initialSettings,
  userName,
  email,
}: SettingsClientProps) {
  const router = useRouter();
  const supabase = getSupabaseBrowserClient();
  const [settings, setSettings] = useState(initialSettings);
  const [error, setError] = useState<string | null>(null);
  const [savedMessage, setSavedMessage] = useState<string | null>(null);

  async function persist(nextSettings: UserSettings) {
    setSettings(nextSettings);
    setSavedMessage(null);
    setError(null);

    try {
      const saved = await upsertSettings(supabase, nextSettings);
      setSettings(saved);
      setSavedMessage("Settings saved.");
    } catch (persistError) {
      setError(
        persistError instanceof Error
          ? persistError.message
          : "Failed to save settings.",
      );
    }
  }

  async function signOut() {
    await supabase.auth.signOut();
    router.replace("/login");
    router.refresh();
  }

  return (
    <div className="space-y-8">
      <PageHeading
        eyebrow="Settings"
        title="Operator preferences"
        description="These settings map to the same `user_settings` rows used by the mobile app. Voice and confirmation preferences are editable here, and the mobile Face ID status is shown for reference."
      />

      <section className="grid gap-4 lg:grid-cols-[0.9fr_1.1fr]">
        <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.3em] text-stone-400">
            Profile
          </p>
          <h3 className="mt-4 text-3xl font-semibold text-white">{userName}</h3>
          <p className="mt-2 text-sm text-stone-300">{email}</p>
          <p className="mt-6 text-sm leading-6 text-stone-400">
            Browser sessions share the same account and backend records as the mobile app. Sign out here if you need to switch operators.
          </p>
          <button
            type="button"
            onClick={signOut}
            className="mt-8 rounded-full border border-rose-400/20 bg-rose-400/10 px-5 py-3 text-sm font-semibold uppercase tracking-[0.24em] text-rose-100"
          >
            Sign out
          </button>
        </div>

        <div className="rounded-[28px] border border-white/10 bg-white/4 p-6">
          <div className="space-y-6">
            <StaticRow
              label="Mobile Face ID"
              description="This mirrors the mobile login checkbox and mobile Settings toggle. Enrollment still happens on the mobile app."
              value={settings.face_id_enabled ? "Enabled" : "Not enabled"}
            />
            <ToggleRow
              label="Voice output"
              description="Allow browser playback for AI responses and generated audio."
              checked={settings.voice_output_enabled}
              onChange={(checked) =>
                void persist({
                  ...settings,
                  voice_output_enabled: checked,
                })
              }
            />
            <ToggleRow
              label="Premium voice (OpenAI)"
              description="Preserve the higher-quality TTS preference used in mobile."
              checked={settings.use_premium_tts}
              onChange={(checked) =>
                void persist({
                  ...settings,
                  use_premium_tts: checked,
                })
              }
            />

            <label className="block">
              <span className="text-sm text-stone-200">Voice speed</span>
              <input
                type="range"
                min="0.5"
                max="2"
                step="0.25"
                value={settings.voice_speed}
                onChange={(event) =>
                  void persist({
                    ...settings,
                    voice_speed: Number(event.target.value),
                  })
                }
                className="mt-3 w-full"
              />
              <span className="mt-2 block text-sm text-stone-400">
                {settings.voice_speed.toFixed(2)}x
              </span>
            </label>

            <div>
              <p className="text-sm text-stone-200">Confirmation mode</p>
              <div className="mt-3 flex flex-wrap gap-2">
                {confirmationModes.map((mode) => (
                  <button
                    key={mode}
                    type="button"
                    onClick={() =>
                      void persist({
                        ...settings,
                        confirmation_mode: mode,
                      })
                    }
                    className={`rounded-full px-4 py-2 text-sm capitalize transition ${
                      settings.confirmation_mode === mode
                        ? "bg-amber-300 text-slate-950"
                        : "bg-white/6 text-stone-200 hover:bg-white/10"
                    }`}
                  >
                    {mode}
                  </button>
                ))}
              </div>
            </div>

            {savedMessage ? (
              <div className="rounded-2xl border border-emerald-400/20 bg-emerald-400/10 px-4 py-3 text-sm text-emerald-100">
                {savedMessage}
              </div>
            ) : null}

            {error ? (
              <div className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-3 text-sm text-rose-100">
                {error}
              </div>
            ) : null}
          </div>
        </div>
      </section>
    </div>
  );
}

type ToggleRowProps = {
  label: string;
  description: string;
  checked: boolean;
  onChange: (nextValue: boolean) => void;
};

type StaticRowProps = {
  label: string;
  description: string;
  value: string;
};

function StaticRow({ label, description, value }: StaticRowProps) {
  return (
    <div className="flex items-start justify-between gap-4 rounded-[20px] border border-white/10 bg-slate-950/35 p-4">
      <div>
        <p className="text-sm font-semibold text-white">{label}</p>
        <p className="mt-2 text-sm leading-6 text-stone-400">{description}</p>
      </div>
      <span className="rounded-full border border-white/10 bg-white/6 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-stone-200">
        {value}
      </span>
    </div>
  );
}

function ToggleRow({ label, description, checked, onChange }: ToggleRowProps) {
  return (
    <div className="flex items-start justify-between gap-4 rounded-[20px] border border-white/10 bg-slate-950/35 p-4">
      <div>
        <p className="text-sm font-semibold text-white">{label}</p>
        <p className="mt-2 text-sm leading-6 text-stone-400">{description}</p>
      </div>
      <button
        type="button"
        aria-pressed={checked}
        onClick={() => onChange(!checked)}
        className={`relative mt-1 h-8 w-[60px] rounded-full transition ${
          checked ? "bg-amber-300" : "bg-white/10"
        }`}
      >
        <span
          className={`absolute top-1 h-6 w-6 rounded-full bg-slate-950 transition ${
            checked ? "left-8" : "left-1"
          }`}
        />
      </button>
    </div>
  );
}
