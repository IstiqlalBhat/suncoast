-- Fix: Consolidate signup trigger chain into a single function.
--
-- Root cause: Cascading AFTER INSERT triggers on profiles
-- (handle_new_profile_organization, handle_new_profile_settings) failed
-- when invoked within GoTrue's auth transaction context, even though the
-- same logic succeeds when run inline.  Merging everything into
-- handle_new_user() eliminates the cascading trigger issue.

-- Remove the separate cascading triggers
DROP TRIGGER IF EXISTS on_profile_created_organization ON profiles;
DROP TRIGGER IF EXISTS on_profile_created_settings ON profiles;

-- Single consolidated trigger function: profile + org + settings
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_org_id UUID;
BEGIN
    -- 1. Create profile
    INSERT INTO public.profiles (id, email, name)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        COALESCE(
            NEW.raw_user_meta_data->>'name',
            split_part(COALESCE(NEW.email, ''), '@', 1)
        )
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        name  = COALESCE(NULLIF(EXCLUDED.name, ''), profiles.name),
        updated_at = NOW();

    -- 2. Bootstrap personal organization
    INSERT INTO public.organizations (name, settings)
    VALUES (
        COALESCE(
            NULLIF(
                COALESCE(NEW.raw_user_meta_data->>'name', ''),
                ''
            ),
            split_part(COALESCE(NEW.email, ''), '@', 1)
        ) || ' Workspace',
        '{"bootstrap": true}'::jsonb
    )
    RETURNING id INTO v_org_id;

    UPDATE public.profiles
    SET org_id = v_org_id
    WHERE id = NEW.id;

    -- 3. Create default user settings
    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
