-- Seed Multi-Section Assignments for Branch Officers (Sr. AOs)

DO $$
DECLARE
    v_org_id uuid := '01a029f9-4568-7c32-9782-f69a23782652';
    v_sec RECORD;
    v_sao RECORD;
    v_sao_ids uuid[];
    v_idx int := 1;
BEGIN
    -- Collect all Senior Accounts Officer employee IDs
    SELECT ARRAY_AGG(e.id) INTO v_sao_ids
    FROM employees e
    JOIN designations d ON e.designation_id = d.id
    WHERE d.title ILIKE '%Senior Accounts Officer%' OR d.title ILIKE '%SR ACCOUNTS OFFICER%';

    IF v_sao_ids IS NULL OR array_length(v_sao_ids, 1) = 0 THEN
        RAISE NOTICE 'No Senior Accounts Officers found';
        RETURN;
    END IF;

    -- Assign each section a Branch Officer from the Sr. AO list in round-robin fashion
    FOR v_sec IN SELECT id, name FROM sections WHERE organization_id = v_org_id LOOP
        INSERT INTO section_officer_assignments (id, organization_id, section_id, employee_id, role_title)
        VALUES (
            gen_random_uuid(),
            v_org_id,
            v_sec.id,
            v_sao_ids[((v_idx - 1) % array_length(v_sao_ids, 1)) + 1],
            'BRANCH_OFFICER'
        )
        ON CONFLICT (section_id, employee_id, role_title) DO NOTHING;

        v_idx := v_idx + 1;
    END LOOP;
END $$;