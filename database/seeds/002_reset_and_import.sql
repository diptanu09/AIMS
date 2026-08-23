-- 002_reset_and_import.sql
-- Complete reset of operational/employee/report data and fresh master import.
SET search_path TO "AIMS", public;

BEGIN;

UPDATE users SET employee_id = NULL;

ALTER TABLE IF EXISTS attendance_raw_events DISABLE TRIGGER trg_protect_raw_attendance;


TRUNCATE TABLE
    attendance_sessions,
    attendance_corrections,
    attendance_daily,
    attendance_raw_events,
    attendance_import_batches,
    attendance_processing_jobs,
    employee_section_assignments,
    section_officer_assignments,
    user_section_assignments,
    leave_records,
    scheduled_reports,
    report_runs,
    in_app_notifications,
    audit_logs,
    user_sessions,
    employees,
    sections,
    designations,
    organizations
RESTART IDENTITY CASCADE;

ALTER TABLE IF EXISTS attendance_raw_events ENABLE TRIGGER trg_protect_raw_attendance;


DO $$
DECLARE
    seq RECORD;
BEGIN
    FOR seq IN 
        SELECT sequence_name 
        FROM information_schema.sequences 
        WHERE sequence_schema IN ('AIMS', 'public')
    LOOP
        EXECUTE 'ALTER SEQUENCE ' || quote_ident(seq.sequence_name) || ' RESTART WITH 1';
    END LOOP;
END $$;


INSERT INTO organizations (id, code, name, timezone, active)
VALUES ('01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DEFAULT', 'PAG (A&E), Tripura', 'Asia/Kolkata', TRUE)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;


-- Seed default permissions and roles
INSERT INTO permissions (code, name, module, description) VALUES
('attendance.import', 'Import Attendance', 'ATTENDANCE', 'Upload and import raw attendance punch files'),
('attendance.view.all', 'View All Attendance', 'ATTENDANCE', 'View attendance logs across all sections'),
('attendance.view.section', 'View Section Attendance', 'ATTENDANCE', 'View attendance logs within assigned section'),
('attendance.correct', 'Request Correction', 'ATTENDANCE', 'Submit attendance correction requests'),
('attendance.approve', 'Approve Correction', 'ATTENDANCE', 'Approve or reject attendance correction requests'),
('employee.create', 'Create Employee', 'EMPLOYEE', 'Create new employee master records'),
('employee.update', 'Update Employee', 'EMPLOYEE', 'Update existing employee records'),
('employee.view', 'View Employee', 'EMPLOYEE', 'View employee details'),
('report.generate', 'Generate Reports', 'REPORTING', 'Generate official PDF and Excel reports'),
('report.export', 'Export Reports', 'REPORTING', 'Export raw data and aggregates'),
('section.manage', 'Manage Sections', 'ORGANIZATION', 'Create and modify organizational sections'),
('rule.manage', 'Manage Rules', 'ATTENDANCE', 'Configure attendance rules and shift policies'),
('audit.view', 'View Audit Logs', 'AUDIT', 'Inspect system audit trails'),
('user.manage', 'Manage Users', 'RBAC', 'Manage user accounts and credentials'),
('role.manage', 'Manage Roles', 'RBAC', 'Manage roles and permissions'),
('holiday.manage', 'Manage Holidays', 'CALENDAR', 'Configure calendar, holidays, and weekly offs')
ON CONFLICT (code) DO NOTHING;

INSERT INTO roles (organization_id, code, name, description, is_system)
SELECT o.id, r.role_code, r.role_name, r.role_description, TRUE
FROM organizations o
CROSS JOIN (
    VALUES
        ('SUPER_ADMIN', 'SUPER_ADMIN', 'Full AIMS system access'),
        ('ADMIN', 'ADMIN', 'Administrative access'),
        ('ATTENDANCE_ADMIN', 'ATTENDANCE_ADMIN', 'Attendance administration'),
        ('BO', 'BO', 'Branch / Section Officer access'),
        ('AAO', 'AAO', 'Assistant Accounts Officer access'),
        ('REPORT_USER', 'REPORT_USER', 'Report generation access'),
        ('VIEW_ONLY', 'VIEW_ONLY', 'Read-only access')
) AS r(role_code, role_name, role_description)
WHERE o.code = 'DEFAULT'
ON CONFLICT (organization_id, code) DO NOTHING;

-- Map ALL permissions to SUPER_ADMIN and ADMIN
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
JOIN organizations o ON o.id = r.organization_id
WHERE o.code = 'DEFAULT' AND r.name IN ('SUPER_ADMIN', 'ADMIN')
ON CONFLICT DO NOTHING;


INSERT INTO attendance_rules (id, organization_id, name, shift_start_time, shift_end_time, grace_period_minutes, half_day_min_duration_minutes, full_day_min_duration_minutes, early_exit_threshold_minutes, max_single_session_hours, cross_midnight, effective_from, active)
VALUES (
    '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '01a029f9-4568-7c32-9782-f69a23782652'::uuid,
    'Standard Office Shift',
    '09:30:00', '17:30:00',
    15, 240, 420, 15, 12, FALSE,
    '2026-01-01', TRUE
)
ON CONFLICT (organization_id, name, effective_from) DO NOTHING;


-- Ensure System Admin User (admin / Admin@Aims123!)
INSERT INTO users (
    id, organization_id, username, email, password_hash, full_name, status
) VALUES (
    '01a02dac-692c-7eda-bf7d-8148daee3eb2'::uuid,
    '01a029f9-4568-7c32-9782-f69a23782652'::uuid,
    'admin',
    'admin@aims.internal',
    '$argon2id$v=19$m=19456,t=2,p=1$004Cn63cFXbKorFkkWSRmQ$ZaCtJyujqgR779cGvA4YsgN0Gvxvo2veODUZMPY//Ks',
    'System Administrator',
    'ACTIVE'::user_status
) ON CONFLICT (organization_id, username) DO NOTHING;

-- Assign SUPER_ADMIN role to admin
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.organization_id = u.organization_id AND r.code = 'SUPER_ADMIN'
WHERE u.username = 'admin'
ON CONFLICT DO NOTHING;

