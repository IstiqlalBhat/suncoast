import type { UserSettings } from "@/lib/types";

export function createDefaultSettings(userId: string): UserSettings {
  return {
    id: "",
    user_id: userId,
    face_id_enabled: false,
    voice_output_enabled: true,
    voice_id: null,
    voice_speed: 1,
    confirmation_mode: "smart",
    language: "en",
    use_premium_tts: true,
  };
}
