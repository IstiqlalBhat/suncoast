-- Allow users to delete their own sessions
-- Related ai_events, media_attachments, and session_summaries cascade via ON DELETE CASCADE
CREATE POLICY "Users can delete own sessions"
    ON sessions FOR DELETE
    USING (user_id = auth.uid());
