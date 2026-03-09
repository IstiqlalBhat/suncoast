-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,
    avatar_url TEXT,
    role TEXT DEFAULT 'field_worker',
    org_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key for org_id
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_profiles_org'
    ) THEN
        ALTER TABLE profiles
            ADD CONSTRAINT fk_profiles_org
            FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- RLS Policies for organizations
DROP POLICY IF EXISTS "Org members can view their org" ON organizations;
CREATE POLICY "Org members can view their org"
    ON organizations FOR SELECT
    USING (
        id IN (SELECT org_id FROM profiles WHERE id = auth.uid())
    );

-- Function to create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for auto profile creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Function to auto-create a personal organization for each profile
CREATE OR REPLACE FUNCTION handle_new_profile_organization()
RETURNS TRIGGER AS $$
DECLARE
    v_org_id UUID;
BEGIN
    IF NEW.org_id IS NULL THEN
        INSERT INTO organizations (name, settings)
        VALUES (
            COALESCE(NULLIF(NEW.name, ''), split_part(NEW.email, '@', 1)) || ' Workspace',
            '{"bootstrap": true}'::jsonb
        )
        RETURNING id INTO v_org_id;

        UPDATE profiles
        SET org_id = v_org_id
        WHERE id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_profile_created_organization ON profiles;
