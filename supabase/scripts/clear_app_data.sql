-- Clear FieldFlow application data while preserving auth users and profiles.
-- This removes runtime records and derived per-user rows, then recreates one
-- organization and one settings row per existing profile.
--
-- Supabase blocks direct SQL deletes from storage.objects. Empty the buckets
-- first via the Storage API, for example:
--   node supabase/scripts/clear_storage.mjs
-- Then run this SQL.

BEGIN;

DELETE FROM public.ai_events;
DELETE FROM public.session_summaries;
DELETE FROM public.media_attachments;
DELETE FROM public.sessions;
DELETE FROM public.activities;
DELETE FROM public.user_settings;

UPDATE public.profiles
SET
    avatar_url = NULL,
    org_id = NULL;

DELETE FROM public.organizations;

DO $$
DECLARE
    v_profile RECORD;
    v_org_id UUID;
BEGIN
    FOR v_profile IN
        SELECT id, email, name
        FROM public.profiles
    LOOP
        INSERT INTO public.organizations (name, settings)
        VALUES (
            COALESCE(NULLIF(v_profile.name, ''), split_part(v_profile.email, '@', 1)) || ' Workspace',
            '{"bootstrap": true}'::jsonb
        )
        RETURNING id INTO v_org_id;

        UPDATE public.profiles
        SET org_id = v_org_id
        WHERE id = v_profile.id;
    END LOOP;
END $$;

INSERT INTO public.user_settings (user_id)
SELECT p.id
FROM public.profiles p
LEFT JOIN public.user_settings us ON us.user_id = p.id
WHERE us.user_id IS NULL;

COMMIT;
