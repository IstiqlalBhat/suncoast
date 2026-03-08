-- Allow authenticated users to create activities within their org
CREATE POLICY "Users can create activities"
    ON activities FOR INSERT
    WITH CHECK (
        assigned_to = auth.uid()
        AND org_id IN (SELECT org_id FROM profiles WHERE id = auth.uid())
    );