CREATE TRIGGER on_profile_created_organization
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_profile_organization();
-- Create activities table
CREATE TABLE IF NOT EXISTS activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL CHECK (type IN ('passive', 'twoway', 'media')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    location TEXT,
    scheduled_at TIMESTAMPTZ,
    assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_activities_org_id ON activities(org_id);
CREATE INDEX IF NOT EXISTS idx_activities_assigned_to ON activities(assigned_to);
CREATE INDEX IF NOT EXISTS idx_activities_type ON activities(type);
CREATE INDEX IF NOT EXISTS idx_activities_status ON activities(status);
CREATE INDEX IF NOT EXISTS idx_activities_scheduled_at ON activities(scheduled_at DESC);

-- Enable RLS
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view org activities" ON activities;
CREATE POLICY "Users can view org activities"
    ON activities FOR SELECT
    USING (
        org_id IN (SELECT org_id FROM profiles WHERE id = auth.uid())
        OR assigned_to = auth.uid()
    );

DROP POLICY IF EXISTS "Users can update assigned activities" ON activities;
CREATE POLICY "Users can update assigned activities"
    ON activities FOR UPDATE
    USING (assigned_to = auth.uid());

DROP POLICY IF EXISTS "Users can create activities" ON activities;
CREATE POLICY "Users can create activities"
    ON activities FOR INSERT
    WITH CHECK (
        assigned_to = auth.uid()
        AND org_id IN (SELECT org_id FROM profiles WHERE id = auth.uid())
    );
-- Create sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    mode TEXT NOT NULL CHECK (mode IN ('passive', 'chat', 'media')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    transcript TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_sessions_activity_id ON sessions(activity_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started_at ON sessions(started_at DESC);

-- Enable RLS
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own sessions" ON sessions;
CREATE POLICY "Users can view own sessions"
    ON sessions FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can create sessions" ON sessions;
CREATE POLICY "Users can create sessions"
    ON sessions FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own sessions" ON sessions;
CREATE POLICY "Users can update own sessions"
    ON sessions FOR UPDATE
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own sessions" ON sessions;
CREATE POLICY "Users can delete own sessions"
    ON sessions FOR DELETE
    USING (user_id = auth.uid());
-- Create AI events table
CREATE TABLE IF NOT EXISTS ai_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('observation', 'lookup', 'action')),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    confidence DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_events_session_id ON ai_events(session_id);
CREATE INDEX IF NOT EXISTS idx_ai_events_type ON ai_events(type);
CREATE INDEX IF NOT EXISTS idx_ai_events_created_at ON ai_events(created_at);

-- Enable RLS
ALTER TABLE ai_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view events for own sessions" ON ai_events;
CREATE POLICY "Users can view events for own sessions"
    ON ai_events FOR SELECT
    USING (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

DROP POLICY IF EXISTS "Service role can insert events" ON ai_events;
CREATE POLICY "Service role can insert events"
    ON ai_events FOR INSERT
    WITH CHECK (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

-- Enable realtime for ai_events
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'ai_events'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.ai_events;
    END IF;
END $$;
-- Create media attachments table
CREATE TABLE IF NOT EXISTS media_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('photo', 'video', 'file')),
    storage_path TEXT NOT NULL,
    thumbnail_path TEXT,
    ai_analysis TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_media_attachments_session_id ON media_attachments(session_id);

-- Enable RLS
ALTER TABLE media_attachments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own media" ON media_attachments;
CREATE POLICY "Users can view own media"
    ON media_attachments FOR SELECT
    USING (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

DROP POLICY IF EXISTS "Users can insert media for own sessions" ON media_attachments;
CREATE POLICY "Users can insert media for own sessions"
    ON media_attachments FOR INSERT
    WITH CHECK (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

-- Storage bucket policies (run via Supabase dashboard or separate migration)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('media-attachments', 'media-attachments', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
-- Create session summaries table
CREATE TABLE IF NOT EXISTS session_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL UNIQUE REFERENCES sessions(id) ON DELETE CASCADE,
    key_observations JSONB NOT NULL DEFAULT '[]',
    actions_taken JSONB NOT NULL DEFAULT '[]',
    follow_ups JSONB NOT NULL DEFAULT '[]',
    duration_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_session_summaries_session_id ON session_summaries(session_id);

-- Enable RLS
ALTER TABLE session_summaries ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own summaries" ON session_summaries;
CREATE POLICY "Users can view own summaries"
    ON session_summaries FOR SELECT
    USING (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

DROP POLICY IF EXISTS "Service role can insert summaries" ON session_summaries;
CREATE POLICY "Service role can insert summaries"
    ON session_summaries FOR INSERT
    WITH CHECK (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );
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
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);

-- Enable RLS
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own settings" ON user_settings;
CREATE POLICY "Users can view own settings"
    ON user_settings FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own settings" ON user_settings;
CREATE POLICY "Users can insert own settings"
    ON user_settings FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own settings" ON user_settings;
CREATE POLICY "Users can update own settings"
    ON user_settings FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

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

DO $$
DECLARE
    v_profile RECORD;
    v_org_id UUID;
BEGIN
    FOR v_profile IN
        SELECT id, email, name
        FROM profiles
        WHERE org_id IS NULL
    LOOP
        INSERT INTO organizations (name, settings)
        VALUES (
            COALESCE(NULLIF(v_profile.name, ''), split_part(v_profile.email, '@', 1)) || ' Workspace',
            '{"bootstrap": true}'::jsonb
        )
        RETURNING id INTO v_org_id;

        UPDATE profiles
        SET org_id = v_org_id
        WHERE id = v_profile.id;
    END LOOP;
END $$;

-- Repair profile-linked defaults after manual data deletion.
-- This backfills personal organizations and user_settings rows for existing users.

DROP POLICY IF EXISTS "Users can update own settings" ON user_settings;
CREATE POLICY "Users can update own settings"
    ON user_settings FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DO $$
DECLARE
    v_profile RECORD;
    v_org_id UUID;
BEGIN
    FOR v_profile IN
        SELECT id, email, name
        FROM profiles
        WHERE org_id IS NULL
    LOOP
        INSERT INTO organizations (name, settings)
        VALUES (
            COALESCE(NULLIF(v_profile.name, ''), split_part(v_profile.email, '@', 1)) || ' Workspace',
            '{"bootstrap": true}'::jsonb
        )
        RETURNING id INTO v_org_id;

        UPDATE profiles
        SET org_id = v_org_id
        WHERE id = v_profile.id;
    END LOOP;
END $$;

INSERT INTO user_settings (user_id)
SELECT p.id
FROM profiles p
LEFT JOIN user_settings us ON us.user_id = p.id
WHERE us.user_id IS NULL;

-- Production hardening for session lifecycle, AI metadata, and storage policies

-- Sessions
ALTER TABLE public.sessions
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'ended', 'processing', 'failed')),
    ADD COLUMN IF NOT EXISTS ended_reason TEXT,
    ADD COLUMN IF NOT EXISTS processing_error TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_sessions_status ON public.sessions(status);

-- AI events
ALTER TABLE public.ai_events
    ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'ai'
        CHECK (source IN ('ai', 'system', 'user', 'integration')),
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'completed'
        CHECK (status IN ('pending', 'completed', 'skipped', 'failed')),
    ADD COLUMN IF NOT EXISTS requires_confirmation BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS external_record_id TEXT,
    ADD COLUMN IF NOT EXISTS external_record_url TEXT,
    ADD COLUMN IF NOT EXISTS action_label TEXT;

CREATE INDEX IF NOT EXISTS idx_ai_events_status ON public.ai_events(status);
CREATE INDEX IF NOT EXISTS idx_ai_events_source ON public.ai_events(source);

-- Media attachments
ALTER TABLE public.media_attachments
    ADD COLUMN IF NOT EXISTS mime_type TEXT,
    ADD COLUMN IF NOT EXISTS file_size_bytes BIGINT,
    ADD COLUMN IF NOT EXISTS analysis_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (analysis_status IN ('pending', 'completed', 'failed', 'skipped')),
    ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_media_attachments_analysis_status
    ON public.media_attachments(analysis_status);

-- Session summaries
ALTER TABLE public.session_summaries
    ADD COLUMN IF NOT EXISTS observation_summary TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS action_statuses JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS external_records JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ;

DROP POLICY IF EXISTS "Users can update own summaries" ON session_summaries;
CREATE POLICY "Users can update own summaries"
    ON session_summaries FOR UPDATE
    USING (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    )
    WITH CHECK (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

DROP POLICY IF EXISTS "Users can view org activities" ON activities;
DROP POLICY IF EXISTS "Users can update assigned activities" ON activities;
DROP POLICY IF EXISTS "Users can view own activities" ON activities;
DROP POLICY IF EXISTS "Users can update own activities" ON activities;
DROP POLICY IF EXISTS "Users can create sessions" ON sessions;
DROP POLICY IF EXISTS "Users can update own sessions" ON sessions;

CREATE POLICY "Users can view own activities"
    ON activities FOR SELECT
    USING (assigned_to = auth.uid());

CREATE POLICY "Users can update own activities"
    ON activities FOR UPDATE
    USING (assigned_to = auth.uid())
    WITH CHECK (assigned_to = auth.uid());

CREATE POLICY "Users can create sessions"
    ON sessions FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
        AND activity_id IN (
            SELECT id
            FROM activities
            WHERE assigned_to = auth.uid()
        )
    );

CREATE POLICY "Users can update own sessions"
    ON sessions FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (
        user_id = auth.uid()
        AND activity_id IN (
            SELECT id
            FROM activities
            WHERE assigned_to = auth.uid()
        )
    );

-- Buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'media-attachments',
    'media-attachments',
    FALSE,
    52428800,
    ARRAY[
        'image/jpeg',
        'image/png',
        'image/webp',
        'video/mp4',
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
)
ON CONFLICT (id) DO UPDATE
SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    TRUE,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Users can read own session media objects" ON storage.objects;
CREATE POLICY "Users can read own session media objects"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'media-attachments'
        AND (storage.foldername(name))[1] IN (
            SELECT id::TEXT
            FROM public.sessions
            WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can upload own session media objects" ON storage.objects;
CREATE POLICY "Users can upload own session media objects"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'media-attachments'
        AND (storage.foldername(name))[1] IN (
            SELECT id::TEXT
            FROM public.sessions
            WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update own session media objects" ON storage.objects;
CREATE POLICY "Users can update own session media objects"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'media-attachments'
        AND (storage.foldername(name))[1] IN (
            SELECT id::TEXT
            FROM public.sessions
            WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete own session media objects" ON storage.objects;
CREATE POLICY "Users can delete own session media objects"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'media-attachments'
        AND (storage.foldername(name))[1] IN (
            SELECT id::TEXT
            FROM public.sessions
            WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Public can read avatars" ON storage.objects;
CREATE POLICY "Public can read avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload own avatars" ON storage.objects;
CREATE POLICY "Users can upload own avatars"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

DROP POLICY IF EXISTS "Users can update own avatars" ON storage.objects;
CREATE POLICY "Users can update own avatars"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

DROP POLICY IF EXISTS "Users can delete own avatars" ON storage.objects;
CREATE POLICY "Users can delete own avatars"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );
