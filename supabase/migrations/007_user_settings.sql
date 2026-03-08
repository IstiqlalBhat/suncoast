-- Create user settings table
CREATE TABLE IF NOT EXISTS user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
    face_id_enabled BOOLEAN DEFAULT FALSE,
    voice_output_enabled BOOLEAN DEFAULT TRUE,
    voice_id TEXT,
    voice_speed DOUBLE PRECISION DEFAULT 1.0,
    confirmation_mode TEXT DEFAULT 'smart' CHECK (confirmation_mode IN ('always', 'smart', 'off')),
    language TEXT DEFAULT 'en',
    use_premium_tts BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

-- Enable RLS
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own settings"
    ON user_settings FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own settings"
    ON user_settings FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own settings"
    ON user_settings FOR UPDATE
    USING (user_id = auth.uid());

-- Function to auto-create settings on profile creation
CREATE OR REPLACE FUNCTION handle_new_profile_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_profile_created_settings ON profiles;
CREATE TRIGGER on_profile_created_settings
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_profile_settings();
