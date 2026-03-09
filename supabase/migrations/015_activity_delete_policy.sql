DROP POLICY IF EXISTS "Users can delete own activities" ON activities;

CREATE POLICY "Users can delete own activities"
    ON activities FOR DELETE
    USING (assigned_to = auth.uid());
