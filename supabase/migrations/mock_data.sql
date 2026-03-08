-- FieldFlow Mock Data (idempotent - safe to re-run)
-- Run AFTER you have at least one signed-up user

-- Step 1: Clean up any previous mock data
DELETE FROM session_summaries WHERE id = '70000000-0000-0000-0000-000000000001';
DELETE FROM ai_events WHERE session_id IN ('50000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000002');
DELETE FROM sessions WHERE id IN ('50000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000002');
DELETE FROM activities WHERE id IN (
    '10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003',
    '20000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003',
    '30000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000003'
);

-- Step 2: Create org (or skip if exists)
INSERT INTO organizations (id, name, settings)
VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'Apex Property Management',
    '{"industry": "property_management", "plan": "pro"}'
)
ON CONFLICT (id) DO NOTHING;

-- Step 3: Assign ALL users to this org (not just the first one)
UPDATE profiles
SET org_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    role = 'admin',
    name = COALESCE(NULLIF(name, ''), split_part(email, '@', 1))
WHERE org_id IS NULL OR org_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- Step 4: Insert all mock data using the most recent user
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT id INTO v_user_id FROM profiles WHERE org_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' ORDER BY created_at DESC LIMIT 1;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'No user found. Please sign up first, then run this script.';
    END IF;

    -- PASSIVE activities (green)
    INSERT INTO activities (id, org_id, title, description, type, status, location, scheduled_at, assigned_to, metadata)
    VALUES
    (
        '10000000-0000-0000-0000-000000000001',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'Roof Inspection - Building A',
        'Annual roof condition assessment for the main office building. Check for leaks, damaged shingles, and drainage issues.',
        'passive',
        'pending',
        '123 Main St, Suite 400',
        NOW() + INTERVAL '2 hours',
        v_user_id,
        '{"priority": "high", "building": "A", "floor": "roof"}'
    ),
    (
        '10000000-0000-0000-0000-000000000002',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'HVAC System Check - Unit 5B',
        'Quarterly HVAC maintenance inspection. Test heating and cooling performance, check filters, inspect ductwork.',
        'passive',
        'pending',
        '456 Oak Avenue, Unit 5B',
        NOW() + INTERVAL '1 day',
        v_user_id,
        '{"priority": "medium", "unit": "5B", "system": "HVAC"}'
    ),
    (
        '10000000-0000-0000-0000-000000000003',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'Parking Lot Survey',
        'Assess parking lot condition after winter. Document cracks, potholes, and faded line markings.',
        'passive',
        'in_progress',
        '789 Commerce Blvd',
        NOW() - INTERVAL '30 minutes',
        v_user_id,
        '{"priority": "low", "area": "parking"}'
    );

    -- TWOWAY / Chat activities (blue)
    INSERT INTO activities (id, org_id, title, description, type, status, location, scheduled_at, assigned_to, metadata)
    VALUES
    (
        '20000000-0000-0000-0000-000000000001',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'Tenant Complaint - Water Leak',
        'Tenant in 3A reported water stain on ceiling. Interview tenant, inspect the unit above, and document findings.',
        'twoway',
        'pending',
        '456 Oak Avenue, Unit 3A',
        NOW() + INTERVAL '3 hours',
        v_user_id,
        '{"priority": "high", "tenant": "Maria Garcia", "unit": "3A"}'
    ),
    (
        '20000000-0000-0000-0000-000000000002',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'New Hire Safety Walkthrough',
        'Walk new maintenance staff through building safety protocols, fire exits, and equipment locations.',
        'twoway',
        'pending',
        '123 Main St',
        NOW() + INTERVAL '1 day 4 hours',
        v_user_id,
        '{"priority": "medium", "new_hire": "James Wilson"}'
    ),
    (
        '20000000-0000-0000-0000-000000000003',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'Vendor Meeting - Elevator Service',
        'Meet with ThyssenKrupp rep to discuss elevator maintenance contract renewal and modernization options.',
        'twoway',
        'in_progress',
        '123 Main St, Lobby',
        NOW() - INTERVAL '15 minutes',
        v_user_id,
        '{"priority": "high", "vendor": "ThyssenKrupp", "contract": "ELV-2024-089"}'
    );

    -- MEDIA activities (orange)
    INSERT INTO activities (id, org_id, title, description, type, status, location, scheduled_at, assigned_to, metadata)
    VALUES
    (
        '30000000-0000-0000-0000-000000000001',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'Move-Out Inspection - Unit 7C',
        'Document condition of apartment for security deposit assessment. Photo all rooms, appliances, fixtures.',
        'media',
        'pending',
        '456 Oak Avenue, Unit 7C',
        NOW() + INTERVAL '5 hours',
        v_user_id,
        '{"priority": "high", "unit": "7C", "tenant": "Robert Chen", "deposit": 2500}'
    ),
    (
        '30000000-0000-0000-0000-000000000002',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'Construction Progress - Lobby Renovation',
        'Weekly progress photos of lobby renovation project. Capture current state of flooring, lighting, and reception desk.',
        'media',
        'in_progress',
        '123 Main St, Lobby',
        NOW() - INTERVAL '1 hour',
        v_user_id,
        '{"priority": "medium", "project": "LOBBY-RENO-2024", "week": 6}'
    ),
    (
        '30000000-0000-0000-0000-000000000003',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'Fire Safety Equipment Audit',
        'Photo-document all fire extinguishers, sprinkler heads, and emergency exit signs across floors 1-5.',
        'media',
        'pending',
        '123 Main St, Floors 1-5',
        NOW() + INTERVAL '2 days',
        v_user_id,
        '{"priority": "high", "floors": [1,2,3,4,5], "compliance": "NFPA"}'
    );

    -- Completed session with events (parking lot survey)
    INSERT INTO sessions (id, activity_id, user_id, mode, started_at, ended_at, transcript)
    VALUES (
        '50000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000003',
        v_user_id,
        'passive',
        NOW() - INTERVAL '45 minutes',
        NOW() - INTERVAL '15 minutes',
        'Walking the east section of the parking lot now. I can see three significant potholes near the entrance. The largest one is about two feet wide. Line markings in the visitor section are almost completely faded. The drainage grate near spot 47 appears to be clogged with debris. Moving to the north section. The asphalt here is in better condition. Some minor cracking along the curb line but nothing urgent. The handicap signs need repainting. Speed bumps look intact.'
    );

    INSERT INTO ai_events (id, session_id, type, content, confidence, metadata)
    VALUES
    ('60000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 'observation', 'Three significant potholes identified near east entrance, largest approximately 2 feet wide', 0.95, '{"location": "east entrance"}'),
    ('60000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000001', 'observation', 'Visitor section line markings severely faded, nearly invisible', 0.92, '{"location": "visitor section"}'),
    ('60000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000001', 'observation', 'Drainage grate at spot 47 clogged with debris', 0.88, '{"location": "spot 47"}'),
    ('60000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000001', 'observation', 'North section asphalt in good condition with minor curb cracking', 0.90, '{"location": "north section"}'),
    ('60000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000001', 'action', 'Handicap signs flagged for repainting', 0.85, '{}'),
    ('60000000-0000-0000-0000-000000000006', '50000000-0000-0000-0000-000000000001', 'lookup', 'Check municipal code for parking lot maintenance requirements', 0.78, '{}');

    INSERT INTO session_summaries (id, session_id, key_observations, actions_taken, follow_ups, duration_seconds)
    VALUES (
        '70000000-0000-0000-0000-000000000001',
        '50000000-0000-0000-0000-000000000001',
        '["Three large potholes near east entrance need repair", "Visitor section line markings completely faded", "Drainage grate at spot 47 blocked", "North section in good condition with minor issues", "Handicap signs need repainting"]',
        '["Completed full walkthrough of east and north parking sections", "Documented pothole locations and sizes", "Identified drainage issue at spot 47"]',
        '[{"description": "Schedule pothole repair for east entrance - safety hazard", "priority": "high", "due_date": null}, {"description": "Repaint line markings in visitor section", "priority": "medium", "due_date": null}, {"description": "Clear debris from drainage grate at spot 47", "priority": "high", "due_date": null}, {"description": "Repaint handicap signage", "priority": "low", "due_date": null}, {"description": "Review municipal parking lot maintenance codes", "priority": "low", "due_date": null}]',
        1800
    );

    -- Active session for vendor meeting (twoway)
    INSERT INTO sessions (id, activity_id, user_id, mode, started_at, ended_at, transcript)
    VALUES (
        '50000000-0000-0000-0000-000000000002',
        '20000000-0000-0000-0000-000000000003',
        v_user_id,
        'chat',
        NOW() - INTERVAL '15 minutes',
        NULL,
        'Meeting with ThyssenKrupp representative about the elevator service contract. They are proposing a 3-year renewal with 5% annual increase. Current contract expires next month.'
    );

    INSERT INTO ai_events (id, session_id, type, content, confidence, metadata)
    VALUES
    ('60000000-0000-0000-0000-000000000010', '50000000-0000-0000-0000-000000000002', 'observation', 'Vendor proposing 3-year contract renewal with 5% annual price increase', 0.95, '{}'),
    ('60000000-0000-0000-0000-000000000011', '50000000-0000-0000-0000-000000000002', 'lookup', 'Current elevator maintenance contract ELV-2024-089 expires next month', 0.90, '{}'),
    ('60000000-0000-0000-0000-000000000012', '50000000-0000-0000-0000-000000000002', 'action', 'Request itemized breakdown of proposed service tiers from vendor', 0.85, '{}');

    -- User settings
    INSERT INTO user_settings (user_id, face_id_enabled, voice_output_enabled, voice_speed, confirmation_mode, language)
    VALUES (v_user_id, false, true, 1.0, 'smart', 'en')
    ON CONFLICT (user_id) DO NOTHING;

END $$;
