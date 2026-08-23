-- 002_reset_and_import.sql
-- Complete reset of operational/employee/report data and fresh master import.
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
    designations
RESTART IDENTITY CASCADE;

ALTER TABLE IF EXISTS attendance_raw_events ENABLE TRIGGER trg_protect_raw_attendance;


DO $$
DECLARE
    seq RECORD;
BEGIN
    FOR seq IN 
        SELECT sequence_name 
        FROM information_schema.sequences 
        WHERE sequence_schema = 'public'
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
VALUES ('1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT', 'Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('e69f17f4-bbbb-493d-aff1-e693728a761f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT_GENERAL_A_E', 'Accountant General (A&E)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASSISTANT_SUPERVISOR', 'Assistant Supervisor', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASST_ACCOUNTS_OFFICER', 'Asst. Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('125c3208-d465-479b-ac53-3ac795bdb266'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT', 'Canteen Attendant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('ace6cdbd-a45e-4d2d-80c0-366ddc72222f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT_OUTSOURCED', 'Canteen Attendant (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('34794043-14cf-47df-aedc-bb78f6c683d5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_CLERK', 'Canteen Clerk', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('6241cdd0-1eb0-418c-9baa-49e410ff23c4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CASUAL_WORKER_TRIPURA', 'Casual Worker Tripura', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('8a5af85a-c0e4-41a5-84fb-d9169793ddeb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CLERK_TYPIST', 'Clerk Typist', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('06c61f6e-4f46-4a8c-8af2-595d41879198'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CONSULTANT_ACCOUNTANT', 'Consultant Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_OUTSOURC', 'Data Entry Operator (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('9eb756d3-8c28-45cb-ac98-ad48ff522df8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_A', 'Data Entry Operator Gr A', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('0964e17c-ce7e-4ae3-95d0-f7444834118e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_B', 'Data Entry Operator Gr B', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('6f1a3140-7a74-4033-9fc9-519b8d3fac4f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_HALWAI', 'Halwai', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('74b9b895-87db-4178-ad29-b6d5356f8804'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_JUNIOR_TRANSLATOR', 'Junior Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASK_STAFF', 'Multi Task Staff', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('ed3defad-2db3-486c-a004-0c73d202e6ba'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASKING_STAFF_OUTSOURC', 'Multi Tasking Staff (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('8205a0b9-0b92-4216-810e-e072b0a880ee'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_OUTSOURCED_CANTEEN_MANAGER', 'Outsourced Canteen Manager', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('5e6a32de-3390-4ad4-b1b5-7567c38e86a8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ROLL_OUT_SUPPORT_ENGINEER', 'Roll out Support Engineer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('92146bf2-b182-40f0-af33-7a318ddcaf73'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTANT', 'Senior Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('11d69b61-7d57-4c3f-937e-ea41717d8238'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTS_OFFICER', 'Senior Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('1a8fa17d-68fd-485e-8db2-d5a267133138'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_DEPUTY_ACCOUNTANT_GEN', 'Senior Deputy Accountant General', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('99286827-d833-4add-afd0-b60a9ca5966f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_HINDI_TRANSLATOR', 'Senior Hindi Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('783ec91a-36c5-4f1f-8d6e-845d1320a6ee'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER', 'Stenographer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('9ed0bbe1-d113-4a44-9ef4-434b949d8c61'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER_OUTSOURCED', 'Stenographer (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('00a24bef-f62e-4642-a188-5e1402724fa3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SUPERVISOR', 'Supervisor', 1, TRUE);

-- Master Sections
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_UNASSIGNED', 'Unassigned / General Pool', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('aab7dba6-faf8-4490-b09d-42c4f42b3e0f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_SR_AO', 'Sr. AO Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('5d1b1c51-3558-4e0f-b72b-82e54bfeec19'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_AAO', 'AAO Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('b909ee29-6c2b-4b6e-9c1c-3e767be25c70'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_ADMIN', 'Admin Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('1bdd2d0f-89cf-42e1-a9eb-4db08458c065'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_ACCOUNTS', 'Accounts Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('3e4c1385-4c4e-47b1-9465-3cd50fc8b705'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_AUDIT', 'Audit Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('38ce8292-d920-439d-b372-85222b55cf5b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_ESTT', 'Establishment Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('d70565f7-5321-4f6b-b6c8-5654808d2bfd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_PENSION', 'Pension Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('f76157b9-2903-4040-a78e-c8122ad76eb5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_FUND', 'GPF / Fund Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('46f1b225-0e7d-48e5-a0e0-1d3d4f2115a9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_EDP', 'EDP Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('bc7b0e06-42e7-4d07-8098-cff286fccf9b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_CANTEEN', 'Departmental Canteen Section', TRUE);

-- Master Employees
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'af51181d-24f1-4403-bae9-92f6be1dd5f5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '045677', '045677',
    'Amar', 'Chandra', 'De', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3770836e-d59b-4294-ae77-a65e35db8b2f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '716775', '716775',
    'Lokesh', 'Singh', 'Manral', 'manral.lokesh@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3f03f149-6b1f-4fc9-85d1-4e37006a7a83'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258696', '258696',
    'Nipun', NULL, 'Jain', 'nipunj.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4b971704-e070-4c34-8b00-988203b137b6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '419627', '419627',
    'Palash', NULL, 'Banerjee', 'banerjeepalas@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9e77bd64-5590-4700-8ae3-7747e6f458dc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '787234', '787234',
    'Piyush', NULL, 'Prabhakar', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '374ed599-340e-4e57-bf89-4dfb0a52fa20'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382834', '382834',
    'Priyadarshini', NULL, 'Singh', 'prdrshn91113@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b04b6cc5-58e1-4bb0-a2fa-2932efd3df5d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991014', '991014',
    'Rahul', NULL, 'Kumar', 'rahulk.wbl.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '27c79747-bada-45ec-8184-da31895b66fa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '551720', '551720',
    'Rakesh', 'Chandra', 'Srivastav', 'rakeshcs.wbl.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2e283cbb-8735-4d8e-b218-bce75b2d3e37'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296861', '296861',
    'Rohit', NULL, 'Yadav', 'rohity.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '774d55b6-0919-410b-a323-635d07d4962e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '457386', '457386',
    'Sourav', NULL, 'Maji', 'souravm.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6996149f-29f4-4bab-a3ca-8a9914fafdb1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '354091', '354091',
    'Suraj', NULL, 'Kishore', 'surajk.wbl.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '94adf254-ada0-453d-ae12-c7b83b85c145'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '081342', '081342',
    'Vishal', NULL, 'Verma', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a77fea5a-5e9b-4e80-bd94-278684c23cb1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '925906', '925906',
    'Ashish', NULL, 'Verma', 'ashishv.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'faf95662-5270-48d4-b8b4-995d97fe34fb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '412074', '412074',
    'Bubai', NULL, 'Mondal', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'edc99cfc-9c78-47f7-bedf-ccce811d5f01'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273329', '273329',
    'Dibakar', NULL, 'Das', 'dibakard.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5c5c3d98-7dce-4077-8296-05e219f0df9b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '454543', '454543',
    'Dipa', NULL, 'Karmakar', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'cd80c529-baf0-449f-8802-7a808e598138'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '625079', '625079',
    'Gautam', NULL, 'Kumar', 'gautamk.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7d7bc883-ff5a-4828-bb8c-32d76836171f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970806', '970806',
    'Jayanti', NULL, 'Saha', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '48904b61-7a38-4816-b38c-16f8183fecb3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '192266', '192266',
    'Jishan', NULL, 'Choudhuri', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bfac1906-306a-4ad1-a48b-8cee86c75888'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '570806', '570806',
    'Keya', NULL, 'Sarkar', 'keyas.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '208a7517-2090-449a-b1fe-ec9e0d618224'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970592', '970592',
    'Kishlay', NULL, 'Raj', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '434b93d6-02ea-4985-979f-31dcf983e9b9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '222819', '222819',
    'Mohammad', 'Naqi', 'Ali', 'naqimadina12@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '81de62a5-1ab6-48ac-96e6-800e2a13866a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '229834', '229834',
    'Paramita', NULL, 'Bhattacharjee', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd3748767-6473-48b7-bc82-407c8d6c8213'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '789991', '789991',
    'Partha', NULL, 'Debnath', 'parthad.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '483d170b-2ccc-4f83-a9f3-c78702008b54'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '008233', '008233',
    'Pilan', NULL, 'Ngullie', 'pilann.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9b85a884-bf83-45b4-8f77-7b75d5486e4c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '275804', '275804',
    'Pranav', NULL, 'Kumar', 'pranavk.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e6dda436-7b9f-45e5-9566-5b756110f631'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296851', '296851',
    'Rajeev', NULL, 'Kumar', 'rajeevkumarag1985@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '136ac730-7636-440a-a215-1bde7cd9477b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '405349', '405349',
    'Rajeev', NULL, 'Kumar', 'rajeevkr.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f1b7adb2-4800-4e29-96b1-ed75a862931b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786890', '786890',
    'Subham', NULL, 'Ghosh', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5ba7b090-7626-482d-a763-faf06cc5270b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '642211', '642211',
    'Sudip', NULL, 'Barman', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c526c5ce-438e-42ec-ae82-555c7fddac9f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '482594', '482594',
    'Sunil', NULL, 'Kumar', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6d6b8e9b-a7ab-4c71-9335-ce2e072685de'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '515186', '515186',
    'Udiyan', NULL, 'Bose', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1015ff15-da63-4e56-80b4-b2ed67f32a71'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '31e95d9d-8941-4554-8b7b-592f8b2d2415'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '871058', '871058',
    'Ranendu', NULL, 'Sarkar', 'sarkarr@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'e69f17f4-bbbb-493d-aff1-e693728a761f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '81507fcf-21fe-4671-a863-708df919997e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '202868', '202868',
    'Amit', NULL, 'Gaurav', 'amitgaurav.wbl.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '4d1a73cd-65e3-4a63-b978-eff34401e672'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd2a9076b-0f8b-4c3a-b012-c0d58c59c55d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '231116', '231116',
    'Anjana', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5d55b454-9b1b-4407-8e62-e7565ed375dc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '587084', '587084',
    'Ankur', NULL, 'Debbarma', 'ankurd.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '79cb5023-8634-4c59-86c3-92dfd40669bf'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '863010', '863010',
    'Babul', NULL, 'Bhowmik', 'babulb.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ec05cbfd-e80a-4601-9198-a7649e55e0a5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545651', '545651',
    'Banani', NULL, 'Das', 'babanib.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c20e7d61-10f2-485a-bd79-4e520a964398'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '788426', '788426',
    'Biswajit', NULL, 'Datta', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a390493e-1191-466a-b67a-0f8d9da1b4fa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '802702', '802702',
    'Biswanath', NULL, 'Chakraborty', 'biswanathc.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd8a428c6-65b6-4b9f-9399-959dc001ce2b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '604228', '604228',
    'Champakali', NULL, 'Debbarma', 'champa68@rediffmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f4c64895-4b20-43e7-bddb-818c00d2c70d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510884', '510884',
    'Chandan', NULL, 'Debnath', 'chandand.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1200de68-2bdd-4001-8860-9edf7cf46450'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '310789', '310789',
    'Chhanda', 'Banik', 'Bhaumik', 'chhandab.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '19fe38db-6aae-43d5-9495-7fb42c82a221'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545958', '545958',
    'Debabrata', NULL, 'Bhattacharjee', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '93e4ece0-35a9-467f-9333-6719eb6dc9e0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '452643', '452643',
    'Debasis', NULL, 'Biswas', 'debasisb.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '03758a6e-4ea5-4460-b152-b9b243f116f6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '177893', '177893',
    'Malabika', NULL, 'Rakshit', 'mablabikar.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5d84f2e2-34a2-4847-9e9c-3052251e11c1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '300159', '300159',
    'Mrityunjoy', NULL, 'Bhowmik', 'mrityunjoyb.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '13da348f-bc15-4a52-bde1-c0833582b334'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '280235', '280235',
    'Pradip', NULL, 'Karmakar', 'pradipk.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fb3a6feb-eb77-414b-af55-1c7a9eb2881a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '483866', '483866',
    'Prasenjit', NULL, 'Pal', 'prasenjitp.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '01ba797b-6ff8-4c1b-a202-68dde0b72c87'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '558271', '558271',
    'Raj', 'Kumar', 'Debbarma', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '78bff5a1-5e92-45f8-9a8a-83c1fdd7f39a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '605543', '605543',
    'Rama', NULL, 'Bhattacharya', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ca8ea4c2-9d66-4203-8d53-676541500653'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '265793', '265793',
    'Sanjoy', 'Krishna', 'Debbarma', 'sanjoykd.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2db7ede7-f51b-4e49-8ed9-34166f8007a0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '738761', '738761',
    'Satish', NULL, 'Debbarma', 'satish71debbarma@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e4ce0e7c-7743-4811-89bc-1e94978c8760'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '318974', '318974',
    'Srilekha', NULL, 'Dey', 'srilekhad.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9aa4b188-086a-43a4-a532-1c0678d6869d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '502040', '502040',
    'Subh', 'Karan', 'Chauhan', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '18c61096-040b-49f8-99f4-2dd2d20f45a0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '603680', '603680',
    'Suchana', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ebb305b6-9693-4ec9-b10f-af8c6e888d4b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '137660', '137660',
    'Sudha', 'Ranjan', 'Debbarma', 'sudharanjand.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4715191f-c6ac-44f9-bdc1-029dd620f128'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '423533', '423533',
    'Sukhendu', NULL, 'Bhaumik', 'sukhendub.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c7e086c3-99ab-4468-9f36-613f040ed7fc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '090908', '090908',
    'Tapan', 'Kumar', 'Sarkar', 'tapankumars.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6a3b81dc-cf3b-4568-83a8-f8d221acd294'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6425592a-4700-4ebe-954b-49e55357ad4d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '149565', '149565',
    'Chandan', 'Kumar', 'Das', 'Chandankd.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '125c3208-d465-479b-ac53-3ac795bdb266'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '802e522c-b2b8-4655-b4ba-9eec6840569e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '037947', '037947',
    'Ratan', NULL, 'Ghosh', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '125c3208-d465-479b-ac53-3ac795bdb266'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b31dca29-3e3a-4226-8e0e-8940f720ee81'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '711741', '711741',
    'Nayan', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ace6cdbd-a45e-4d2d-80c0-366ddc72222f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2ea32d08-134b-4955-85cc-8d106d2f0ffe'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '060574', '060574',
    'Shahil', NULL, 'Singha', 'shahilsingha321@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ace6cdbd-a45e-4d2d-80c0-366ddc72222f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '264dcaa6-d6eb-4e57-a082-66a8c9bab0cb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '998024', '998024',
    'Swapan', NULL, 'Bhowmik', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '34794043-14cf-47df-aedc-bb78f6c683d5'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a7286b30-d993-47e9-a1b1-d76fbc88547f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '586589', '586589',
    'Bimal', NULL, 'Sarkar', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6241cdd0-1eb0-418c-9baa-49e410ff23c4'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c0bc830a-09af-4267-9cc3-0050706586a3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '969535', '969535',
    'Gopal', NULL, 'Karmakar', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6241cdd0-1eb0-418c-9baa-49e410ff23c4'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '801f853b-3534-419c-9889-da00cddaa39a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '942482', '942482',
    'Raja', NULL, 'Biswas', 'rajabiswas16696@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6241cdd0-1eb0-418c-9baa-49e410ff23c4'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a5d8436c-1993-40bc-b506-61b5355f546f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '756473', '756473',
    'Shibu', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6241cdd0-1eb0-418c-9baa-49e410ff23c4'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ba1673f4-7234-4e8a-bf5a-96f74e8eae6a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '859252', '859252',
    'Sumit', NULL, 'Dhanuk', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6241cdd0-1eb0-418c-9baa-49e410ff23c4'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3e13be05-237f-4da6-a2db-240366a44972'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258186', '258186',
    'Sumita', 'Bose', 'Dey', 'sumitab.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '8a5af85a-c0e4-41a5-84fb-d9169793ddeb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fe40d009-5910-499a-9aa6-28e767939a6e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '792890', '792890',
    'Saurabh', NULL, 'Das', 'saurabhd.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '8a5af85a-c0e4-41a5-84fb-d9169793ddeb'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '59e70871-ebfd-4378-9bfd-c846f5286e8d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '992660', '992660',
    'Pankaj', 'Kumar', 'Sarkar', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '06c61f6e-4f46-4a8c-8af2-595d41879198'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e55719c4-18e8-4be4-8583-478b837945c3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '126173', '126173',
    'Dipankar', NULL, 'Debnath', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '06c61f6e-4f46-4a8c-8af2-595d41879198'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8b1dfb04-285b-442e-a249-ede58874e9e8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '223506', '223506',
    'Thaingla', NULL, 'Mog', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ad986edc-ef40-48de-b9f6-68c7b3edef0c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '541791', '541791',
    'Subhranil', NULL, 'Debroy', 'subhranil191@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '022e0c96-49c8-4900-b58d-ca3badc1e73a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786106', '786106',
    'Diptanu', NULL, 'Roy', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a33ce8c5-e52b-4669-a9af-1be74659fede'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '351307', '351307',
    'Gobinda', NULL, 'Bhowmik', 'bhowmikgobinda19@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e7d92e7f-5ddf-4b3f-b580-189cd46b6b33'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '073976', '073976',
    'Himanshu', NULL, 'Khokhar', 'himnshuk.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '0964e17c-ce7e-4ae3-95d0-f7444834118e'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2c95e44f-933e-49eb-8222-71ca0fc2469a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '944337', '944337',
    'Sayani', NULL, 'Nandy', 'sayanin.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '9eb756d3-8c28-45cb-ac98-ad48ff522df8'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '99026f12-4857-4a8f-87db-fcacdf91b194'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '358367', '358367',
    'Pramod', NULL, 'Kumar', 'pramodp.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '0964e17c-ce7e-4ae3-95d0-f7444834118e'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '13f23689-0115-4c3a-ac87-88a0f689ea0a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '464696', '464696',
    'Ankan', NULL, 'Paul', 'paulankan16@gamil.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'cdf590ac-5115-4ea6-bad4-2c35001c71bb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '611223', '611223',
    'Hritam', NULL, 'Bhattacharyya', 'hrikbhattacharyya@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'dd4de469-d6c6-4665-af00-1a03fb58c930'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '260758', '260758',
    'Kuldeep', NULL, 'Debnath', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '18885a16-23a1-4ebd-a01b-06b5103f2523'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '773969', '773969',
    'Pranay', NULL, 'Singha', 'pranay.singha2011@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '46825f7a-d44b-4dd0-be59-3d6b9477a08e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '432043', '432043',
    'Dipak', NULL, 'Kumar', 'deepakk.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '0964e17c-ce7e-4ae3-95d0-f7444834118e'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '92c3c86a-68cf-4ef4-bf5a-ef65f8b6f032'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '425230', '425230',
    'Gaurav', 'Kumar', 'Tomar', 'gauravkumart.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '0964e17c-ce7e-4ae3-95d0-f7444834118e'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ecd0a1fa-9be2-4113-b456-0d3860583f9c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '168844', '168844',
    'Rajeev', NULL, 'Ranjan', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '0964e17c-ce7e-4ae3-95d0-f7444834118e'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'acf05e2b-c61e-46e7-8fe7-d5a8e72f45e6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '322963', '322963',
    'Arindam', NULL, 'Chakraborty', 'carindam410@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '83d4eb01-1946-4d36-ac04-761f805f61fd'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '59131fd2-72e8-4f61-ace4-dd25c3cacf84'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '774775', '774775',
    'Ashish', NULL, 'Chakraborty', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6f1a3140-7a74-4033-9fc9-519b8d3fac4f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '813b7ea9-979f-47a4-9b45-ae1e3fd77b3d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '418960', '418960',
    'Ankita', NULL, 'Koiri', 'ankita.anp.au@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '74b9b895-87db-4178-ad29-b6d5356f8804'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f9bb751f-e152-45a8-93ce-d53d0daf6a72'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089422', '089422',
    'Gita', 'Rani Das', 'Dhanuk', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '73d04325-77f2-4b2e-8822-165e06e5303f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '776568', '776568',
    'Haradhan', NULL, 'Dey', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '46e33204-4319-4fe6-9210-ad6278abf0e0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '595944', '595944',
    'Kshitish', 'Chandra', 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '24993651-753d-4c86-893f-db8db8c16bf1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '705463', '705463',
    'Nitai', 'Chandra', 'Saha', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2b408557-d69f-4586-83b9-864fa3feb794'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '867836', '867836',
    'Rajani', NULL, 'Dhanuk', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd74ab7e2-a47e-4029-a635-aadbb55d648a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '059931', '059931',
    'Rohit', NULL, 'Dhanuk', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e3948034-6180-4f8b-a9bc-c993545915b5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '537725', '537725',
    'Samir', NULL, 'Sutradhar', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c0972ba3-05a5-4bd1-8d0f-97d138973547'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '837817', '837817',
    'Sanjoy', 'Kumar', 'Deb', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3fe6e9e1-5bde-46b6-b272-6954fcb90b89'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '660611', '660611',
    'Siman', NULL, 'Rakshit', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd57bafba-9ab3-4c7a-9691-3450f57769a8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '675239', '675239',
    'Sudhir', NULL, 'Uria', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '41d3da5c-7158-46f9-bc4e-b84072283cdc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '977332', '977332',
    'Swadesh', NULL, 'Dhanuk', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1e944dc8-cfd0-4700-b0d8-857cefa30aa7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '554361', '554361',
    'Bijoy', NULL, 'Shil', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ed3defad-2db3-486c-a004-0c73d202e6ba'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '56768d7b-5345-48c2-a502-6b2b3e194bab'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '814841', '814841',
    'Chiranjit', NULL, 'Sutradhar', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ed3defad-2db3-486c-a004-0c73d202e6ba'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '56d947a8-70d4-43f8-b381-7c191b133105'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '119700', '119700',
    'Koushik', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ed3defad-2db3-486c-a004-0c73d202e6ba'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6abb7b4a-7039-49bb-bafe-0fd66284583f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089261', '089261',
    'Manjushree', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ed3defad-2db3-486c-a004-0c73d202e6ba'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ad1c254f-e0da-48a5-8169-9ea9389a8c77'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991831', '991831',
    'Sagar', NULL, 'Majumder', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ed3defad-2db3-486c-a004-0c73d202e6ba'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '30e32a54-27dc-44e1-b634-49222909a0ed'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '103575', '103575',
    'Sujal', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ed3defad-2db3-486c-a004-0c73d202e6ba'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1cb7de3c-5d05-4c12-becc-6a202c7d595f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '692945', '692945',
    'Biswajit', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '416df321-4979-4e2f-b71f-56705fc54043'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '221497', '221497',
    'Sudip', NULL, 'Biswas', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'cbbcc145-9a20-4bb5-928e-c18402229b69'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '723614', '723614',
    'Asam', 'Ray', 'Debbarma', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2b36ec65-63cc-47f4-bf67-a74a96970eae'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '334054', '334054',
    'Babul', NULL, 'Karmakar', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '552902be-8ef1-48cf-a996-692b1063905e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '069114', '069114',
    'Charan', 'Manik', 'Halam', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '999fc143-d214-40b5-b8d5-2db84a88b1d9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '266707', '266707',
    'Rajesh', NULL, 'Debbarma', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b5a60dea-2e22-4ae1-a485-7baef6e57c3c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '496988', '496988',
    'Sabitri', 'Podder', 'Roy', 'sabitripodderr.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '78424d35-46e3-4649-9aea-2828e3241a11'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '0a4333b4-e5b6-4218-85c7-669ac62d36d2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '829528', '829528',
    'Goutam', NULL, 'Roy', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '6241cdd0-1eb0-418c-9baa-49e410ff23c4'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e786c7ca-cffd-40e5-9d93-1eaaa91234c3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273300', '273300',
    'Arpan', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ed3defad-2db3-486c-a004-0c73d202e6ba'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3d113c7a-114d-404b-ad2c-cd7a23a1ca6f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '117874', '117874',
    'Jadab', NULL, 'Das', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, 'ed3defad-2db3-486c-a004-0c73d202e6ba'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'df6f4708-147a-4d69-9105-69a5a94021fa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '989373', '989373',
    'Rajesh', NULL, 'Chakraborty', 'chakraj27@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '8205a0b9-0b92-4216-810e-e072b0a880ee'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'dcb8c96c-c91b-4206-a758-e42597f172ac'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '878245', '878245',
    'Diptanu', NULL, 'Deb', 'deb.diptanu09@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '5e6a32de-3390-4ad4-b1b5-7567c38e86a8'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '44a103f1-f80c-4d52-845f-8959f55026d8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '287245', '287245',
    'Jhuntu', NULL, 'Dasgupta', 'jhuntudd.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '11d69b61-7d57-4c3f-937e-ea41717d8238'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'eb6365ba-5c59-41ae-a2f8-aede12723bbe'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '083321', '083321',
    'Nabajyoti', NULL, 'Debnath', 'nabajyotid.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '92146bf2-b182-40f0-af33-7a318ddcaf73'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e6403827-ea9d-4ee5-ac30-0cfd90731111'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '508317', '508317',
    'Samar', 'Chandra', 'Deb', 'samarchandrad.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '92146bf2-b182-40f0-af33-7a318ddcaf73'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a9560638-c19e-42f6-8174-bfeb3e67150d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '599624', '599624',
    'Santosh', NULL, 'Das', 'das71santosh@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '92146bf2-b182-40f0-af33-7a318ddcaf73'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1c301a8a-c35f-4db3-8253-9f9fb8066b16'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '677853', '677853',
    'Soumen', NULL, 'Banik', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '92146bf2-b182-40f0-af33-7a318ddcaf73'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7e51e8ec-0afc-4f8b-a919-0c510de073d5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '404232', '404232',
    'Ajoy', NULL, 'Dutta', 'ajoyd.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '11d69b61-7d57-4c3f-937e-ea41717d8238'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2d5d47d9-6477-4890-b80a-06cf59fc9d7c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '567588', '567588',
    'Debabrato', NULL, 'Chowdhury', 'debabratoc.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '11d69b61-7d57-4c3f-937e-ea41717d8238'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bf364bdd-74fc-491a-9f43-ad46cb81b188'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '799528', '799528',
    'Subodh', NULL, 'Debbarma', 'subodhd.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '11d69b61-7d57-4c3f-937e-ea41717d8238'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '236dc8ca-ce8d-453d-8e81-b85155f25b51'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '923432', '923432',
    'Uttam', NULL, 'Chakraborty', 'uttamc.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '11d69b61-7d57-4c3f-937e-ea41717d8238'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9011e3aa-7a9e-4c42-a57b-2e5a13ae93dd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '919704', '919704',
    'Tanushree', NULL, 'Biswas', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '1a8fa17d-68fd-485e-8db2-d5a267133138'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd6269acb-176b-45e0-b556-e980dd786a15'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '326801', '326801',
    'Dipannita', NULL, 'Das', 'dipannitad.kol.pdac@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '99286827-d833-4add-afd0-b60a9ca5966f'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fc17bfd2-05e3-4e18-b7f0-322c442ad351'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510617', '510617',
    'Bishu', NULL, 'Nandi', NULL,
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '92146bf2-b182-40f0-af33-7a318ddcaf73'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c5c57695-5905-45ea-9f11-43dcb45a40e2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382713', '382713',
    'Subhrajit', NULL, 'Roy', 'subhrajitr.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '92146bf2-b182-40f0-af33-7a318ddcaf73'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ee76c4b6-0544-4114-82f0-5d3c735a98e6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '980071', '980071',
    'Subrata', 'Das', 'Choudhury', 'chowdhurysd.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '11d69b61-7d57-4c3f-937e-ea41717d8238'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5a66bbb8-69d8-410b-a862-71505096aad9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '952380', '952380',
    'Rajashree', NULL, 'Chakraborty', 'rajashreec.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '92146bf2-b182-40f0-af33-7a318ddcaf73'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f8ad669d-3ac2-4758-928a-8ea6234eecf9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '109614', '109614',
    'Sanjay', 'Kumar', 'Yadav', 'sanjoykumary.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '783ec91a-36c5-4f1f-8d6e-845d1320a6ee'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '93fe038e-7c55-46f6-bba5-8b58f0927413'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '795304', '795304',
    'Arpan', NULL, 'Shil', 'arpanshil.agt@gmail.com',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '9ed0bbe1-d113-4a44-9ef4-434b949d8c61'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8680be5f-c274-4914-b4ec-e9be3ad1610d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '042174', '042174',
    'Pradip', 'Kumar', 'Nandi', 'pradipkn.tri.ae@cag.gov.in',
    '00d7df3c-5897-4a1a-a8fe-585408c2dddd'::uuid, '00a24bef-f62e-4642-a188-5e1402724fa3'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);

COMMIT;