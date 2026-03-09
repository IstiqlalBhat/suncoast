-- Ensure every profile has a personal organization so activity creation works
-- even after mock data is removed.

CREATE OR REPLACE FUNCTION handle_new_profile_organization()
RETURNS TRIGGER AS $$
DECLARE
    v_org_id UUID;
BEGIN
    IF NEW.org_id IS NULL THEN
        INSERT INTO organizations (name, settings)
        VALUES (
            COALESCE(NULLIF(NEW.name, ''), split_part(NEW.email, '@', 1)) || ' Workspace',
            '{"bootstrap": true}'::jsonb
        )
        RETURNING id INTO v_org_id;

        UPDATE profiles
        SET org_id = v_org_id
        WHERE id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_profile_created_organization ON profiles;
CREATE TRIGGER on_profile_created_organization
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_profile_organization();

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
