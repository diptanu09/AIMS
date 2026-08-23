import uuid

# Database connection parameters
DB_PARAMS = {
    "dbname": "aims",
    "user": "aims_app",
    "password": "",  # Local peer/trust inside container or direct psql execution
}

# We can generate a clean SQL file scratch/seed_section_officers.sql
output_sql = r"c:\Users\MrF41C0N\Desktop\GitHub\AIMS\scratch\seed_section_officers.sql"
org_id = "01a029f9-4568-7c32-9782-f69a23782652"

# 5 Sr. AOs (Branch Officers)
# 404232: AJOY DUTTA (Senior Accounts Officer)
# 567588: Debabrato Chowdhury (Senior Accounts Officer)
# 799528: Subodh Debbarma (Senior Accounts Officer)
# 980071: SUBRATA DAS CHOUDHURY (SR ACCOUNTS OFFICER)
# 923432: UTTAM CHAKRABORTY (Senior Accounts Officer)

sao_codes = ["404232", "567588", "799528", "980071", "923432"]

sql_lines = []
sql_lines.append("-- Seed Multi-Section Assignments for Branch Officers (Sr. AOs)")
sql_lines.append("""
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
""".strip())

with open(output_sql, "w", encoding="utf-8") as out:
    out.write("\n\n".join(sql_lines))

print("Generated seed_section_officers.sql cleanly.")
