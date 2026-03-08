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
CREATE INDEX idx_session_summaries_session_id ON session_summaries(session_id);

-- Enable RLS
ALTER TABLE session_summaries ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own summaries"
    ON session_summaries FOR SELECT
    USING (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

CREATE POLICY "Service role can insert summaries"
    ON session_summaries FOR INSERT
    WITH CHECK (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );
