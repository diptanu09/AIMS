import csv
import re
import uuid

# Read emp_data.csv
input_file = r"c:\Users\MrF41C0N\Desktop\GitHub\AIMS\emp_data.csv"
output_sql = r"c:\Users\MrF41C0N\Desktop\GitHub\AIMS\scratch\update_emp_data.sql"

# Organization ID for DEFAULT organization
org_id = "01a029f9-4568-7c32-9782-f69a23782652"
default_rule_id = "01a02d55-d7a6-7df4-99b1-ee21116f52a6"

sections = {}
designations = {}
employees = []

def slugify(text):
    clean = re.sub(r'[^a-zA-Z0-9]+', '_', text.strip()).upper().strip('_')
    return clean[:25] if clean else "DEFAULT"

with open(input_file, mode="r", encoding="utf-8-sig") as f:
    reader = csv.DictReader(f)
    for row in reader:
        emp_id = row.get("Emp_ID", "").strip()
        if not emp_id:
            continue
        
        name = row.get("Employee_Name", "").strip()
        email = row.get("Emp_Mail", "").strip()
        designation = row.get("Emp_Designation", "").strip() or "Staff"
        department = row.get("Emp_Department", "").strip() or "General"
        
        # Split name into first and last name
        parts = name.split(maxsplit=1)
        first_name = parts[0] if parts else name
        last_name = parts[1] if len(parts) > 1 else ""
        
        sec_code = f"SEC_{slugify(department)}"
        if department not in sections:
            sections[department] = sec_code

        des_code = f"DES_{slugify(designation)}"
        if designation not in designations:
            designations[designation] = des_code
            
        employees.append({
            "emp_id": emp_id,
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
            "designation": designation,
            "des_code": des_code,
            "department": department,
            "sec_code": sec_code,
        })

sql_lines = []
sql_lines.append("-- Section Upserts")
for dep, code in sections.items():
    dep_escaped = dep.replace("'", "''")
    sql_lines.append(f"""
INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '{org_id}', '{code}', '{dep_escaped}', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;
""".strip())

sql_lines.append("\n-- Designation Upserts")
for des, code in designations.items():
    des_escaped = des.replace("'", "''")
    sql_lines.append(f"""
INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '{org_id}', '{code}', '{des_escaped}', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;
""".strip())

sql_lines.append("\n-- Employee Upserts")
for emp in employees:
    fn = emp["first_name"].replace("'", "''")
    ln = emp["last_name"].replace("'", "''")
    em_sql = f"'{emp['email'].replace('\'', '\'\'')}'" if emp["email"] else "NULL"
    sec_code = emp["sec_code"]
    des_code = emp["des_code"]
    emp_id = emp["emp_id"]

    sql_lines.append(f"""
DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '{org_id}' AND code = '{sec_code}' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '{org_id}' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '{org_id}' AND code = '{des_code}' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '{org_id}' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '{org_id}', '{emp_id}', '{emp_id}',
        '{fn}', '{ln}', {em_sql}, v_sec_id, v_des_id,
        '{default_rule_id}', CURRENT_DATE, 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    )
    ON CONFLICT (organization_id, attendance_device_user_id) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        email = COALESCE(EXCLUDED.email, employees.email),
        section_id = EXCLUDED.section_id,
        designation_id = EXCLUDED.designation_id,
        updated_at = CURRENT_TIMESTAMP;
END $$;
""".strip())

with open(output_sql, "w", encoding="utf-8") as out:
    out.write("\n\n".join(sql_lines))

print(f"Generated SQL file with {len(sections)} sections, {len(designations)} designations, and {len(employees)} employees.")