-- Master Designations
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT', 'Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('a342a2b4-36e0-4fb9-9085-480a39b9242e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT_GENERAL_A_E', 'Accountant General (A&E)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASSISTANT_SUPERVISOR', 'Assistant Supervisor', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASST_ACCOUNTS_OFFICER', 'Asst. Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('ecf5609e-2177-4a80-a7dc-53c20ed5adf2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT', 'Canteen Attendant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('3fe94c8a-513f-4c39-96fb-48145c879187'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT_OUTSOURCED', 'Canteen Attendant (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('62fc0ad3-6102-4034-9109-6c90e753f2c8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_CLERK', 'Canteen Clerk', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('f91a0789-5093-4461-80e5-66ebfbd399bd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CASUAL_WORKER_TRIPURA', 'Casual Worker Tripura', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('512fff2d-c82c-447e-bf48-65452771c13d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CLERK_TYPIST', 'Clerk Typist', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('71f94ebb-f5cf-425e-9606-943a9532c632'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CONSULTANT_ACCOUNTANT', 'Consultant Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_OUTSOURC', 'Data Entry Operator (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('05948772-7b5b-4bbb-9c33-4be963a4efb9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_A', 'Data Entry Operator Gr A', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('489154f1-2e0a-4fe7-8914-6a96ba283a3c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_B', 'Data Entry Operator Gr B', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('c926ead9-513a-48d0-a01f-673bbf746c0f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_HALWAI', 'Halwai', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('86743cee-16d0-4ffa-9dd5-8fbdc667507d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_JUNIOR_TRANSLATOR', 'Junior Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASK_STAFF', 'Multi Task Staff', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('fe769eae-2d31-4c06-a66b-dc348e94ad59'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASKING_STAFF_OUTSOURC', 'Multi Tasking Staff (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('1af17377-1156-4995-986b-380077b5bee9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_OUTSOURCED_CANTEEN_MANAGER', 'Outsourced Canteen Manager', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('edc1ccd5-4f92-4007-80bd-015071ad889d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ROLL_OUT_SUPPORT_ENGINEER', 'Roll out Support Engineer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('9c8b9a5e-a4d6-48e1-b7fc-d97af334fe3b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTANT', 'Senior Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('ebaca2db-8e57-4de3-bcf5-9587f063447d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTS_OFFICER', 'Senior Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('7a1f7531-67ef-4ba6-b733-8a1faa6efd7f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_DEPUTY_ACCOUNTANT_GEN', 'Senior Deputy Accountant General', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('6799326c-81cc-41c7-affb-411a21186908'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_HINDI_TRANSLATOR', 'Senior Hindi Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('6ea94e07-25dd-41d0-ac5e-9df1109b2123'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER', 'Stenographer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('73b386cf-b408-4c59-82c7-e12f45fb4465'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER_OUTSOURCED', 'Stenographer (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('17c472a1-2f6a-4113-8ec7-b1aed72d3f8c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SUPERVISOR', 'Supervisor', 1, TRUE);

-- Master Sections
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_UNASSIGNED', 'Unassigned / General Pool', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('d48c6328-1f92-41d7-a613-871fee592287'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_SR_AO', 'Sr. AO Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('e55340f8-a24b-4488-b1c6-232f3eef928f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_AAO', 'AAO Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('466b7d57-d5d4-4435-aedf-0f829f18c0fc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_ADMIN', 'Admin Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('858da0d5-ce17-493b-b5a7-4155f8f36275'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_ACCOUNTS', 'Accounts Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('63465aa1-6083-4477-91da-88011108ecac'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_AUDIT', 'Audit Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('20891b0b-4be0-4c3c-b6a3-fa4c5ad23560'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_ESTT', 'Establishment Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('8974f895-6f90-482d-9aa5-ab95dc1f95b9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_PENSION', 'Pension Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('090d7a32-ad52-4257-a923-80780225a26f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_FUND', 'GPF / Fund Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('f6f09638-fed2-4944-a234-cf328967f5ca'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_EDP', 'EDP Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('0b6da6b0-c8f7-4580-b636-5452c97d6bd9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_CANTEEN', 'Departmental Canteen Section', TRUE);

-- Master Employees
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '653ecd7c-ce48-49bf-a269-f65ac53e4d12'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '045677', '045677',
    'Amar', 'Chandra', 'De', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '81b7a1db-6e76-4a0b-83f7-cb6e7bfd9e76'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '716775', '716775',
    'Lokesh', 'Singh', 'Manral', 'manral.lokesh@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '02c3eef5-24e2-4a3b-aee8-015ca0ee3648'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258696', '258696',
    'Nipun', NULL, 'Jain', 'nipunj.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9b0e3732-6d29-42b5-bae1-fcc074b349b5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '419627', '419627',
    'Palash', NULL, 'Banerjee', 'banerjeepalas@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f6b37292-d3ac-4c70-a39a-8b5f241bdb7e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '787234', '787234',
    'Piyush', NULL, 'Prabhakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '85be849e-a724-4833-b6e5-2ee77b6e40fb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382834', '382834',
    'Priyadarshini', NULL, 'Singh', 'prdrshn91113@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7e198d41-87c7-4da2-a912-3d29d59b97b9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991014', '991014',
    'Rahul', NULL, 'Kumar', 'rahulk.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '671a643e-8cc0-4dd1-847d-ca468ae80b2b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '551720', '551720',
    'Rakesh', 'Chandra', 'Srivastav', 'rakeshcs.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5187e626-e9ad-48f6-b7d6-8ca0966a05f0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296861', '296861',
    'Rohit', NULL, 'Yadav', 'rohity.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd6dc4a16-23eb-4f7c-bb68-0e3c64517557'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '457386', '457386',
    'Sourav', NULL, 'Maji', 'souravm.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e8ce5752-aa69-467b-960c-ff9031497954'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '354091', '354091',
    'Suraj', NULL, 'Kishore', 'surajk.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c6dcb08e-6e98-41d0-bd9c-f8c6dbb04b89'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '081342', '081342',
    'Vishal', NULL, 'Verma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7d8a9f52-7daa-42b3-902a-349084f813e7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '925906', '925906',
    'Ashish', NULL, 'Verma', 'ashishv.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c1b846fd-9e8d-400e-bba0-64951bae6c3c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '412074', '412074',
    'Bubai', NULL, 'Mondal', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e2788f42-fcf8-474b-959f-0c063069d0fa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273329', '273329',
    'Dibakar', NULL, 'Das', 'dibakard.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6be0acf6-827b-428f-a7ca-156c64a75221'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '454543', '454543',
    'Dipa', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a5280a8a-1585-4010-8351-3daa1856bba0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '625079', '625079',
    'Gautam', NULL, 'Kumar', 'gautamk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1ff56cf2-d2b1-4d6a-a70d-e36ff558453d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970806', '970806',
    'Jayanti', NULL, 'Saha', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '45adf888-a31a-4d9e-b42d-374d71b739f8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '192266', '192266',
    'Jishan', NULL, 'Choudhuri', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd5b19dd3-ac02-40e2-93d8-ee1d74640152'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '570806', '570806',
    'Keya', NULL, 'Sarkar', 'keyas.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '10cf60bc-fe3c-4808-8382-7fa905d9c8f0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970592', '970592',
    'Kishlay', NULL, 'Raj', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '11019aa3-8eda-41cc-a951-58fb651673ff'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '222819', '222819',
    'Mohammad', 'Naqi', 'Ali', 'naqimadina12@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '34bbb6a9-1698-45b4-8536-ddd5e824bd6c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '229834', '229834',
    'Paramita', NULL, 'Bhattacharjee', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6241cb95-9076-4e3d-8a7e-61f9eaa4995a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '789991', '789991',
    'Partha', NULL, 'Debnath', 'parthad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f0f9455d-ec26-4be3-9a9b-e2635d63e8fc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '008233', '008233',
    'Pilan', NULL, 'Ngullie', 'pilann.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '743dcfd5-8402-4ade-8e44-e4fc277d0d59'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '275804', '275804',
    'Pranav', NULL, 'Kumar', 'pranavk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b681461f-7c32-404c-acd8-bef7bb8ff6c4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296851', '296851',
    'Rajeev', NULL, 'Kumar', 'rajeevkumarag1985@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '10b2c805-b922-495c-96db-cb52604af66d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '405349', '405349',
    'Rajeev', NULL, 'Kumar', 'rajeevkr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '232e34d9-576b-4715-86c4-8d5a8392c20c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786890', '786890',
    'Subham', NULL, 'Ghosh', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1fb8da91-2f71-4b6c-8a65-d5a6b39831e2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '642211', '642211',
    'Sudip', NULL, 'Barman', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '49497be7-fa74-4094-9995-6d4c2b3bc571'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '482594', '482594',
    'Sunil', NULL, 'Kumar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4d52482a-7ad9-4e93-93ca-30973be4bc1a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '515186', '515186',
    'Udiyan', NULL, 'Bose', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f83bff18-b6dc-47ac-9581-cfb2860b7cfe'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c1e05498-265b-42dd-8511-af4c9b8af30b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '871058', '871058',
    'Ranendu', NULL, 'Sarkar', 'sarkarr@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'a342a2b4-36e0-4fb9-9085-480a39b9242e'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b39180bb-35ff-4773-9ac4-6fb2a78c8771'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '202868', '202868',
    'Amit', NULL, 'Gaurav', 'amitgaurav.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'baef3247-4108-4365-9c44-1bbedd61465b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd3a27180-40df-461c-9100-b6e8498e674f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '231116', '231116',
    'Anjana', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e53b993f-82bf-457c-842c-1d8b5d3aa64b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '587084', '587084',
    'Ankur', NULL, 'Debbarma', 'ankurd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c420e359-6f99-4ae7-89e7-4c39d70505fb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '863010', '863010',
    'Babul', NULL, 'Bhowmik', 'babulb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a3073e35-5251-42b5-b83f-adc52f9cbf57'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545651', '545651',
    'Banani', NULL, 'Das', 'babanib.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4a1a80f7-ba9c-41d2-afd2-80a1713210b3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '788426', '788426',
    'Biswajit', NULL, 'Datta', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '621a02e4-fcf4-4ee6-8803-bd0ed01f77b2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '802702', '802702',
    'Biswanath', NULL, 'Chakraborty', 'biswanathc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c051b845-a5de-4ae7-8c58-fe5f8509bd2e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '604228', '604228',
    'Champakali', NULL, 'Debbarma', 'champa68@rediffmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '67d90fbc-2c6b-4447-8b2e-aaf0e4b692c3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510884', '510884',
    'Chandan', NULL, 'Debnath', 'chandand.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f3ce5d9a-224e-415f-b3e4-dbc727b7878a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '310789', '310789',
    'Chhanda', 'Banik', 'Bhaumik', 'chhandab.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '98a01771-03bc-4a9d-9c75-39e8c1c0f5e0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545958', '545958',
    'Debabrata', NULL, 'Bhattacharjee', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd718b5c7-cb61-4fee-9dd3-eb25416dc510'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '452643', '452643',
    'Debasis', NULL, 'Biswas', 'debasisb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd86dfa49-c53e-44bd-9328-4980f0d919c8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '177893', '177893',
    'Malabika', NULL, 'Rakshit', 'mablabikar.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '75f24a92-070b-4039-8b0a-763634171627'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '300159', '300159',
    'Mrityunjoy', NULL, 'Bhowmik', 'mrityunjoyb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '27d26051-7bcf-4ea6-89fd-3aea45ef04e7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '280235', '280235',
    'Pradip', NULL, 'Karmakar', 'pradipk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '442959ab-e09d-49e3-bc8d-8e14a26336c8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '483866', '483866',
    'Prasenjit', NULL, 'Pal', 'prasenjitp.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a74ca1ae-3286-472a-9fc6-f4c6c97368c5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '558271', '558271',
    'Raj', 'Kumar', 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a2062566-6014-48f1-b3d3-e08fc7f96484'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '605543', '605543',
    'Rama', NULL, 'Bhattacharya', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'eb108408-521a-48c2-aaa2-2a5866804761'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '265793', '265793',
    'Sanjoy', 'Krishna', 'Debbarma', 'sanjoykd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b2a83dab-e7bc-4dc6-90e6-02071d18082e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '738761', '738761',
    'Satish', NULL, 'Debbarma', 'satish71debbarma@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'afac1f7e-3723-4ea6-ab13-8b4ccfc2ad81'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '318974', '318974',
    'Srilekha', NULL, 'Dey', 'srilekhad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6153a465-1667-4840-a946-150b95e249c2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '502040', '502040',
    'Subh', 'Karan', 'Chauhan', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '77f337e1-584d-4f21-b156-27383cab99aa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '603680', '603680',
    'Suchana', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6a395027-2086-4298-94fd-d73edaca50b2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '137660', '137660',
    'Sudha', 'Ranjan', 'Debbarma', 'sudharanjand.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '86d09d34-20d6-45de-b9d3-fac32a819450'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '423533', '423533',
    'Sukhendu', NULL, 'Bhaumik', 'sukhendub.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3d942cd8-59a4-41e7-934b-33889e6c3d3c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '090908', '090908',
    'Tapan', 'Kumar', 'Sarkar', 'tapankumars.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9610d6a-81bd-46db-a73a-16331f0c3a6c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '12cbcf19-6818-4dda-ab3a-aeb14d20b8d3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '149565', '149565',
    'Chandan', 'Kumar', 'Das', 'Chandankd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ecf5609e-2177-4a80-a7dc-53c20ed5adf2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2390b7b8-5e6b-49f9-aab8-785e9ceab2a6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '037947', '037947',
    'Ratan', NULL, 'Ghosh', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ecf5609e-2177-4a80-a7dc-53c20ed5adf2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3e25901f-5912-47e4-9069-687da5860f55'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '711741', '711741',
    'Nayan', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '3fe94c8a-513f-4c39-96fb-48145c879187'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '205dd969-67ef-4341-83ea-913bfe34d5d5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '060574', '060574',
    'Shahil', NULL, 'Singha', 'shahilsingha321@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '3fe94c8a-513f-4c39-96fb-48145c879187'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4b0dadb8-197c-4a37-9a40-720979ce6aa8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '998024', '998024',
    'Swapan', NULL, 'Bhowmik', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '62fc0ad3-6102-4034-9109-6c90e753f2c8'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7bbb8dcf-ff3c-4b84-b6c8-9684c8736f9f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '586589', '586589',
    'Bimal', NULL, 'Sarkar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f91a0789-5093-4461-80e5-66ebfbd399bd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1163bdd0-8265-4c3e-b5a1-2fd66f7b1307'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '969535', '969535',
    'Gopal', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f91a0789-5093-4461-80e5-66ebfbd399bd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4b0690d1-8777-47b1-930d-174890113810'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '942482', '942482',
    'Raja', NULL, 'Biswas', 'rajabiswas16696@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f91a0789-5093-4461-80e5-66ebfbd399bd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e332e293-108e-4c40-b6ef-3367266ebc84'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '756473', '756473',
    'Shibu', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f91a0789-5093-4461-80e5-66ebfbd399bd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '67fea134-27bd-4a97-89af-ee4c72a03234'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '859252', '859252',
    'Sumit', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f91a0789-5093-4461-80e5-66ebfbd399bd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7ac3fda6-ac75-4910-8826-7b23c15054e9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258186', '258186',
    'Sumita', 'Bose', 'Dey', 'sumitab.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '512fff2d-c82c-447e-bf48-65452771c13d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '404a8917-800f-4c45-80a0-121c68e70291'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '792890', '792890',
    'Saurabh', NULL, 'Das', 'saurabhd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '512fff2d-c82c-447e-bf48-65452771c13d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7eec5780-31fc-4202-86e3-6afad3a2ea32'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '992660', '992660',
    'Pankaj', 'Kumar', 'Sarkar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '71f94ebb-f5cf-425e-9606-943a9532c632'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '22f5a005-ded7-425a-a0ce-a60cb600bad9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '126173', '126173',
    'Dipankar', NULL, 'Debnath', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '71f94ebb-f5cf-425e-9606-943a9532c632'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ab819e2e-d95c-4b02-834a-0fb4b7fab709'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '223506', '223506',
    'Thaingla', NULL, 'Mog', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '627623d5-2bff-4efc-bd70-a396692205b7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '541791', '541791',
    'Subhranil', NULL, 'Debroy', 'subhranil191@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7cd7bf75-b9d5-43de-b274-534358d50ec9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786106', '786106',
    'Diptanu', NULL, 'Roy', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a7074a50-f26f-481d-9b5c-e79eb5f5ef79'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '351307', '351307',
    'Gobinda', NULL, 'Bhowmik', 'bhowmikgobinda19@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '62fa4d76-eb3c-4cb7-880e-9bdb32bc13bc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '073976', '073976',
    'Himanshu', NULL, 'Khokhar', 'himnshuk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '489154f1-2e0a-4fe7-8914-6a96ba283a3c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '697b3d09-6c13-4ae0-9c11-c4d14748fe96'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '944337', '944337',
    'Sayani', NULL, 'Nandy', 'sayanin.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '05948772-7b5b-4bbb-9c33-4be963a4efb9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3ab9fe78-b02f-4bf8-8625-de108fe67608'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '358367', '358367',
    'Pramod', NULL, 'Kumar', 'pramodp.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '489154f1-2e0a-4fe7-8914-6a96ba283a3c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5b3567d1-fe6c-4d89-9a99-676d3a02a650'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '464696', '464696',
    'Ankan', NULL, 'Paul', 'paulankan16@gamil.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e8829bc7-b477-451b-8ef8-afaa4716a697'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '611223', '611223',
    'Hritam', NULL, 'Bhattacharyya', 'hrikbhattacharyya@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd1312646-791b-4b4e-8b47-3faeb751e6d2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '260758', '260758',
    'Kuldeep', NULL, 'Debnath', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '81325d63-9296-415a-9ffd-a3472e6d3683'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '773969', '773969',
    'Pranay', NULL, 'Singha', 'pranay.singha2011@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'de1cacf1-1120-4566-a1af-03b79c21392d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '432043', '432043',
    'Dipak', NULL, 'Kumar', 'deepakk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '489154f1-2e0a-4fe7-8914-6a96ba283a3c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4b9cd115-6de0-4563-810e-3ec49b84d88d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '425230', '425230',
    'Gaurav', 'Kumar', 'Tomar', 'gauravkumart.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '489154f1-2e0a-4fe7-8914-6a96ba283a3c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9ac9a66d-6658-45fb-8a43-ad0b09fbfccc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '168844', '168844',
    'Rajeev', NULL, 'Ranjan', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '489154f1-2e0a-4fe7-8914-6a96ba283a3c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd98ba84b-4689-487e-a5ad-674720d8f57f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '322963', '322963',
    'Arindam', NULL, 'Chakraborty', 'carindam410@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '281be55c-ba18-421b-bb1f-f948853faf4c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3eade3cd-d881-4701-a1c9-b63f2a59a383'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '774775', '774775',
    'Ashish', NULL, 'Chakraborty', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c926ead9-513a-48d0-a01f-673bbf746c0f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0d274288-9d5e-4125-b983-8201ad0f0e88'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '418960', '418960',
    'Ankita', NULL, 'Koiri', 'ankita.anp.au@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '86743cee-16d0-4ffa-9dd5-8fbdc667507d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5a68153f-131e-454c-8608-5867781f2230'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089422', '089422',
    'Gita', 'Rani Das', 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3af76f51-da06-4155-ae2f-4840f95239f2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '776568', '776568',
    'Haradhan', NULL, 'Dey', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7882b08a-79ef-4893-9d5f-994fcb5fc40a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '595944', '595944',
    'Kshitish', 'Chandra', 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '72daee8b-723a-4fa1-a112-10523f89e59f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '705463', '705463',
    'Nitai', 'Chandra', 'Saha', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c6ba4bab-6af0-4aeb-aa2f-540c2e89fbb6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '867836', '867836',
    'Rajani', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a8d63197-6d1f-4cce-9ff3-4ba62b21ffb5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '059931', '059931',
    'Rohit', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'be66690b-b32f-4a18-973f-735b477df974'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '537725', '537725',
    'Samir', NULL, 'Sutradhar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '96bd98cc-24ff-4392-adc3-e867732c860f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '837817', '837817',
    'Sanjoy', 'Kumar', 'Deb', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '34263190-6b98-4709-a0c0-9d2f76aa34e0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '660611', '660611',
    'Siman', NULL, 'Rakshit', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c68d553e-731c-4b60-9569-4ad7a4251915'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '675239', '675239',
    'Sudhir', NULL, 'Uria', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd161aa1c-b06b-4318-ba94-1ee7c8584545'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '977332', '977332',
    'Swadesh', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '68522b20-b513-42b0-aa84-31eaf27e613c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '554361', '554361',
    'Bijoy', NULL, 'Shil', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'fe769eae-2d31-4c06-a66b-dc348e94ad59'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7bf8bb63-5a03-4a46-821c-ca267c103287'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '814841', '814841',
    'Chiranjit', NULL, 'Sutradhar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'fe769eae-2d31-4c06-a66b-dc348e94ad59'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8de291b1-ea73-4ae2-aba3-999a884d2280'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '119700', '119700',
    'Koushik', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'fe769eae-2d31-4c06-a66b-dc348e94ad59'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ab7588f0-801d-4c17-aca5-efaf12822085'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089261', '089261',
    'Manjushree', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'fe769eae-2d31-4c06-a66b-dc348e94ad59'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0501afd8-d2e2-4e70-b1cf-6094e64158c9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991831', '991831',
    'Sagar', NULL, 'Majumder', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'fe769eae-2d31-4c06-a66b-dc348e94ad59'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ce236545-075b-41b0-be40-7ecd9368f862'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '103575', '103575',
    'Sujal', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'fe769eae-2d31-4c06-a66b-dc348e94ad59'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd5775831-50ae-42c1-9ae9-79e1c716437e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '692945', '692945',
    'Biswajit', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7f8192b1-7df0-4de7-9f5b-e6538cc76610'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '221497', '221497',
    'Sudip', NULL, 'Biswas', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1d742691-8030-4b28-82a1-6ba6520e14c6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '723614', '723614',
    'Asam', 'Ray', 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd35bde8b-bde8-4168-b6c3-da524ca47271'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '334054', '334054',
    'Babul', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '03334e39-8573-47d4-b5f1-2df6883fee16'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '069114', '069114',
    'Charan', 'Manik', 'Halam', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f8c74a23-c90a-49fd-98c0-36a5131d4c09'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '266707', '266707',
    'Rajesh', NULL, 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9f5148c4-42f3-4c56-97f6-42bbd83a14ba'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '496988', '496988',
    'Sabitri', 'Podder', 'Roy', 'sabitripodderr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7737f836-991a-4045-a4fc-fcb2c201967f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '929d1f96-672f-4528-9df1-a4c3f0b82fc3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '829528', '829528',
    'Goutam', NULL, 'Roy', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f91a0789-5093-4461-80e5-66ebfbd399bd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9acec630-7d5c-48e5-ba20-b64d3cc1c344'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273300', '273300',
    'Arpan', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'fe769eae-2d31-4c06-a66b-dc348e94ad59'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6a2fbd4d-1b73-44cd-940e-156ce4d7b240'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '117874', '117874',
    'Jadab', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'fe769eae-2d31-4c06-a66b-dc348e94ad59'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a07998e9-944d-4a6e-915f-c360794c82f5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '989373', '989373',
    'Rajesh', NULL, 'Chakraborty', 'chakraj27@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '1af17377-1156-4995-986b-380077b5bee9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '29b1bfb3-adeb-4a11-b1ba-17b54b4b9a4a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '878245', '878245',
    'Diptanu', NULL, 'Deb', 'deb.diptanu09@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'edc1ccd5-4f92-4007-80bd-015071ad889d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'eed7ab96-2107-4edd-838e-d4743f999530'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '287245', '287245',
    'Jhuntu', NULL, 'Dasgupta', 'jhuntudd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ebaca2db-8e57-4de3-bcf5-9587f063447d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '19b8cc8e-e022-46b4-912e-49b94c337784'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '083321', '083321',
    'Nabajyoti', NULL, 'Debnath', 'nabajyotid.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9c8b9a5e-a4d6-48e1-b7fc-d97af334fe3b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd840033b-bb19-4372-bf2a-a8d7660b6447'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '508317', '508317',
    'Samar', 'Chandra', 'Deb', 'samarchandrad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9c8b9a5e-a4d6-48e1-b7fc-d97af334fe3b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9c6d3257-6ea7-4ded-8fea-7a03d36da645'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '599624', '599624',
    'Santosh', NULL, 'Das', 'das71santosh@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9c8b9a5e-a4d6-48e1-b7fc-d97af334fe3b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e59b856e-8fff-4438-b78a-bddc5a218b2b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '677853', '677853',
    'Soumen', NULL, 'Banik', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9c8b9a5e-a4d6-48e1-b7fc-d97af334fe3b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3d25b2e3-0caa-4d50-8282-e7a546c0c677'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '404232', '404232',
    'Ajoy', NULL, 'Dutta', 'ajoyd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ebaca2db-8e57-4de3-bcf5-9587f063447d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c7624708-4ade-472e-ad85-18ac546c06db'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '567588', '567588',
    'Debabrato', NULL, 'Chowdhury', 'debabratoc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ebaca2db-8e57-4de3-bcf5-9587f063447d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6df10c16-b199-4ba0-8c19-d2581c596449'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '799528', '799528',
    'Subodh', NULL, 'Debbarma', 'subodhd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ebaca2db-8e57-4de3-bcf5-9587f063447d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '29c33035-c1f0-4434-a0ef-4bfeff080894'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '923432', '923432',
    'Uttam', NULL, 'Chakraborty', 'uttamc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ebaca2db-8e57-4de3-bcf5-9587f063447d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0bc279c7-ef22-4557-81a1-9b0a53bb8ad9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '919704', '919704',
    'Tanushree', NULL, 'Biswas', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7a1f7531-67ef-4ba6-b733-8a1faa6efd7f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bf82474d-3beb-4fe9-b61e-e772b0d7e7aa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '326801', '326801',
    'Dipannita', NULL, 'Das', 'dipannitad.kol.pdac@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '6799326c-81cc-41c7-affb-411a21186908'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'deb347b0-7b79-4295-84ce-d451cfc4a3a1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510617', '510617',
    'Bishu', NULL, 'Nandi', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9c8b9a5e-a4d6-48e1-b7fc-d97af334fe3b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'cef21bc2-588b-45b0-9925-39296816e467'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382713', '382713',
    'Subhrajit', NULL, 'Roy', 'subhrajitr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9c8b9a5e-a4d6-48e1-b7fc-d97af334fe3b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'da3ef4ba-83cf-401b-a67d-7062714598a4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '980071', '980071',
    'Subrata', 'Das', 'Choudhury', 'chowdhurysd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ebaca2db-8e57-4de3-bcf5-9587f063447d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'cc09d4b0-2842-46df-8b14-5a209fda330f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '952380', '952380',
    'Rajashree', NULL, 'Chakraborty', 'rajashreec.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9c8b9a5e-a4d6-48e1-b7fc-d97af334fe3b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ade6db1b-80a0-4390-8c6a-02c56b23977b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '109614', '109614',
    'Sanjay', 'Kumar', 'Yadav', 'sanjoykumary.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '6ea94e07-25dd-41d0-ac5e-9df1109b2123'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '60084d60-2c11-4376-9544-a4a16927fa10'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '795304', '795304',
    'Arpan', NULL, 'Shil', 'arpanshil.agt@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '73b386cf-b408-4c59-82c7-e12f45fb4465'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7d3cab35-8399-4b3b-9de7-8dc4d263a826'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '042174', '042174',
    'Pradip', 'Kumar', 'Nandi', 'pradipkn.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '17c472a1-2f6a-4113-8ec7-b1aed72d3f8c'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);

COMMIT;