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
CREATE INDEX idx_media_attachments_session_id ON media_attachments(session_id);

-- Enable RLS
ALTER TABLE media_attachments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own media"
    ON media_attachments FOR SELECT
    USING (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert media for own sessions"
    ON media_attachments FOR INSERT
    WITH CHECK (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

-- Storage bucket policies (run via Supabase dashboard or separate migration)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('media-attachments', 'media-attachments', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
