-- Add stt_engine column to user_settings for on-device vs cloud speech recognition
ALTER TABLE user_settings
    ADD COLUMN IF NOT EXISTS stt_engine TEXT DEFAULT 'cloud'
    CHECK (stt_engine IN ('device', 'cloud'));
