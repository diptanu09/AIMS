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
VALUES ('915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT', 'Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('0bdde63f-7736-48be-8d61-34582860f107'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT_GENERAL_A_E', 'Accountant General (A&E)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASSISTANT_SUPERVISOR', 'Assistant Supervisor', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASST_ACCOUNTS_OFFICER', 'Asst. Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('e9a14955-87d8-4883-8a4c-31e5fa863ad0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT', 'Canteen Attendant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('a227b0d3-db12-4606-91bf-c118e7499478'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT_OUTSOURCED', 'Canteen Attendant (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('835eae31-c580-4a1e-b028-8b209ece82e1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_CLERK', 'Canteen Clerk', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('b9d805d6-5554-4dad-a00c-a2f099aa09b1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CASUAL_WORKER_TRIPURA', 'Casual Worker Tripura', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('39ca8528-3de0-4588-ad14-a2f6f37a1a85'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CLERK_TYPIST', 'Clerk Typist', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('92a35797-4c98-4557-a8e8-7739bcfc5a48'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CONSULTANT_ACCOUNTANT', 'Consultant Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_OUTSOURC', 'Data Entry Operator (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('16e288a4-d388-4b7d-8746-93310ccc31d9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_A', 'Data Entry Operator Gr A', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('d7b8ce8e-684b-4bcb-b966-2d725753d2a8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_B', 'Data Entry Operator Gr B', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('f9e3cee5-5c22-40a6-87c2-c9b30ed3bdfc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_HALWAI', 'Halwai', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('20abceba-8372-40cd-8275-49ff4673b341'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_JUNIOR_TRANSLATOR', 'Junior Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASK_STAFF', 'Multi Task Staff', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('4c66d4ae-b308-4497-a209-31c93fbf02f7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASKING_STAFF_OUTSOURC', 'Multi Tasking Staff (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('c45df739-b03c-480d-b028-a9b2a6dbd0fb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_OUTSOURCED_CANTEEN_MANAGER', 'Outsourced Canteen Manager', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('2b0ab5fe-f5c0-47c9-ae8a-9633c7491386'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ROLL_OUT_SUPPORT_ENGINEER', 'Roll out Support Engineer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('0736fdde-90b6-43ab-9776-9c1dfce75b1d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTANT', 'Senior Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('b31e7b59-d4ee-4346-9c34-0b95b4aad3de'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTS_OFFICER', 'Senior Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('8cb043ce-54d1-4230-ac42-f8d4440a2a5f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_DEPUTY_ACCOUNTANT_GEN', 'Senior Deputy Accountant General', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('3490705f-d370-4f17-9593-db86b017c0e3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_HINDI_TRANSLATOR', 'Senior Hindi Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('f72ffe7e-8b09-4df0-889f-6d99c992b458'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER', 'Stenographer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('f6197663-454e-4d7e-a5e5-30297501da04'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER_OUTSOURCED', 'Stenographer (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('7fe1595a-30a0-4237-96b2-a36a90acfdb4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SUPERVISOR', 'Supervisor', 1, TRUE);

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
    '81ee40b1-5ea3-492a-8fb9-f458e1250de9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '045677', '045677',
    'Amar', 'Chandra', 'De', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '79927797-4df0-4846-a016-658ecfe8acc9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '716775', '716775',
    'Lokesh', 'Singh', 'Manral', 'manral.lokesh@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ad7802bd-d57a-45be-b1d0-a382bdd58910'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258696', '258696',
    'Nipun', NULL, 'Jain', 'nipunj.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '066ddc18-0fd4-4237-aa59-8164ea293db1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '419627', '419627',
    'Palash', NULL, 'Banerjee', 'banerjeepalas@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '377980dd-8b3f-48e7-badf-7d4a51a5c133'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '787234', '787234',
    'Piyush', NULL, 'Prabhakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '28aa074d-6b6e-4673-9f25-1f759e91397c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382834', '382834',
    'Priyadarshini', NULL, 'Singh', 'prdrshn91113@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '37bcfd73-37be-4a80-b014-06a8aca6924b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991014', '991014',
    'Rahul', NULL, 'Kumar', 'rahulk.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1b31037f-9c19-46d0-bdb5-578159165b2c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '551720', '551720',
    'Rakesh', 'Chandra', 'Srivastav', 'rakeshcs.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bb3933f4-407e-454f-a50e-2aab40bd2596'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296861', '296861',
    'Rohit', NULL, 'Yadav', 'rohity.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6cae8e37-f91b-49b3-894b-d4a02148e39c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '457386', '457386',
    'Sourav', NULL, 'Maji', 'souravm.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5f83671c-0f0c-41b0-bb72-74fbdb3de063'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '354091', '354091',
    'Suraj', NULL, 'Kishore', 'surajk.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '038c553e-6e74-4a69-a37b-023c27f79b6f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '081342', '081342',
    'Vishal', NULL, 'Verma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f7af6102-e4c2-49d2-983d-24cacfdaccef'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '925906', '925906',
    'Ashish', NULL, 'Verma', 'ashishv.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c7a2fc0a-7778-4a60-bb19-9038404ff662'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '412074', '412074',
    'Bubai', NULL, 'Mondal', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8c8067fd-8667-4b61-98ae-bd1119eeda28'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273329', '273329',
    'Dibakar', NULL, 'Das', 'dibakard.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd79e8da5-d1a4-4501-821f-83ad0e87e956'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '454543', '454543',
    'Dipa', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f5a8f9dc-40f3-46ba-a28c-109f3df1ec28'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '625079', '625079',
    'Gautam', NULL, 'Kumar', 'gautamk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1496a991-6583-47a0-8175-d694745fa110'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970806', '970806',
    'Jayanti', NULL, 'Saha', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a897a234-c819-46bc-bff8-a124f08be9a8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '192266', '192266',
    'Jishan', NULL, 'Choudhuri', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '937a3d2f-7ebf-40b8-be64-bf8713569661'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '570806', '570806',
    'Keya', NULL, 'Sarkar', 'keyas.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e23fae65-7520-4076-b1f4-111fd8ad83b8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970592', '970592',
    'Kishlay', NULL, 'Raj', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '76e0f6d4-dc55-460b-a3b6-b7a762005d21'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '222819', '222819',
    'Mohammad', 'Naqi', 'Ali', 'naqimadina12@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0e02a422-2aa0-4f89-be2d-a2a8757e6544'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '229834', '229834',
    'Paramita', NULL, 'Bhattacharjee', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '496a7b47-aac6-4223-8008-9ed9ab945708'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '789991', '789991',
    'Partha', NULL, 'Debnath', 'parthad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ef2fad76-c587-469f-84a5-ff6cc11fae9b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '008233', '008233',
    'Pilan', NULL, 'Ngullie', 'pilann.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0f59a039-393a-4a67-898b-993b8b8c8676'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '275804', '275804',
    'Pranav', NULL, 'Kumar', 'pranavk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a813d0fc-8d26-4bf0-b817-360f6e8f3071'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296851', '296851',
    'Rajeev', NULL, 'Kumar', 'rajeevkumarag1985@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9bea7f60-b694-46a9-ad4c-a49f74e09cd7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '405349', '405349',
    'Rajeev', NULL, 'Kumar', 'rajeevkr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3c8ad4ca-b92e-49dc-8cd0-d9d30048f183'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786890', '786890',
    'Subham', NULL, 'Ghosh', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'dab6eecc-46c1-452c-b7cd-488a4765c2f5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '642211', '642211',
    'Sudip', NULL, 'Barman', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '44248bd7-786f-4edf-a03d-e2115b1d05a9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '482594', '482594',
    'Sunil', NULL, 'Kumar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6fa08079-0100-4502-958f-680124a3c9fe'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '515186', '515186',
    'Udiyan', NULL, 'Bose', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '915fd0ef-4b46-4cf4-9ee5-20176694f7f9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'eb7a3f6e-f792-4cbd-8e89-b0524997c107'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '871058', '871058',
    'Ranendu', NULL, 'Sarkar', 'sarkarr@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '0bdde63f-7736-48be-8d61-34582860f107'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f562cf9a-a1cd-43ee-a5de-01386d713621'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '202868', '202868',
    'Amit', NULL, 'Gaurav', 'amitgaurav.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '23062066-8b09-4717-833e-e88f6bf092c2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '32b15190-2f54-484d-8b5a-0ab89d6d65a3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '231116', '231116',
    'Anjana', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7365bd47-406b-482c-b2bd-d1fbef93c319'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '587084', '587084',
    'Ankur', NULL, 'Debbarma', 'ankurd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c80a58ed-ae94-4ce7-81d0-3135c95929c3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '863010', '863010',
    'Babul', NULL, 'Bhowmik', 'babulb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a0e9cb07-05cd-4fbe-b5a9-1fc11b925883'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545651', '545651',
    'Banani', NULL, 'Das', 'babanib.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5f50ae39-35ba-474f-a69d-e5baf7edb5e5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '788426', '788426',
    'Biswajit', NULL, 'Datta', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3764ca13-02f2-4408-97d0-e7976248c5e0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '802702', '802702',
    'Biswanath', NULL, 'Chakraborty', 'biswanathc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '08de7a18-ad15-4294-885b-59a52435d9c3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '604228', '604228',
    'Champakali', NULL, 'Debbarma', 'champa68@rediffmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1514401d-4d77-4658-bafe-90d54a202d79'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510884', '510884',
    'Chandan', NULL, 'Debnath', 'chandand.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8761fbe0-6ec8-4783-9257-6b17e0f23b78'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '310789', '310789',
    'Chhanda', 'Banik', 'Bhaumik', 'chhandab.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fab4a04b-de5a-47c6-b481-5d5c095fda3c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545958', '545958',
    'Debabrata', NULL, 'Bhattacharjee', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '74323fe8-9c74-4202-9947-8bcfda1e6520'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '452643', '452643',
    'Debasis', NULL, 'Biswas', 'debasisb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c434c435-7127-4f61-82b0-d5a860af0994'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '177893', '177893',
    'Malabika', NULL, 'Rakshit', 'mablabikar.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e41dcfd0-7ae4-4a4e-85cd-4591b536ca42'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '300159', '300159',
    'Mrityunjoy', NULL, 'Bhowmik', 'mrityunjoyb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b4ea3a4f-e0a5-42a8-8c54-81410a27e6c0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '280235', '280235',
    'Pradip', NULL, 'Karmakar', 'pradipk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3c9cab65-c7c6-40f2-ac49-f1f3992ab5dc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '483866', '483866',
    'Prasenjit', NULL, 'Pal', 'prasenjitp.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1e5ce40c-b78d-4f1c-8f26-958b8f63036e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '558271', '558271',
    'Raj', 'Kumar', 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'cbae4a73-63af-49a8-82bb-d57aa771bd0e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '605543', '605543',
    'Rama', NULL, 'Bhattacharya', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '763f6a78-8de2-41f5-a812-011f17c1ab56'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '265793', '265793',
    'Sanjoy', 'Krishna', 'Debbarma', 'sanjoykd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e1625d76-f5b8-4a48-924e-2aeb33b1a255'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '738761', '738761',
    'Satish', NULL, 'Debbarma', 'satish71debbarma@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3966c272-2ed6-4386-ad0b-28238bb4240d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '318974', '318974',
    'Srilekha', NULL, 'Dey', 'srilekhad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1e44a0ac-e290-4025-ac35-a23078221359'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '502040', '502040',
    'Subh', 'Karan', 'Chauhan', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '73f4fd7e-5dfb-4aee-b8bc-646500af955f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '603680', '603680',
    'Suchana', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ae2f7b88-0248-46e7-a02a-afd20f0f4865'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '137660', '137660',
    'Sudha', 'Ranjan', 'Debbarma', 'sudharanjand.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7349ce7e-1e31-41e3-ae1d-5c5d3119f1e1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '423533', '423533',
    'Sukhendu', NULL, 'Bhaumik', 'sukhendub.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b7ddde84-da9b-428b-95f7-67d2eaf553aa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '090908', '090908',
    'Tapan', 'Kumar', 'Sarkar', 'tapankumars.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '46a748a7-ff1c-427a-a83c-b7f50e6cb2eb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '80e95075-8e82-4130-8955-f2b3d71ca875'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '149565', '149565',
    'Chandan', 'Kumar', 'Das', 'Chandankd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'e9a14955-87d8-4883-8a4c-31e5fa863ad0'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2c17d4c9-b88d-45a8-a84a-43b88f45824f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '037947', '037947',
    'Ratan', NULL, 'Ghosh', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'e9a14955-87d8-4883-8a4c-31e5fa863ad0'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '77219860-b249-44db-b092-963621f05fc5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '711741', '711741',
    'Nayan', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'a227b0d3-db12-4606-91bf-c118e7499478'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ebf33fbe-425d-4ec4-88ed-83006968366a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '060574', '060574',
    'Shahil', NULL, 'Singha', 'shahilsingha321@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'a227b0d3-db12-4606-91bf-c118e7499478'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '21b3c465-3d2d-4de6-9db9-33509639bcc3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '998024', '998024',
    'Swapan', NULL, 'Bhowmik', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '835eae31-c580-4a1e-b028-8b209ece82e1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '78021b6e-46f6-43fa-a0a1-087770299854'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '586589', '586589',
    'Bimal', NULL, 'Sarkar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b9d805d6-5554-4dad-a00c-a2f099aa09b1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ca31cd21-f764-45ae-8dde-9b4d006488e3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '969535', '969535',
    'Gopal', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b9d805d6-5554-4dad-a00c-a2f099aa09b1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6839e022-b05d-4609-a34c-45fe706a8763'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '942482', '942482',
    'Raja', NULL, 'Biswas', 'rajabiswas16696@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b9d805d6-5554-4dad-a00c-a2f099aa09b1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd652a75a-c095-42fe-aa78-6302e15e0994'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '756473', '756473',
    'Shibu', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b9d805d6-5554-4dad-a00c-a2f099aa09b1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4f3c7af8-2391-4c6e-aa40-cbad25e9e651'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '859252', '859252',
    'Sumit', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b9d805d6-5554-4dad-a00c-a2f099aa09b1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '21bc3df5-2c1e-4186-879d-6a58d1c5c1bf'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258186', '258186',
    'Sumita', 'Bose', 'Dey', 'sumitab.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '39ca8528-3de0-4588-ad14-a2f6f37a1a85'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '29c78135-63bf-4e30-9b97-c2aa920266c9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '792890', '792890',
    'Saurabh', NULL, 'Das', 'saurabhd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '39ca8528-3de0-4588-ad14-a2f6f37a1a85'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3ad4217b-1ae3-43d9-aa30-ce5f6898c5ec'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '992660', '992660',
    'Pankaj', 'Kumar', 'Sarkar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '92a35797-4c98-4557-a8e8-7739bcfc5a48'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd6c10222-9dd3-4970-9282-8fe4877ab344'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '126173', '126173',
    'Dipankar', NULL, 'Debnath', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '92a35797-4c98-4557-a8e8-7739bcfc5a48'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7c9a787b-6363-4b61-aa33-a0f6d2a72312'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '223506', '223506',
    'Thaingla', NULL, 'Mog', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0ed28213-54ff-417b-999f-6dcb3d7ef21c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '541791', '541791',
    'Subhranil', NULL, 'Debroy', 'subhranil191@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7da3124f-c278-4cb0-b2ab-01975d7bffde'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786106', '786106',
    'Diptanu', NULL, 'Roy', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c459377c-3c8a-4b9d-aa51-ed41fe09412e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '351307', '351307',
    'Gobinda', NULL, 'Bhowmik', 'bhowmikgobinda19@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f08de29d-2e54-4436-91db-a7e10b6f6967'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '073976', '073976',
    'Himanshu', NULL, 'Khokhar', 'himnshuk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd7b8ce8e-684b-4bcb-b966-2d725753d2a8'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'dfae433f-9982-47b2-948e-903dfdfa9d46'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '944337', '944337',
    'Sayani', NULL, 'Nandy', 'sayanin.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '16e288a4-d388-4b7d-8746-93310ccc31d9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '100969eb-93c4-450f-97f9-e848166497a4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '358367', '358367',
    'Pramod', NULL, 'Kumar', 'pramodp.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd7b8ce8e-684b-4bcb-b966-2d725753d2a8'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '217c29f9-6063-4da3-bac6-8d3aac9cf64c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '464696', '464696',
    'Ankan', NULL, 'Paul', 'paulankan16@gamil.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4f73d65c-0a56-4738-a8d9-43bf3de4c4d7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '611223', '611223',
    'Hritam', NULL, 'Bhattacharyya', 'hrikbhattacharyya@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4dc35ab4-26de-4797-a6cc-ae55e9e6a62c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '260758', '260758',
    'Kuldeep', NULL, 'Debnath', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '414a768b-af59-47e0-a445-405c8bb9b804'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '773969', '773969',
    'Pranay', NULL, 'Singha', 'pranay.singha2011@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fc76c021-5647-41ec-a3d1-d81ce08f1f39'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '432043', '432043',
    'Dipak', NULL, 'Kumar', 'deepakk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd7b8ce8e-684b-4bcb-b966-2d725753d2a8'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '72f64f3f-6f1c-4efe-bb7c-da03f630e9b0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '425230', '425230',
    'Gaurav', 'Kumar', 'Tomar', 'gauravkumart.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd7b8ce8e-684b-4bcb-b966-2d725753d2a8'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '05da84ee-d64f-4c88-8481-936ecfdf7267'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '168844', '168844',
    'Rajeev', NULL, 'Ranjan', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd7b8ce8e-684b-4bcb-b966-2d725753d2a8'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '71f6a9f6-0d20-4280-a35f-363d7fb9fdb0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '322963', '322963',
    'Arindam', NULL, 'Chakraborty', 'carindam410@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8ed7be5d-7ab2-4ead-8c1a-346b05031893'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b5ead4ce-8af1-466d-b983-e36cd0907147'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '774775', '774775',
    'Ashish', NULL, 'Chakraborty', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f9e3cee5-5c22-40a6-87c2-c9b30ed3bdfc'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '538e9fb9-dbc1-4779-b4c0-05d5ea5b3b21'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '418960', '418960',
    'Ankita', NULL, 'Koiri', 'ankita.anp.au@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '20abceba-8372-40cd-8275-49ff4673b341'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7f02a530-175e-47ab-b3f0-0b210cd78925'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089422', '089422',
    'Gita', 'Rani Das', 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '041e4259-6efd-43db-9c02-82e8743efc20'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '776568', '776568',
    'Haradhan', NULL, 'Dey', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2531b241-b2de-40b7-b7d5-e435508fd959'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '595944', '595944',
    'Kshitish', 'Chandra', 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a0cf6675-a69d-40fe-8998-f45533d04cee'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '705463', '705463',
    'Nitai', 'Chandra', 'Saha', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8e5a9f2c-b034-458b-83c5-30ffdc285495'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '867836', '867836',
    'Rajani', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'dae42cd3-2020-4446-9889-de6f92b65eb8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '059931', '059931',
    'Rohit', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9e4c6c7d-ecaf-4eef-92bb-d9dae1d978c6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '537725', '537725',
    'Samir', NULL, 'Sutradhar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2f85aff6-0f66-4551-86c0-176504988c7a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '837817', '837817',
    'Sanjoy', 'Kumar', 'Deb', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7b459ea9-235c-48b3-906f-fd8577e81f7c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '660611', '660611',
    'Siman', NULL, 'Rakshit', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4ce8dc5e-fa61-48de-9d07-56fd47060a4d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '675239', '675239',
    'Sudhir', NULL, 'Uria', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e1d7c8c3-cdc8-4f09-93fd-351bb07f92db'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '977332', '977332',
    'Swadesh', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ec551b43-e1b4-4c95-97c9-6212eff853e9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '554361', '554361',
    'Bijoy', NULL, 'Shil', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4c66d4ae-b308-4497-a209-31c93fbf02f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '38473661-9c84-4844-a5f4-01e89021cc5a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '814841', '814841',
    'Chiranjit', NULL, 'Sutradhar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4c66d4ae-b308-4497-a209-31c93fbf02f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '37b664d6-39a3-4b49-b87e-e9b8520d845b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '119700', '119700',
    'Koushik', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4c66d4ae-b308-4497-a209-31c93fbf02f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '23c53931-336c-46ec-afcf-27725a05d502'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089261', '089261',
    'Manjushree', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4c66d4ae-b308-4497-a209-31c93fbf02f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6ed3d664-e5c2-4bc3-9304-db4881c8590d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991831', '991831',
    'Sagar', NULL, 'Majumder', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4c66d4ae-b308-4497-a209-31c93fbf02f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '32a41b7a-a1c7-478f-b9ea-4e1efe267c84'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '103575', '103575',
    'Sujal', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4c66d4ae-b308-4497-a209-31c93fbf02f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '58ed2191-0c91-437e-abd5-7e6f7b029162'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '692945', '692945',
    'Biswajit', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bfaadfe3-a7cb-4877-a446-b342e7baafdd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '221497', '221497',
    'Sudip', NULL, 'Biswas', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '429e9c15-3f40-4663-bd9d-68490f3e7fb1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '723614', '723614',
    'Asam', 'Ray', 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9f14e888-ede1-4c92-a18e-f2176070ec60'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '334054', '334054',
    'Babul', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b1c9753a-a483-4f94-a1fa-3ff0794e2905'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '069114', '069114',
    'Charan', 'Manik', 'Halam', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b59ca7c8-0971-4f40-b503-c6b5a8711b15'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '266707', '266707',
    'Rajesh', NULL, 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c80a10a1-c00b-47ef-93e6-f30870079741'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '496988', '496988',
    'Sabitri', 'Podder', 'Roy', 'sabitripodderr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'db2b9473-55d0-4ce6-a419-8ed2fcf5e7ec'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a70816b7-2c4b-4855-a09b-4232be56b076'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '829528', '829528',
    'Goutam', NULL, 'Roy', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b9d805d6-5554-4dad-a00c-a2f099aa09b1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '708f535e-1568-419e-a2d1-b6653e5bc434'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273300', '273300',
    'Arpan', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4c66d4ae-b308-4497-a209-31c93fbf02f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b73e87c8-3318-4861-9fad-554a2ecf3125'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '117874', '117874',
    'Jadab', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4c66d4ae-b308-4497-a209-31c93fbf02f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '534ff72f-ba0f-4a40-982c-17501bc5d646'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '989373', '989373',
    'Rajesh', NULL, 'Chakraborty', 'chakraj27@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c45df739-b03c-480d-b028-a9b2a6dbd0fb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ca69a413-e4f8-4365-b8dd-c805ef7fcccf'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '878245', '878245',
    'Diptanu', NULL, 'Deb', 'deb.diptanu09@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2b0ab5fe-f5c0-47c9-ae8a-9633c7491386'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f41f5576-efa8-4aa8-b91d-565a9bc5522d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '287245', '287245',
    'Jhuntu', NULL, 'Dasgupta', 'jhuntudd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b31e7b59-d4ee-4346-9c34-0b95b4aad3de'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ceeaede3-68f8-4c21-8e55-9f12b7ed13e7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '083321', '083321',
    'Nabajyoti', NULL, 'Debnath', 'nabajyotid.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '0736fdde-90b6-43ab-9776-9c1dfce75b1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f94a0956-654f-44d5-aca5-1064dfbfc683'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '508317', '508317',
    'Samar', 'Chandra', 'Deb', 'samarchandrad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '0736fdde-90b6-43ab-9776-9c1dfce75b1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c5645012-8589-4947-a19f-c6453e1c3b72'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '599624', '599624',
    'Santosh', NULL, 'Das', 'das71santosh@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '0736fdde-90b6-43ab-9776-9c1dfce75b1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '77b7b49c-494c-44d9-a957-b66e3f29f705'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '677853', '677853',
    'Soumen', NULL, 'Banik', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '0736fdde-90b6-43ab-9776-9c1dfce75b1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9554b399-0950-415e-808e-193b42047e14'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '404232', '404232',
    'Ajoy', NULL, 'Dutta', 'ajoyd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b31e7b59-d4ee-4346-9c34-0b95b4aad3de'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a46b34a9-c5d3-48e1-b32d-a9b74cd7dc0f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '567588', '567588',
    'Debabrato', NULL, 'Chowdhury', 'debabratoc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b31e7b59-d4ee-4346-9c34-0b95b4aad3de'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4f74b5d3-6f3b-4701-9af4-ec79d816e706'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '799528', '799528',
    'Subodh', NULL, 'Debbarma', 'subodhd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b31e7b59-d4ee-4346-9c34-0b95b4aad3de'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '11f0fcdb-8086-441e-97a4-e62bd46c3089'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '923432', '923432',
    'Uttam', NULL, 'Chakraborty', 'uttamc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b31e7b59-d4ee-4346-9c34-0b95b4aad3de'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1a229a33-ccca-449b-b956-353bc6134cf0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '919704', '919704',
    'Tanushree', NULL, 'Biswas', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '8cb043ce-54d1-4230-ac42-f8d4440a2a5f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e30e1412-ed5c-42ea-9748-963c9d3a9a88'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '326801', '326801',
    'Dipannita', NULL, 'Das', 'dipannitad.kol.pdac@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '3490705f-d370-4f17-9593-db86b017c0e3'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ba44ebe2-4f1f-43fd-9d6b-82a68e82c337'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510617', '510617',
    'Bishu', NULL, 'Nandi', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '0736fdde-90b6-43ab-9776-9c1dfce75b1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8d108879-bade-490b-acfd-c15c19365fc7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382713', '382713',
    'Subhrajit', NULL, 'Roy', 'subhrajitr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '0736fdde-90b6-43ab-9776-9c1dfce75b1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e6088b61-d626-4b12-a5a0-cd6fafb186ae'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '980071', '980071',
    'Subrata', 'Das', 'Choudhury', 'chowdhurysd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b31e7b59-d4ee-4346-9c34-0b95b4aad3de'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a1c87b8c-2fd0-4841-a235-db794b524f11'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '952380', '952380',
    'Rajashree', NULL, 'Chakraborty', 'rajashreec.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '0736fdde-90b6-43ab-9776-9c1dfce75b1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fad5ed2d-1aa7-4a6b-9625-11a22feb1462'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '109614', '109614',
    'Sanjay', 'Kumar', 'Yadav', 'sanjoykumary.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f72ffe7e-8b09-4df0-889f-6d99c992b458'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '52c98f69-9c8f-4178-a80a-3a3e52652c13'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '795304', '795304',
    'Arpan', NULL, 'Shil', 'arpanshil.agt@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'f6197663-454e-4d7e-a5e5-30297501da04'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd9036b02-5b87-436c-83c0-8c37dcbc2c17'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '042174', '042174',
    'Pradip', 'Kumar', 'Nandi', 'pradipkn.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7fe1595a-30a0-4237-96b2-a36a90acfdb4'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);

COMMIT;