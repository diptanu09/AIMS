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
VALUES ('7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT', 'Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('029730df-87a8-4de7-9987-954096def4ce'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ACCOUNTANT_GENERAL_A_E', 'Accountant General (A&E)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('0d321984-ddaf-49d4-8d9f-5453a065875d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASSISTANT_SUPERVISOR', 'Assistant Supervisor', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('abb6e966-d8be-4e0d-8e25-c8dc388f700d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ASST_ACCOUNTS_OFFICER', 'Asst. Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('3241e7a9-21be-4d21-a7b9-42694b072945'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT', 'Canteen Attendant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('b322e88b-f745-4c43-9d99-951a45f7f88e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_ATTENDANT_OUTSOURCED', 'Canteen Attendant (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('1384e377-4e12-44c5-b1fb-03b006033f54'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CANTEEN_CLERK', 'Canteen Clerk', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('29c40733-cfce-460b-bcbe-737bee9d0790'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CASUAL_WORKER_TRIPURA', 'Casual Worker Tripura', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('6d7c0b9d-92d8-4436-be12-926bef5299d7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CLERK_TYPIST', 'Clerk Typist', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('71971748-f1f6-4902-a186-10814d567d0f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_CONSULTANT_ACCOUNTANT', 'Consultant Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('6127330f-6226-4048-8a4d-672fba99a456'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_OUTSOURC', 'Data Entry Operator (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('786860a9-2cbc-4183-899e-b3d57431a52e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_A', 'Data Entry Operator Gr A', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('97aad500-e18b-4153-8a67-6e5e15ebf445'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_DATA_ENTRY_OPERATOR_GR_B', 'Data Entry Operator Gr B', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('e248738c-fda1-4bfc-9b2a-51dbb12b9f43'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_HALWAI', 'Halwai', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('9e2267f9-fde0-4596-84e1-4b0091da579e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_JUNIOR_TRANSLATOR', 'Junior Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('64e9f2a6-e8c3-48ea-bb51-ba5b1f773d92'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASK_STAFF', 'Multi Task Staff', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('29d248c0-5a67-4ccf-ae8c-29f5de3ed80d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_MULTI_TASKING_STAFF_OUTSOURC', 'Multi Tasking Staff (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('dfbf9e1b-3058-4ef6-a7eb-d88b68fda4b0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_OUTSOURCED_CANTEEN_MANAGER', 'Outsourced Canteen Manager', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('b648f400-21da-4944-94ff-ab84d0864f0d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_ROLL_OUT_SUPPORT_ENGINEER', 'Roll out Support Engineer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('a06b9733-c430-4167-80a7-83ea523e93a9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTANT', 'Senior Accountant', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('0cffdcbe-39f8-4497-8ee0-01db98f04ec7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_ACCOUNTS_OFFICER', 'Senior Accounts Officer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('56395316-90eb-4302-af94-e2b526f39686'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_DEPUTY_ACCOUNTANT_GEN', 'Senior Deputy Accountant General', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('d792beda-7327-4e69-a426-4eaf6afe72ba'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SENIOR_HINDI_TRANSLATOR', 'Senior Hindi Translator', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('b870b9bf-2ffa-4398-aa9d-9f5f7ee292d4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER', 'Stenographer', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('8591f814-5204-4c0b-882f-b5e277f8ba42'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_STENOGRAPHER_OUTSOURCED', 'Stenographer (Outsourced)', 1, TRUE);
INSERT INTO designations (id, organization_id, code, title, level, active)
VALUES ('e76bafc5-c0fc-4611-8e70-9374ce591bf5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'DES_SUPERVISOR', 'Supervisor', 1, TRUE);

-- Master Sections
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_UNASSIGNED', 'Unassigned / General Pool', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('24178d9d-4494-5f96-a6b3-e80d4d329f32'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_HOD_ACCOUNTANT_GENERAL_A_E_T', 'HoD, Accountant General (A&E), Tripura', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('c22fc1df-324b-596f-971c-ac0a6335c348'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_SENIOR_DEPUTY_ACCOUNTANT_GEN', 'Senior Deputy Accountant General (Sr. DAG), Tripura', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('52a2470d-bd2a-5c4f-aeab-8dca3513d051'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_BOOK_SECTION', 'Book Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('1c0c5149-cc8a-59fe-ae9f-bf10b6dcc2c3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_RECORD_SECTION', 'Record Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('737709ce-9a80-5acf-a097-aadc6401c7ed'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_SR_DAG_CELL', 'Sr.DAG Cell', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('31a3db36-33cc-57ac-8b66-686676eabd22'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_ESTABLISHMENT', 'Establishment', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('e3fccbc0-9407-50b3-9029-6cbf6ce4330d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_A_G_SECTARIAT', 'A.G. Sectariat', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('3759e021-d3ea-5c5a-9307-d000c3de7c28'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_TMC', 'TMC', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('1c19b978-bb42-5bf1-ace4-d57743756b29'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_DEPARTMENTAL_CANTEEN', 'Departmental Canteen', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('e1fe9244-7f70-5670-a19c-cbece87be61b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_FA_CELL', 'FA Cell', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('8d413bee-3549-5cab-bca9-9aa1e04908d8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_AC_SECTION', 'AC section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('0bc25ae6-956f-59a5-9a1a-4cb6d6e4b946'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_EDP_PF', 'EDP-PF', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('62170ae5-eee2-5fd1-a48e-2249e3d220de'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_PAO_LOCAL', 'PAO  (Local)', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('736a8dea-f345-5c4a-811f-0905b52ad1a5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_VLCS', 'VLCS', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('3c00f6bf-bed5-5496-b552-9cedd2a53e57'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_EDP_GPF', 'EDP-GPF', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('b0045605-71ef-57fd-be0b-90c850d9ba92'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_HINDI_ANUBHAG', 'Hindi Anubhag', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('8320d373-8933-5402-9083-d540725896c9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_PENSION_I', 'Pension -I', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('dcff6266-a56c-5bcf-b29f-5c8a357a4acd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_PENSION_III', 'Pension-III', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('b23932c0-d602-59af-ad81-0e0a55d7d65f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_LEGAL_SECTION', 'Legal Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('70415bbb-2d73-59ad-b778-f3954f08b4fb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_PENSION_II', 'Pension-II', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('9505be0a-f264-5a14-a1c8-3c5c4a52bcd3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_IT_CELL', 'IT CELL', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('800bc923-68eb-5cbf-a555-b8e9c698e453'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_ITA_SECTION', 'ITA Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('e2d66dd6-9279-50c3-a5ed-c21548403e4c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_AG_CELL', 'AG Cell', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('72819fe6-ae15-5f9a-9d22-cc934b2b2337'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_CA_SECTION', 'CA Section', TRUE);
INSERT INTO sections (id, organization_id, code, name, active)
VALUES ('388a146c-4d49-5fc0-a77b-d73eeceb4811'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, 'SEC_ADMINISTRATION', 'Administration', TRUE);

-- Master Employees
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7d7c0488-d1dd-4a76-a957-1d9004176b10'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '045677', '045677',
    'Amar', 'Chandra', 'De', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '20266469-ed59-4024-9edf-6c770c81ecd8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '716775', '716775',
    'Lokesh', 'Singh', 'Manral', 'manral.lokesh@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1be8d483-c21e-48a8-8881-eb5bed8d1ed3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258696', '258696',
    'Nipun', NULL, 'Jain', 'nipunj.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '33e6de44-3ff3-412a-8f02-31a641edcced'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '419627', '419627',
    'Palash', NULL, 'Banerjee', 'banerjeepalas@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5ede3553-6224-4b8a-95b3-bac097827e9c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '787234', '787234',
    'Piyush', NULL, 'Prabhakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '121a8649-77e1-4113-9e47-52d8e15bfcf8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382834', '382834',
    'Priyadarshini', NULL, 'Singh', 'prdrshn91113@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3792462a-1b18-4b1c-929d-4e65321aec40'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991014', '991014',
    'Rahul', NULL, 'Kumar', 'rahulk.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7656657c-4d27-4bfb-a1f5-459e0995f76d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '551720', '551720',
    'Rakesh', 'Chandra', 'Srivastav', 'rakeshcs.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'bdb6eff0-44cb-416d-bc9b-d9da75e05b23'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296861', '296861',
    'Rohit', NULL, 'Yadav', 'rohity.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c969d10f-7dc4-4f75-97c3-12a487719a6c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '457386', '457386',
    'Sourav', NULL, 'Maji', 'souravm.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5da75c55-6a0a-4fd3-8746-5f0d70ae10ad'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '354091', '354091',
    'Suraj', NULL, 'Kishore', 'surajk.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e6807a51-f1fe-47ae-a063-b53482b51284'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '081342', '081342',
    'Vishal', NULL, 'Verma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd6696f2b-88b1-46da-b78d-d9947ee1fea5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '925906', '925906',
    'Ashish', NULL, 'Verma', 'ashishv.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4b49dae7-0a3f-48b5-8eff-4c8796cba6d8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '412074', '412074',
    'Bubai', NULL, 'Mondal', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9b877761-55a7-42f9-8245-9db0fabf60f5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273329', '273329',
    'Dibakar', NULL, 'Das', 'dibakard.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5e4f9664-c2ee-4ce1-a998-4fcdefa3cf0b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '454543', '454543',
    'Dipa', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '50d88b2f-96d2-4174-b00a-47a0f16c40cd'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '625079', '625079',
    'Gautam', NULL, 'Kumar', 'gautamk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a315ef3b-a005-492d-8cc1-078c303d7477'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970806', '970806',
    'Jayanti', NULL, 'Saha', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'eecd3171-7cce-4e19-b6e4-9d3838be8e17'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '192266', '192266',
    'Jishan', NULL, 'Choudhuri', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7a28dcce-b227-438a-8584-9e0e257285e7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '570806', '570806',
    'Keya', NULL, 'Sarkar', 'keyas.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '14675870-ae1f-4de0-9d04-9edb45e37be3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '970592', '970592',
    'Kishlay', NULL, 'Raj', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9a227005-db8a-4ce4-9302-9c6cae76ba85'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '222819', '222819',
    'Mohammad', 'Naqi', 'Ali', 'naqimadina12@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '571a1912-b1c9-4d71-8c22-0fce556bc5e4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '229834', '229834',
    'Paramita', NULL, 'Bhattacharjee', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e0667b42-3330-49f4-9264-fe0d71e9ceeb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '789991', '789991',
    'Partha', NULL, 'Debnath', 'parthad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd3b38288-e131-4bef-908f-d60eb0bd309f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '008233', '008233',
    'Pilan', NULL, 'Ngullie', 'pilann.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2074ef87-670e-4f24-87ff-c0858feeb693'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '275804', '275804',
    'Pranav', NULL, 'Kumar', 'pranavk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '351317e7-650b-4d47-8c38-a1c9ebe47684'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '296851', '296851',
    'Rajeev', NULL, 'Kumar', 'rajeevkumarag1985@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f82d5eb3-2119-4574-892b-ab7cd1049aa0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '405349', '405349',
    'Rajeev', NULL, 'Kumar', 'rajeevkr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '15a8b9f9-45d1-4560-8a13-7ff063ac4075'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786890', '786890',
    'Subham', NULL, 'Ghosh', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '27f1e8ee-2b93-4291-a05b-f13c92f96ff0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '642211', '642211',
    'Sudip', NULL, 'Barman', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'cd5007d0-b377-4480-b2c3-55ba3358af67'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '482594', '482594',
    'Sunil', NULL, 'Kumar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b6ffa04f-1d5b-41dd-b548-d19728bfac78'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '515186', '515186',
    'Udiyan', NULL, 'Bose', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a77c8fb8-f866-4b02-be95-4b0a35e8e62e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '871058', '871058',
    'Ranendu', NULL, 'Sarkar', 'sarkarr@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '04a6066d-dcbf-48cf-b865-ff64d4c7739d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '202868', '202868',
    'Amit', NULL, 'Gaurav', 'amitgaurav.wbl.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '60ad26ff-d311-495a-9767-5872c1f35cda'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '231116', '231116',
    'Anjana', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5befa9a4-e011-49b5-bbb2-3aca641c62ea'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '587084', '587084',
    'Ankur', NULL, 'Debbarma', 'ankurd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '62fe46df-6cc3-49ce-bcaa-21fe6e388363'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '863010', '863010',
    'Babul', NULL, 'Bhowmik', 'babulb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2bbe45ff-f03b-41f8-9af5-3b267e1904d8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545651', '545651',
    'Banani', NULL, 'Das', 'babanib.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c31f1bbb-eae9-4a2b-9c79-ed0836cdb9a4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '788426', '788426',
    'Biswajit', NULL, 'Datta', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2bb77c1b-9bc0-47fc-9ec4-e62e7015ef8c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '802702', '802702',
    'Biswanath', NULL, 'Chakraborty', 'biswanathc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ad7f89f0-0de6-4ff5-9dec-c85d70f325f5'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '604228', '604228',
    'Champakali', NULL, 'Debbarma', 'champa68@rediffmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '80d0e190-007a-4ca6-85d4-656b85ac5ea4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510884', '510884',
    'Chandan', NULL, 'Debnath', 'chandand.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c96c0139-04da-4ea6-8c98-7b7ea8654b0d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '310789', '310789',
    'Chhanda', 'Banik', 'Bhaumik', 'chhandab.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3a4e199e-9123-479f-812a-e1401f0a549b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '545958', '545958',
    'Debabrata', NULL, 'Bhattacharjee', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a7e543c9-960e-4011-befb-d9e62c95eec6'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '452643', '452643',
    'Debasis', NULL, 'Biswas', 'debasisb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '90daa9b0-60e8-41cd-a3c4-447b38accfe9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '177893', '177893',
    'Malabika', NULL, 'Rakshit', 'mablabikar.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '89d5052a-3929-47b6-86be-0f480f08ebca'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '300159', '300159',
    'Mrityunjoy', NULL, 'Bhowmik', 'mrityunjoyb.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'df2cf289-9ee8-4103-ab37-c2f58f880793'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '280235', '280235',
    'Pradip', NULL, 'Karmakar', 'pradipk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f4485c5f-15ca-4b57-bb10-529bdab564fe'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '483866', '483866',
    'Prasenjit', NULL, 'Pal', 'prasenjitp.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8a5dffff-ada5-467c-9242-be1f4bb1698b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '558271', '558271',
    'Raj', 'Kumar', 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd088bc7d-629a-4197-80b7-ea3ff8cfa307'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '605543', '605543',
    'Rama', NULL, 'Bhattacharya', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a5a868ea-d031-496f-a9a3-41bf1bb044aa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '265793', '265793',
    'Sanjoy', 'Krishna', 'Debbarma', 'sanjoykd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e2306b44-2dd0-48bc-882c-ecf6bd0bfb87'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '738761', '738761',
    'Satish', NULL, 'Debbarma', 'satish71debbarma@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '45f3e4de-e719-432a-8753-775bd433ec76'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '318974', '318974',
    'Srilekha', NULL, 'Dey', 'srilekhad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7582951c-9c0b-4bb9-bd46-6a8df38bcd07'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '502040', '502040',
    'Subh', 'Karan', 'Chauhan', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2665b161-a1b1-44f3-9bcb-0ac540cf7a01'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '603680', '603680',
    'Suchana', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '335e9df0-7617-4251-9dca-d8b63b49e34e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '137660', '137660',
    'Sudha', 'Ranjan', 'Debbarma', 'sudharanjand.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ee2330be-18a7-46c0-997b-354c45123052'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '423533', '423533',
    'Sukhendu', NULL, 'Bhaumik', 'sukhendub.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6f9542ba-ca06-472d-b386-d62557b58523'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '090908', '090908',
    'Tapan', 'Kumar', 'Sarkar', 'tapankumars.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '710753e6-93e6-4720-95ad-ed5550dd80f2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '149565', '149565',
    'Chandan', 'Kumar', 'Das', 'Chandankd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e190a559-ea56-4210-838d-6ed7396889a4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '037947', '037947',
    'Ratan', NULL, 'Ghosh', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '974080a0-ecd6-4f18-b7b3-c4ab3c96e614'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '711741', '711741',
    'Nayan', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '3669dc09-ea5b-4d3b-88e2-ce3f9de4b742'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '060574', '060574',
    'Shahil', NULL, 'Singha', 'shahilsingha321@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9ef80f31-ea6d-4e1b-bb2a-caedfe52169b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '998024', '998024',
    'Swapan', NULL, 'Bhowmik', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '99a196e9-b14b-4663-a7df-178a9c7c0f39'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '586589', '586589',
    'Bimal', NULL, 'Sarkar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c3bfe31d-1f4f-4f65-8173-4a31515aaffc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '969535', '969535',
    'Gopal', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'dabb4a35-e1f8-4f19-a5d8-8db63802eb5a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '942482', '942482',
    'Raja', NULL, 'Biswas', 'rajabiswas16696@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ae9a9b41-9baa-4202-8be8-c66c1b601c38'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '756473', '756473',
    'Shibu', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8b04498a-e428-4475-824c-f88cd7bff59e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '859252', '859252',
    'Sumit', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8dd3935e-23be-40e5-9377-a9ff1918c895'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '258186', '258186',
    'Sumita', 'Bose', 'Dey', 'sumitab.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '888ddeef-e17e-4c64-90cc-6e137cd8021f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '792890', '792890',
    'Saurabh', NULL, 'Das', 'saurabhd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e44b2616-9c93-4b37-87c1-374938587b9b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '992660', '992660',
    'Pankaj', 'Kumar', 'Sarkar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c58a47c5-23c4-4723-a768-85879cd8be89'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '126173', '126173',
    'Dipankar', NULL, 'Debnath', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '76076d20-1e7f-4011-8afb-3d1a24ab6756'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '223506', '223506',
    'Thaingla', NULL, 'Mog', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '52f8b36d-6040-4e63-bae5-591b986f0cda'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '541791', '541791',
    'Subhranil', NULL, 'Debroy', 'subhranil191@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f4c0e220-0f07-4c78-925f-57f446ed6c81'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '786106', '786106',
    'Diptanu', NULL, 'Roy', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '02fc2841-82b2-4b16-bd89-d1c290e4f7a2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '351307', '351307',
    'Gobinda', NULL, 'Bhowmik', 'bhowmikgobinda19@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '82cebeae-2f7b-49b9-af0a-7ea40bb049fb'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '073976', '073976',
    'Himanshu', NULL, 'Khokhar', 'himnshuk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '197cf8b4-2a6f-415b-9317-d59e3ac66f1e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '944337', '944337',
    'Sayani', NULL, 'Nandy', 'sayanin.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9be8a51e-7aec-4a55-b25a-a97e480f13fa'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '358367', '358367',
    'Pramod', NULL, 'Kumar', 'pramodp.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd98947ae-4a9c-4002-a2d8-4433d16e05b2'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '464696', '464696',
    'Ankan', NULL, 'Paul', 'paulankan16@gamil.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c770923e-aebf-4910-ada6-0af62314a529'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '611223', '611223',
    'Hritam', NULL, 'Bhattacharyya', 'hrikbhattacharyya@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a6a5cdd2-8995-48af-9091-236ce29ac213'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '260758', '260758',
    'Kuldeep', NULL, 'Debnath', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f969e06e-bd35-4cd3-b357-89fed917609e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '773969', '773969',
    'Pranay', NULL, 'Singha', 'pranay.singha2011@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '465c4c8a-03e0-403a-8447-77baaf5a4b85'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '432043', '432043',
    'Dipak', NULL, 'Kumar', 'deepakk.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '35a58cbd-b135-4d26-837a-5303f29f7c26'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '425230', '425230',
    'Gaurav', 'Kumar', 'Tomar', 'gauravkumart.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '33ae836e-b471-44d2-9ba1-4a7beff44029'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '168844', '168844',
    'Rajeev', NULL, 'Ranjan', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'cffb9bc4-7428-45df-af11-c357f3a9601b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '322963', '322963',
    'Arindam', NULL, 'Chakraborty', 'carindam410@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '4a7611de-8bd4-46af-bcac-6b86f8d9d1d0'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '774775', '774775',
    'Ashish', NULL, 'Chakraborty', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '316c40a2-9844-49e0-bd9e-d5ab1cfb27bc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '418960', '418960',
    'Ankita', NULL, 'Koiri', 'ankita.anp.au@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '1552e73f-f8d9-4746-8905-81fc0eaa734e'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089422', '089422',
    'Gita', 'Rani Das', 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '7129df38-6fec-4aec-ad42-50deebd4a965'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '776568', '776568',
    'Haradhan', NULL, 'Dey', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '276d52f1-4b62-412a-afa9-94d427dc1bd4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '595944', '595944',
    'Kshitish', 'Chandra', 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '50348fbe-dec5-4432-8df7-2133b69ef240'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '705463', '705463',
    'Nitai', 'Chandra', 'Saha', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ec9614ab-7dee-49e0-afd5-ed98421ba7fc'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '867836', '867836',
    'Rajani', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd45c52f6-8ab4-4a46-9d28-6c62141027ed'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '059931', '059931',
    'Rohit', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5cf58070-47c0-4206-ad28-abb6b8eeb7c3'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '537725', '537725',
    'Samir', NULL, 'Sutradhar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '9e157c13-923f-4bd3-bcf0-d04d9605405f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '837817', '837817',
    'Sanjoy', 'Kumar', 'Deb', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e5271c71-c661-40c3-8f76-eee30880d907'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '660611', '660611',
    'Siman', NULL, 'Rakshit', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c49b99e7-cb72-43ea-8285-89892920091b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '675239', '675239',
    'Sudhir', NULL, 'Uria', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '01ad483b-41ea-425b-8a03-7661509263d8'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '977332', '977332',
    'Swadesh', NULL, 'Dhanuk', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'c2b57515-07f9-4949-a822-b1fa6829b45d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '554361', '554361',
    'Bijoy', NULL, 'Shil', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b88e794c-50a2-4364-862c-997987a9837b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '814841', '814841',
    'Chiranjit', NULL, 'Sutradhar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fe2114ea-0bf1-4b52-b3f3-c2ae9605df07'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '119700', '119700',
    'Koushik', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e3d3a54a-b1a3-482c-ab63-14aaa33b6ea1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '089261', '089261',
    'Manjushree', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd6dcf452-2a40-4233-8eda-80332bb70110'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '991831', '991831',
    'Sagar', NULL, 'Majumder', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'df0de0eb-f1f8-404e-80c5-a41e02adca8f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '103575', '103575',
    'Sujal', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '8c150ad5-3971-4720-aa9e-225ee25fc563'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '692945', '692945',
    'Biswajit', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '18ba3e41-46d0-4059-90b1-b046a9c1bbe7'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '221497', '221497',
    'Sudip', NULL, 'Biswas', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '6b5004ba-125c-4c1e-92b1-85778f8bbb35'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '723614', '723614',
    'Asam', 'Ray', 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '844c64ba-a2df-422b-8967-fa7036a6028f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '334054', '334054',
    'Babul', NULL, 'Karmakar', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '903f8309-6bec-4d72-927b-80778aac4e24'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '069114', '069114',
    'Charan', 'Manik', 'Halam', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fa9ac8a1-5be1-483b-a3df-5ba388fdcb95'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '266707', '266707',
    'Rajesh', NULL, 'Debbarma', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '996e78f0-4788-4c77-8dce-2c32d7c1cddf'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '496988', '496988',
    'Sabitri', 'Podder', 'Roy', 'sabitripodderr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '365455ef-00c4-4d88-adfb-ce1914e8aeab'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '829528', '829528',
    'Goutam', NULL, 'Roy', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e6119633-3479-4ec8-ac84-bd4fa8824f2a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '273300', '273300',
    'Arpan', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ea3ad0ce-68d4-4056-b252-96f18965269a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '117874', '117874',
    'Jadab', NULL, 'Das', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'ac5d175e-fd7e-40cc-a611-b9c58ca674ea'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '989373', '989373',
    'Rajesh', NULL, 'Chakraborty', 'chakraj27@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b0f982ca-3dbd-4966-9d1b-53496c245da4'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '878245', '878245',
    'Diptanu', NULL, 'Deb', 'deb.diptanu09@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '38d4aea2-8f91-46ce-9187-adb0853cd00d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '287245', '287245',
    'Jhuntu', NULL, 'Dasgupta', 'jhuntudd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'b1159e10-ad95-45e1-8f73-d4e79c85376c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '083321', '083321',
    'Nabajyoti', NULL, 'Debnath', 'nabajyotid.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '058b775e-8f4c-43b2-8330-0f7c086c3116'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '508317', '508317',
    'Samar', 'Chandra', 'Deb', 'samarchandrad.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '28cba8d5-3d2c-4d01-8550-9b493ad18019'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '599624', '599624',
    'Santosh', NULL, 'Das', 'das71santosh@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5f713a96-a20d-48a0-bf4b-ffb08c8bab5f'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '677853', '677853',
    'Soumen', NULL, 'Banik', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '107ee686-395a-45aa-9754-2568a2e96644'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '404232', '404232',
    'Ajoy', NULL, 'Dutta', 'ajoyd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'a4bc6468-a0fd-41cd-b42e-9791b31ef66b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '567588', '567588',
    'Debabrato', NULL, 'Chowdhury', 'debabratoc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'd1900ce6-d263-4678-982c-4146a3f439d1'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '799528', '799528',
    'Subodh', NULL, 'Debbarma', 'subodhd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'fbdea6a2-b180-4934-9a6d-3e8af73ed583'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '923432', '923432',
    'Uttam', NULL, 'Chakraborty', 'uttamc.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '41031912-a246-4ab5-a94e-e6c5866692cf'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '919704', '919704',
    'Tanushree', NULL, 'Biswas', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '799989e4-207b-43d7-be10-9f57ac55a71c'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '326801', '326801',
    'Dipannita', NULL, 'Das', 'dipannitad.kol.pdac@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '2b1bde58-f076-465b-a4d3-485e7ad0f84a'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '510617', '510617',
    'Bishu', NULL, 'Nandi', NULL,
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '42c7bc7b-3786-4d69-b1f8-7b764f2f85f9'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '382713', '382713',
    'Subhrajit', NULL, 'Roy', 'subhrajitr.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5549ffc3-b91d-4de7-97fd-e744a71d0c56'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '980071', '980071',
    'Subrata', 'Das', 'Choudhury', 'chowdhurysd.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '19ab384e-a7d6-4604-a134-16639d00425b'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '952380', '952380',
    'Rajashree', NULL, 'Chakraborty', 'rajashreec.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'e38dd9e5-5646-4e3c-8029-b496d8b96020'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '109614', '109614',
    'Sanjay', 'Kumar', 'Yadav', 'sanjoykumary.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    'f240e1f4-a740-4612-b34d-71b728f2dd7d'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '795304', '795304',
    'Arpan', NULL, 'Shil', 'arpanshil.agt@gmail.com',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);
INSERT INTO employees (
    id, organization_id, employee_code, attendance_device_user_id,
    first_name, middle_name, last_name, email,
    section_id, designation_id, attendance_rule_id,
    joining_date, status
) VALUES (
    '5c6ad3fe-174f-4af7-b18e-c31f693f5e14'::uuid, '01a029f9-4568-7c32-9782-f69a23782652'::uuid, '042174', '042174',
    'Pradip', 'Kumar', 'Nandi', 'pradipkn.tri.ae@cag.gov.in',
    'a49e4762-813b-4bbe-b997-172fcf55a05a'::uuid, '7bf70b52-c328-4208-afdb-6051da09e134'::uuid, '01a02d55-d7a6-7df4-99b1-ee21116f52a6'::uuid,
    '2026-01-01', 'ACTIVE'::employee_status
);

COMMIT;