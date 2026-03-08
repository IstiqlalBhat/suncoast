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

-- Storage policies for session media
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

-- Storage policies for avatars
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
