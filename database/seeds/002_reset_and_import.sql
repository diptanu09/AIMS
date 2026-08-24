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
VALUES ('9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT', 'Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('b8aff575-2699-465f-a9bb-f4857f0dba3a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT_GENERAL_A_E', 'Accountant General (A&E)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('d39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASSISTANT_SUPERVISOR', 'Assistant Supervisor', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASST_ACCOUNTS_OFFICER', 'Asst. Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('5130e2e2-284b-4734-b3ae-f03ab429c98b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT', 'Canteen Attendant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('722b832c-d849-4feb-89f2-cb81123799f7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT_OUTSOURCED', 'Canteen Attendant (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('65c743d5-7753-4da8-8234-b3e00d653ab4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_CLERK', 'Canteen Clerk', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('50f8d28b-f6c6-4ea0-b2af-e343871e8b07'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CASUAL_WORKER_TRIPURA', 'Casual Worker Tripura', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('aa8c0392-25b1-4e2e-8247-90a7ce1ab86d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CLERK_TYPIST', 'Clerk Typist', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('91e17439-7382-4917-9968-f7fd136059a6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CONSULTANT_ACCOUNTANT', 'Consultant Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_OUTSOURC', 'Data Entry Operator (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('b73ec969-5c70-4ef6-9e72-e3700487724f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_A', 'Data Entry Operator Gr A', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('4e4861d1-89c5-4577-adc5-f2ffecbdaa1d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_B', 'Data Entry Operator Gr B', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('b61f093e-9d9d-4aa2-ba77-0285be2925c9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_HALWAI', 'Halwai', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('2ca2964b-d8ea-4330-99de-effe1676b4f8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_JUNIOR_TRANSLATOR', 'Junior Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASK_STAFF', 'Multi Task Staff', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('2dcc0fa5-6dd2-467f-ae00-cea9290b3791'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASKING_STAFF_OUTSOURC', 'Multi Tasking Staff (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('84d1d5dc-f0db-47be-9a38-f709b62c8d22'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_OUTSOURCED_CANTEEN_MANAGER', 'Outsourced Canteen Manager', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('0809b3e4-b19e-4479-9e6f-8984f53e5e81'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ROLL_OUT_SUPPORT_ENGINEER', 'Roll out Support Engineer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('ea9f26b2-0845-4801-8c22-5b4848da43ce'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTANT', 'Senior Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('41b069e3-f675-423c-a6e7-4421a5a43a2b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTS_OFFICER', 'Senior Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('b705160b-dae1-4c4e-be76-fea2d0e63f47'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_DEPUTY_ACCOUNTANT_GEN', 'Senior Deputy Accountant General', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('e123a08c-45f8-41fb-9005-3a7f1eac629b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_HINDI_TRANSLATOR', 'Senior Hindi Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('7343b953-9cb5-4d77-9b6a-bcbd7366c037'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER', 'Stenographer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('cb5b04a2-124d-474d-98bd-cecbacc3fa42'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER_OUTSOURCED', 'Stenographer (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('fa00304f-739d-4cdd-bb75-cb6a1d2518d2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SUPERVISOR', 'Supervisor', 1, TRUE);

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
    '0370ecdd-aa5b-47d7-b7f0-ee2f18d23c5a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '045677', '045677',
    'Amar', 'Chandra', 'De', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a82bba9a-8d2a-4400-a897-9af3e197d7ef'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '716775', '716775',
    'Lokesh', 'Singh', 'Manral', 'manral.lokesh@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f9b533ce-7779-4231-8e16-f7e2acf5db97'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258696', '258696',
    'Nipun', NULL, 'Jain', 'nipunj.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '92e91dc3-8da3-40ee-854f-90c504888555'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '419627', '419627',
    'Palash', NULL, 'Banerjee', 'banerjeepalas@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '21418aab-d114-44a4-92a9-1fafb6137e3a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '787234', '787234',
    'Piyush', NULL, 'Prabhakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '386e9a59-b733-41b8-bc74-a0e9bd0030db'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382834', '382834',
    'Priyadarshini', NULL, 'Singh', 'prdrshn91113@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '72ff1719-2f1f-4779-8f96-df78e3f9fe54'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991014', '991014',
    'Rahul', NULL, 'Kumar', 'rahulk.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0a4532e2-1322-4d2c-8c52-560ea46bc4ab'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '551720', '551720',
    'Rakesh', 'Chandra', 'Srivastav', 'rakeshcs.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3c554e64-9cc6-438b-9ce3-4a059e3bf4fe'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296861', '296861',
    'Rohit', NULL, 'Yadav', 'rohity.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8a058c57-4f75-4e31-a633-6af53d815298'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '457386', '457386',
    'Sourav', NULL, 'Maji', 'souravm.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0488a779-8e9c-4cbc-a53a-2383c5877bb8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '354091', '354091',
    'Suraj', NULL, 'Kishore', 'surajk.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7efc8366-8034-406d-89e2-48e0f619993e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '081342', '081342',
    'Vishal', NULL, 'Verma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '27e5d747-5298-44e9-992b-2cc124aa117f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '925906', '925906',
    'Ashish', NULL, 'Verma', 'ashishv.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bef8f67b-ee82-4c2c-812f-31ced7d94056'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '412074', '412074',
    'Bubai', NULL, 'Mondal', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ec78e75a-9b88-48a9-86eb-e679eaff655a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273329', '273329',
    'Dibakar', NULL, 'Das', 'dibakard.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bb1bf17c-1035-4670-bab6-0fd62d8d866d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '454543', '454543',
    'Dipa', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8ee0da2a-6481-4f9a-916d-3c57c4824fba'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '625079', '625079',
    'Gautam', NULL, 'Kumar', 'gautamk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9842b1de-2df8-47f9-850e-aac700559857'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970806', '970806',
    'Jayanti', NULL, 'Saha', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a23c1250-da9a-411e-9fca-9c8b4da672be'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '192266', '192266',
    'Jishan', NULL, 'Choudhuri', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '174bbed9-cbf6-43d1-87c1-1f3482400c1d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '570806', '570806',
    'Keya', NULL, 'Sarkar', 'keyas.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '221123bb-8d7b-4178-91a4-b592afd3584c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970592', '970592',
    'Kishlay', NULL, 'Raj', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '74f2727f-7b6a-49b8-b249-0e4cfd25822b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '222819', '222819',
    'Mohammad', 'Naqi', 'Ali', 'naqimadina12@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '966f0688-d0e1-4f91-8be0-0756d368af71'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '229834', '229834',
    'Paramita', NULL, 'Bhattacharjee', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e2cb2515-b3a2-40d2-9602-310ba1dc420b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '789991', '789991',
    'Partha', NULL, 'Debnath', 'parthad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'acf83b2a-216d-483f-8adc-b40c1c1f4490'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '008233', '008233',
    'Pilan', NULL, 'Ngullie', 'pilann.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bf8cfc82-01f9-45ba-894a-71aec0126ba0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '275804', '275804',
    'Pranav', NULL, 'Kumar', 'pranavk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '10df96da-bf0b-4cd7-8e52-e708cd6cded3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296851', '296851',
    'Rajeev', NULL, 'Kumar', 'rajeevkumarag1985@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1672b6dc-4c19-436f-bc09-6b9eb9789ce8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '405349', '405349',
    'Rajeev', NULL, 'Kumar', 'rajeevkr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '70504cd0-751e-49c3-8c32-3968c97d4ef6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786890', '786890',
    'Subham', NULL, 'Ghosh', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '005c15f7-aac6-49e8-9917-f88656c874b8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '642211', '642211',
    'Sudip', NULL, 'Barman', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '650556ec-deea-4d33-a8a7-dcb96a0da9d4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '482594', '482594',
    'Sunil', NULL, 'Kumar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd470f886-dbe8-4ecc-a6a3-3e8e45756128'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '515186', '515186',
    'Udiyan', NULL, 'Bose', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '9d279cb8-40cb-47dd-8328-a866f7d8a76f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '07f0b2d8-f986-44ce-af02-18d841e06a52'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '871058', '871058',
    'Ranendu', NULL, 'Sarkar', 'sarkarr@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b8aff575-2699-465f-a9bb-f4857f0dba3a'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ba968760-31b0-4845-a6aa-9fda714e43ec'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '202868', '202868',
    'Amit', NULL, 'Gaurav', 'amitgaurav.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01ab0a9e-4b81-495b-980b-4df6d227bc7b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '26b4c069-2788-4aa3-99eb-6e371697e4dd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '231116', '231116',
    'Anjana', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c2ab379d-67ef-4fac-9337-eed99f7c9f38'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '587084', '587084',
    'Ankur', NULL, 'Debbarma', 'ankurd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3b031dec-ed58-48c7-8907-410b39cee656'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '863010', '863010',
    'Babul', NULL, 'Bhowmik', 'babulb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2a6c812f-b15e-4028-ab2e-5ce01886e2f4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545651', '545651',
    'Banani', NULL, 'Das', 'babanib.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '451893f0-44c5-4a06-94de-30b6e6817bfb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '788426', '788426',
    'Biswajit', NULL, 'Datta', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '853e4d03-d0da-4209-a7c1-f79aa333d38e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '802702', '802702',
    'Biswanath', NULL, 'Chakraborty', 'biswanathc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '66f936ea-2e90-4e00-bbb9-656211131e5d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '604228', '604228',
    'Champakali', NULL, 'Debbarma', 'champa68@rediffmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'adc25d1f-311b-4996-be5c-b382fa1537bc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510884', '510884',
    'Chandan', NULL, 'Debnath', 'chandand.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '78250558-e849-4f10-91d0-b7801568b29b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '310789', '310789',
    'Chhanda', 'Banik', 'Bhaumik', 'chhandab.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8f47e9ab-b331-4a1a-8420-0a0ba2f590ca'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545958', '545958',
    'Debabrata', NULL, 'Bhattacharjee', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fd15fb15-155a-4bfe-9a2a-db0bd9adf484'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '452643', '452643',
    'Debasis', NULL, 'Biswas', 'debasisb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0133e342-c915-4c20-a88d-5c1aa82ee2ac'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '177893', '177893',
    'Malabika', NULL, 'Rakshit', 'mablabikar.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8aee632f-f35e-4910-ba4e-5e32f2790d55'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '300159', '300159',
    'Mrityunjoy', NULL, 'Bhowmik', 'mrityunjoyb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '59100e93-e170-4dfe-89db-b65c6025fd60'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '280235', '280235',
    'Pradip', NULL, 'Karmakar', 'pradipk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6c73ce55-1699-4b0d-b8ae-45f25eed8eba'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '483866', '483866',
    'Prasenjit', NULL, 'Pal', 'prasenjitp.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1885e891-a3f8-4d85-9aa8-a4b8a3e45e05'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '558271', '558271',
    'Raj', 'Kumar', 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3a4ce449-4c30-4f25-a0a0-7b6b899e807b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '605543', '605543',
    'Rama', NULL, 'Bhattacharya', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '60a75c5c-7cfb-49e1-ab15-03ac76e808f7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '265793', '265793',
    'Sanjoy', 'Krishna', 'Debbarma', 'sanjoykd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a6cfe225-295f-4be4-8570-4b2260fe3480'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '738761', '738761',
    'Satish', NULL, 'Debbarma', 'satish71debbarma@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6f46e42e-4be0-47f5-916c-db6c27968eee'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '318974', '318974',
    'Srilekha', NULL, 'Dey', 'srilekhad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4b4e5fc9-a598-41f9-9325-2fb140e98b9f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '502040', '502040',
    'Subh', 'Karan', 'Chauhan', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9379645c-d9fd-409c-a857-3e627df9a640'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '603680', '603680',
    'Suchana', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '66c016fb-6eee-43f2-8859-93810e38eed1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '137660', '137660',
    'Sudha', 'Ranjan', 'Debbarma', 'sudharanjand.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '92686911-7719-4661-8ebb-c9e66d0d3acc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '423533', '423533',
    'Sukhendu', NULL, 'Bhaumik', 'sukhendub.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '72947843-cd05-4a65-96d2-e81c517d6455'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '090908', '090908',
    'Tapan', 'Kumar', 'Sarkar', 'tapankumars.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'd39a15ad-ced9-4757-8890-f7d9285709a1'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '86fa592c-e7ee-4bb9-ac50-5fd45083453e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '149565', '149565',
    'Chandan', 'Kumar', 'Das', 'Chandankd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '5130e2e2-284b-4734-b3ae-f03ab429c98b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '01534c33-6437-4830-a198-d6a751d92d67'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '037947', '037947',
    'Ratan', NULL, 'Ghosh', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '5130e2e2-284b-4734-b3ae-f03ab429c98b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '291a1762-cec9-4c77-93d0-40f0b821f0d7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '711741', '711741',
    'Nayan', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '722b832c-d849-4feb-89f2-cb81123799f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4d4c7b7b-326d-41f5-92ec-84dfe69f81ba'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '060574', '060574',
    'Shahil', NULL, 'Singha', 'shahilsingha321@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '722b832c-d849-4feb-89f2-cb81123799f7'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '55d433ed-998e-4fc6-be07-b60aa4d7ba07'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '998024', '998024',
    'Swapan', NULL, 'Bhowmik', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '65c743d5-7753-4da8-8234-b3e00d653ab4'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2abd8f9e-b964-45cc-8e20-c49473fead48'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '586589', '586589',
    'Bimal', NULL, 'Sarkar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '50f8d28b-f6c6-4ea0-b2af-e343871e8b07'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9408e0d5-0e08-4e3f-9236-8042708bd0cf'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '969535', '969535',
    'Gopal', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '50f8d28b-f6c6-4ea0-b2af-e343871e8b07'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b7fba5f6-b71a-4a2b-820a-29cc278c7214'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '942482', '942482',
    'Raja', NULL, 'Biswas', 'rajabiswas16696@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '50f8d28b-f6c6-4ea0-b2af-e343871e8b07'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8f2b717c-5a2e-4c32-9a87-3ddf0ced2b3c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '756473', '756473',
    'Shibu', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '50f8d28b-f6c6-4ea0-b2af-e343871e8b07'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '71012139-a6ed-4103-a933-cc94ad9852e0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '859252', '859252',
    'Sumit', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '50f8d28b-f6c6-4ea0-b2af-e343871e8b07'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7928c03d-833f-4837-833b-f914fb87f326'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258186', '258186',
    'Sumita', 'Bose', 'Dey', 'sumitab.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'aa8c0392-25b1-4e2e-8247-90a7ce1ab86d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd694b3c3-cbfa-4798-ad6e-c532987b1beb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '792890', '792890',
    'Saurabh', NULL, 'Das', 'saurabhd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'aa8c0392-25b1-4e2e-8247-90a7ce1ab86d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '584897da-d533-4162-8dc3-7454b58c0193'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '992660', '992660',
    'Pankaj', 'Kumar', 'Sarkar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '91e17439-7382-4917-9968-f7fd136059a6'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f2835931-b5ae-4fe7-8b33-66a5430dcb48'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '126173', '126173',
    'Dipankar', NULL, 'Debnath', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '91e17439-7382-4917-9968-f7fd136059a6'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd0f1b5b6-76ca-4369-b23d-bd8f25c0a1b8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '223506', '223506',
    'Thaingla', NULL, 'Mog', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a406b3ca-cdb6-4090-98f8-7bd5fd77acb3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '541791', '541791',
    'Subhranil', NULL, 'Debroy', 'subhranil191@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '57b6d6b9-50bb-44a5-a0de-cee6f761b78b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786106', '786106',
    'Diptanu', NULL, 'Roy', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0f14d20d-e5b4-4815-a3c4-883806295d9b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '351307', '351307',
    'Gobinda', NULL, 'Bhowmik', 'bhowmikgobinda19@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '055dda91-c65a-4631-82f6-d8336caa1451'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '073976', '073976',
    'Himanshu', NULL, 'Khokhar', 'himnshuk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4e4861d1-89c5-4577-adc5-f2ffecbdaa1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '25e8d651-40cd-4bba-9d79-f92458b25598'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '944337', '944337',
    'Sayani', NULL, 'Nandy', 'sayanin.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b73ec969-5c70-4ef6-9e72-e3700487724f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8e58f6db-1ad9-48d4-906e-bb841ef84838'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '358367', '358367',
    'Pramod', NULL, 'Kumar', 'pramodp.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4e4861d1-89c5-4577-adc5-f2ffecbdaa1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a4d7ff78-55c4-4f40-b188-1434335b3c7b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '464696', '464696',
    'Ankan', NULL, 'Paul', 'paulankan16@gamil.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '595dfcf7-f776-474c-af07-914558eef11b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '611223', '611223',
    'Hritam', NULL, 'Bhattacharyya', 'hrikbhattacharyya@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6ebe35d9-2335-45b8-b0ac-a626ff9e8ee2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '260758', '260758',
    'Kuldeep', NULL, 'Debnath', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3a07b74c-4351-4a47-bf59-5d57346876f3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '773969', '773969',
    'Pranay', NULL, 'Singha', 'pranay.singha2011@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c7e7e297-4b87-4477-b352-ddb547942aeb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '432043', '432043',
    'Dipak', NULL, 'Kumar', 'deepakk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4e4861d1-89c5-4577-adc5-f2ffecbdaa1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '10786b06-8486-475c-a7d7-815bf3f8a50b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '425230', '425230',
    'Gaurav', 'Kumar', 'Tomar', 'gauravkumart.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4e4861d1-89c5-4577-adc5-f2ffecbdaa1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fc0cf294-47ad-44a0-a088-505ffa15d2be'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '168844', '168844',
    'Rajeev', NULL, 'Ranjan', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '4e4861d1-89c5-4577-adc5-f2ffecbdaa1d'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2bf20e89-ef92-4631-b40f-8cf06bc5b0ef'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '322963', '322963',
    'Arindam', NULL, 'Chakraborty', 'carindam410@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'c9ff8064-e9d7-4dfd-913a-4c4036298697'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bfd305f7-3a7c-4f6b-ab28-4c94ade26265'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '774775', '774775',
    'Ashish', NULL, 'Chakraborty', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b61f093e-9d9d-4aa2-ba77-0285be2925c9'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a3a74c81-a78e-4af6-bd3a-af85a37b5dd4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '418960', '418960',
    'Ankita', NULL, 'Koiri', 'ankita.anp.au@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2ca2964b-d8ea-4330-99de-effe1676b4f8'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd2487f59-43eb-4907-ae3b-c26ae6920195'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089422', '089422',
    'Gita', 'Rani Das', 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1c216df9-1594-4ee1-9446-cd2f207f31fa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '776568', '776568',
    'Haradhan', NULL, 'Dey', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '720a40de-9123-40a9-af16-dac6fea7cd49'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '595944', '595944',
    'Kshitish', 'Chandra', 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1428a62f-e27e-489d-954a-53be55cec2f9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '705463', '705463',
    'Nitai', 'Chandra', 'Saha', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fece2d04-3271-40e9-bc89-0ae848e23253'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '867836', '867836',
    'Rajani', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5302510c-4d31-4cfe-a46b-baf180d62693'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '059931', '059931',
    'Rohit', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e1ec55fe-c6b7-4c52-afe5-b5ca97296267'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '537725', '537725',
    'Samir', NULL, 'Sutradhar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '00938647-8f68-46f6-8c60-706b86406069'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '837817', '837817',
    'Sanjoy', 'Kumar', 'Deb', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2a3335b3-6019-43f7-ac4e-6a86ba05a535'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '660611', '660611',
    'Siman', NULL, 'Rakshit', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2c0d2bf3-18c7-4a7f-b7f4-c41c16cc1f17'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '675239', '675239',
    'Sudhir', NULL, 'Uria', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '09a0d9c9-efee-483e-9d9d-24e870bb99e6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '977332', '977332',
    'Swadesh', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3b98d95f-b933-4f28-a647-dbb49b5ac6b6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '554361', '554361',
    'Bijoy', NULL, 'Shil', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2dcc0fa5-6dd2-467f-ae00-cea9290b3791'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '936816fd-1169-4fee-8d11-ccd188409806'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '814841', '814841',
    'Chiranjit', NULL, 'Sutradhar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2dcc0fa5-6dd2-467f-ae00-cea9290b3791'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3f0838a2-d3ab-46e8-b4c8-abddcd7419af'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '119700', '119700',
    'Koushik', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2dcc0fa5-6dd2-467f-ae00-cea9290b3791'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '13520517-13ed-4a62-a472-47606ee17a8f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089261', '089261',
    'Manjushree', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2dcc0fa5-6dd2-467f-ae00-cea9290b3791'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e9a85124-1ffe-4f44-9830-8c4447a648d8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991831', '991831',
    'Sagar', NULL, 'Majumder', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2dcc0fa5-6dd2-467f-ae00-cea9290b3791'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e9dbe841-5c39-44c7-81d3-d6d6ed5c9451'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '103575', '103575',
    'Sujal', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2dcc0fa5-6dd2-467f-ae00-cea9290b3791'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9bef4677-f8ca-4a67-b802-770efdde5cac'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '692945', '692945',
    'Biswajit', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '13e51edc-abe4-4b60-939e-43a7096b334f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '221497', '221497',
    'Sudip', NULL, 'Biswas', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '40f3fec1-19b3-4d66-b85d-3791add23509'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '723614', '723614',
    'Asam', 'Ray', 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ab1adecb-f0b2-4544-b6c4-ad969d72bb2d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '334054', '334054',
    'Babul', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'cc79acba-e79d-480e-8c6c-8618818f5162'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '069114', '069114',
    'Charan', 'Manik', 'Halam', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '224b52e2-c46b-4355-9cfd-a0f8c49ac247'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '266707', '266707',
    'Rajesh', NULL, 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b1175426-2af4-4847-89c3-6795cf77a46c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '496988', '496988',
    'Sabitri', 'Podder', 'Roy', 'sabitripodderr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'df529faa-8780-4d26-81cd-9903ac642750'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fcf489ca-739e-4b38-a97e-b24a6580f565'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '829528', '829528',
    'Goutam', NULL, 'Roy', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '50f8d28b-f6c6-4ea0-b2af-e343871e8b07'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bd3e0484-22a1-4b11-9668-8df6f21902e5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273300', '273300',
    'Arpan', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2dcc0fa5-6dd2-467f-ae00-cea9290b3791'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ac62b66b-00bb-4790-89cb-992339e5fe08'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '117874', '117874',
    'Jadab', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '2dcc0fa5-6dd2-467f-ae00-cea9290b3791'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '939f27a6-375a-4f0b-a62c-0d6d0d9d2071'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '989373', '989373',
    'Rajesh', NULL, 'Chakraborty', 'chakraj27@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '84d1d5dc-f0db-47be-9a38-f709b62c8d22'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1eb061b4-8c8e-49dd-bd8b-adc4c9ec0fde'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '878245', '878245',
    'Diptanu', NULL, 'Deb', 'deb.diptanu09@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '0809b3e4-b19e-4479-9e6f-8984f53e5e81'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f5a5339c-8795-445a-bee1-0223bb020ba1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '287245', '287245',
    'Jhuntu', NULL, 'Dasgupta', 'jhuntudd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '41b069e3-f675-423c-a6e7-4421a5a43a2b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2e0c758c-d3ee-45a8-b69a-9c8cb6b476a5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '083321', '083321',
    'Nabajyoti', NULL, 'Debnath', 'nabajyotid.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ea9f26b2-0845-4801-8c22-5b4848da43ce'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a87e9a5f-0203-4e9f-829e-a64fe70cad30'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '508317', '508317',
    'Samar', 'Chandra', 'Deb', 'samarchandrad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ea9f26b2-0845-4801-8c22-5b4848da43ce'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1ad9561f-488d-44b2-8762-fb1fe7db7e8d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '599624', '599624',
    'Santosh', NULL, 'Das', 'das71santosh@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ea9f26b2-0845-4801-8c22-5b4848da43ce'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5f4158bd-a867-410b-9783-4222ba9754e8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '677853', '677853',
    'Soumen', NULL, 'Banik', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ea9f26b2-0845-4801-8c22-5b4848da43ce'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5c2597a5-e7aa-4f47-bd87-cf65357906cb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '404232', '404232',
    'Ajoy', NULL, 'Dutta', 'ajoyd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '41b069e3-f675-423c-a6e7-4421a5a43a2b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3e15052a-e647-432a-acd5-17358a0e6454'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '567588', '567588',
    'Debabrato', NULL, 'Chowdhury', 'debabratoc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '41b069e3-f675-423c-a6e7-4421a5a43a2b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '144caa5c-cd2a-44a5-82a8-d8c448c88c0d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '799528', '799528',
    'Subodh', NULL, 'Debbarma', 'subodhd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '41b069e3-f675-423c-a6e7-4421a5a43a2b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '79a7c61a-a851-4c8f-b261-71912a58f457'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '923432', '923432',
    'Uttam', NULL, 'Chakraborty', 'uttamc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '41b069e3-f675-423c-a6e7-4421a5a43a2b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4dbe8583-cc9c-4c25-a475-97fc246f4f3d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '919704', '919704',
    'Tanushree', NULL, 'Biswas', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'b705160b-dae1-4c4e-be76-fea2d0e63f47'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'aaac98d2-6b96-4f8d-bae2-390ad2064862'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '326801', '326801',
    'Dipannita', NULL, 'Das', 'dipannitad.kol.pdac@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'e123a08c-45f8-41fb-9005-3a7f1eac629b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6ef8a785-293b-400c-9561-e42e905c2f90'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510617', '510617',
    'Bishu', NULL, 'Nandi', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ea9f26b2-0845-4801-8c22-5b4848da43ce'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd72be525-fe94-44bb-a444-06dc6e2bf5cd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382713', '382713',
    'Subhrajit', NULL, 'Roy', 'subhrajitr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ea9f26b2-0845-4801-8c22-5b4848da43ce'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9c39b0ad-ee9f-4189-b66c-166a470ccc38'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '980071', '980071',
    'Subrata', 'Das', 'Choudhury', 'chowdhurysd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '41b069e3-f675-423c-a6e7-4421a5a43a2b'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '246aaeac-6d42-480e-bf06-8aff7d3389a4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '952380', '952380',
    'Rajashree', NULL, 'Chakraborty', 'rajashreec.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'ea9f26b2-0845-4801-8c22-5b4848da43ce'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ad461957-9069-42e4-9569-d45419001860'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '109614', '109614',
    'Sanjay', 'Kumar', 'Yadav', 'sanjoykumary.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7343b953-9cb5-4d77-9b6a-bcbd7366c037'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a7813b3a-aa9d-41dc-8266-fb689aee6f2a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '795304', '795304',
    'Arpan', NULL, 'Shil', 'arpanshil.agt@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'cb5b04a2-124d-474d-98bd-cecbacc3fa42'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '74ba3c2c-9468-4bb2-b920-7e482d2a2711'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '042174', '042174',
    'Pradip', 'Kumar', 'Nandi', 'pradipkn.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, 'fa00304f-739d-4cdd-bb75-cb6a1d2518d2'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);

COMMIT;