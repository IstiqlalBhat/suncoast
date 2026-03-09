-- Tighten app access from org-visible records to user-owned records.
DROP POLICY IF EXISTS "Users can view org activities" ON activities;
DROP POLICY IF EXISTS "Users can update assigned activities" ON activities;
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
