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
