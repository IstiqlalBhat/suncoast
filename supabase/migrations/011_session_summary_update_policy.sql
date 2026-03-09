-- Allow authenticated users to confirm summaries for their own sessions.
CREATE POLICY "Users can update own summaries"
    ON session_summaries FOR UPDATE
    USING (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    )
    WITH CHECK (
        session_id IN (SELECT id FROM sessions WHERE user_id = auth.uid())
    );
