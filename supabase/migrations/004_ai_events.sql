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
CREATE INDEX idx_ai_events_session_id ON ai_events(session_id);
CREATE INDEX idx_ai_events_type ON ai_events(type);
CREATE INDEX idx_ai_events_created_at ON ai_events(created_at);

-- Enable RLS
ALTER TABLE ai_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view events for own sessions"
    ON ai_events FOR SELECT
    USING (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

CREATE POLICY "Service role can insert events"
    ON ai_events FOR INSERT
    WITH CHECK (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );

-- Enable realtime for ai_events
ALTER PUBLICATION supabase_realtime ADD TABLE ai_events;
