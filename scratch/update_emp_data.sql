-- Reset and Truncate Employees Table

TRUNCATE TABLE employees CASCADE;


-- Section Upserts

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_EDP_PF', 'EDP PF', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_PENSION_1_SECTION', 'Pension-1 section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_IT_CELL', 'IT CELL', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_PENSION_2_SECTION', 'Pension-2 section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_HINDI_ANUBHAG', 'Hindi Anubhag', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_GENERAL', 'General', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_RECORD_SECTION', 'Record Section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_AG_CELL', 'AG Cell', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_DEPARTMENTAL_CANTEEN', 'Departmental Canteen', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_VLC', 'VLC', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_SR_DAG_CELL', 'Sr. DAG Cell', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_BOOK_SECTION', 'Book Section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_AC_SECTION', 'AC section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_FA_SECTION', 'FA Section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_PENSION_3_SECTION', 'Pension-3 section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_ESTABLISHMENT', 'Establishment', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_PAO_LOCAL', 'PAO (LOCAL)', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_CA_SECTION', 'CA Section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_TMC', 'TMC', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_ADMIN_SECTION', 'Admin Section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_EDP_GPF', 'EDP GPF', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_HOD_ACCOUNTANT_GENERAL_A_', 'HOD, Accountant General (A&E), Tripura', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_LEGAL_CELL', 'Legal Cell', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_LEGAL', 'Legal', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_SENIOR_DEPUTY_ACCOUNTANT_', 'Senior Deputy Accountant General (Sr. DAG), Tripura', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO sections (id, organization_id, code, name, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'SEC_RECORDS_SECTION', 'Records section', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET name = EXCLUDED.name;


-- Designation Upserts

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_SENIOR_ACCOUNTS_OFFICER', 'Senior Accounts Officer', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_ASST_ACCOUNTS_OFFICER', 'Asst. Accounts Officer', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_ASSISTANT_ACCOUNTS_OFFICE', 'Assistant Accounts Officer(AAO)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_ASSISTANT_SUPERVISOR', 'Assistant Supervisor', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_DEO_OUTSOURCED', 'DEO (Outsourced)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_JUNIOR_TRANSLATOR', 'Junior Translator', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_DEO_OUTSOURCED', 'DEO Outsourced', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_MULTI_TASKING_STAFF_OUTSO', 'Multi Tasking Staff (Outsourced)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_STENOGRAPHER_OUTSOURCED', 'Stenographer (Outsourced)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_MULTI_TASK_STAFF_MTS', 'Multi Task Staff (MTS)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_HALWAI', 'Halwai', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_ACCOUNTANT', 'Accountant', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_MTS_OUTSOURCED', 'MTS (OUTSOURCED)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_CASUAL_WORKER_TRIPURA', 'Casual Worker Tripura', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_SR_ACCOUNTANT', 'SR ACCOUNTANT', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_MULTI_TASK_STAFF', 'Multi Task Staff', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_CANTEEN_ATTENDANT', 'Canteen Attendant', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_DEO_GRADE_B', 'DEO Grade B', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_CONSULTANT_ACCOUNTANT', 'Consultant Accountant', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_SENIOR_HINDI_TRANSLATOR', 'Senior Hindi Translator', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_ROLL_OUT_SUPPORT_ENGINEER', 'Roll out Support Engineer', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_DATA_ENTRY_OPERATOR_OUTSO', 'Data Entry Operator (Outsourced)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_MTS', 'MTS', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_MULTI_TASKING_STAFF_NON_G', 'Multi Tasking Staff (Non Government)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_DATA_ENTRY_OPERATOR_B', 'Data Entry Operator B', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_SAO', 'SAO', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_SENIOR_ACCOUNTANT', 'Senior Accountant', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_CANTEEN_ATTENDANT_OUTSOUR', 'Canteen Attendant (Outsourced)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_CONSULTANT_ACCOUNTANT', 'Consultant (Accountant)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_SUPERVISOR', 'Supervisor', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_DATA_ENTRY_OPERATOR_GR_B', 'Data Entry Operator Gr B', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_SR_ACCOUNTANT', 'Sr. Accountant', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_OUTSOURCED_CANTEEN_MANAGE', 'Outsourced Canteen Manager', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_ACCOUNTANT_GENERAL', 'ACCOUNTANT GENERAL', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_STENOGRAPHER', 'Stenographer', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_CLERK_TYPIST', 'Clerk Typist', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_DATA_ENTRY_OPERATOR_GR_A', 'Data Entry Operator Gr A', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_DATA_ENTRY_OPERATOR_DEO', 'Data Entry Operator (DEO)', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_SR_ACCOUNTS_OFFICER', 'SR ACCOUNTS OFFICER', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_CLERK', 'Clerk', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_CANTEEN_CLERK', 'CANTEEN CLERK', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_SENIOR_DEPUTY_ACCOUNTANT_', 'Senior Deputy Accountant General', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;

INSERT INTO designations (id, organization_id, code, title, level, active, created_at, updated_at)
VALUES (gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', 'DES_DATA_ENTRY_OPERATOR', 'Data Entry Operator', 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (organization_id, code) DO UPDATE SET title = EXCLUDED.title;


-- Employee Upserts

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_PF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '404232', '404232',
        'AJOY', 'DUTTA', 'ajoyd.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (0 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (0 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_1_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '045677', '045677',
        'AMAR', 'CHANDRA DE', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (1 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (1 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_IT_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_ACCOUNTS_OFFICE' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '202868', '202868',
        'AMIT', 'GAURAV', 'amitgaurav.wbl.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (2 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (2 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_PF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '231116', '231116',
        'Anjana', 'Das', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (3 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (3 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_2_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DEO_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '464696', '464696',
        'Ankan', 'Paul', 'paulankan16@gamil.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (4 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (4 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_HINDI_ANUBHAG' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_JUNIOR_TRANSLATOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '418960', '418960',
        'Ankita', 'Koiri', 'ankita.anp.au@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (5 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (5 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_GENERAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '587084', '587084',
        'ANKUR', 'DEBBARMA', 'ankurd.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (6 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (6 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DEO_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '322963', '322963',
        'Arindam', 'Chakraborty', 'carindam410@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (7 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (7 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_AG_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASKING_STAFF_OUTSO' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '273300', '273300',
        'Arpan', 'Das', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (8 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (8 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_STENOGRAPHER_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '795304', '795304',
        'Arpan', 'Shil', 'arpanshil.agt@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (9 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (9 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASK_STAFF_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '723614', '723614',
        'Asam', 'Ray Debbarma', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (10 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (10 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_DEPARTMENTAL_CANTEEN' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_HALWAI' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '774775', '774775',
        'ASHISH', 'CHAKRABORTY', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (11 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (11 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_VLC' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '925906', '925906',
        'ASHISH', 'VERMA', 'ashishv.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (12 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (12 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_SR_DAG_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '863010', '863010',
        'Babul', 'Bhowmik', 'babulb.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (13 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (13 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASK_STAFF_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '334054', '334054',
        'Babul', 'Karmakar', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (14 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (14 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_BOOK_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '545651', '545651',
        'Banani', 'Das', 'babanib.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (15 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (15 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '554361', '554361',
        'BIJOY', 'SHIL', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (16 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (16 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_DEPARTMENTAL_CANTEEN' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CASUAL_WORKER_TRIPURA' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '586589', '586589',
        'Bimal', 'Sarkar', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (17 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (17 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_AC_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SR_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '510617', '510617',
        'BISHU', 'NANDI', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (18 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (18 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASK_STAFF' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '692945', '692945',
        'Biswajit', 'Das', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (19 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (19 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_FA_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '788426', '788426',
        'Biswajit', 'Datta', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (20 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (20 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_VLC' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '802702', '802702',
        'Biswanath', 'Chakraborty', 'biswanathc.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (21 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (21 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_BOOK_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '412074', '412074',
        'BUBAI', 'MONDAL', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (22 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (22 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_3_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '604228', '604228',
        'Champakali', 'Debbarma', 'champa68@rediffmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (23 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (23 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_VLC' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '510884', '510884',
        'Chandan', 'Debnath', 'chandand.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (24 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (24 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_DEPARTMENTAL_CANTEEN' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CANTEEN_ATTENDANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '149565', '149565',
        'CHANDAN', 'KUMAR DAS', 'Chandankd.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (25 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (25 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASK_STAFF_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '069114', '069114',
        'Charan', 'Manik Halam', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (26 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (26 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_GENERAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '310789', '310789',
        'CHHANDA', 'BANIK BHAUMIK', 'chhandab.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (27 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (27 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '814841', '814841',
        'Chiranjit', 'Sutradhar', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (28 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (28 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_3_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '545958', '545958',
        'Debabrata', 'Bhattacharjee', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (29 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (29 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_VLC' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '567588', '567588',
        'Debabrato', 'Chowdhury', 'debabratoc.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (30 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (30 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_2_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '452643', '452643',
        'Debasis', 'Biswas', 'debasisb.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (31 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (31 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_ESTABLISHMENT' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '273329', '273329',
        'Dibakar', 'Das', 'dibakard.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (32 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (32 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '454543', '454543',
        'Dipa', 'Karmakar', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (33 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (33 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_GENERAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DEO_GRADE_B' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '432043', '432043',
        'DIPAK', 'KUMAR', 'deepakk.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (34 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (34 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_GENERAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CONSULTANT_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '126173', '126173',
        'DIPANKAR', 'DEBNATH', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (35 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (35 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_ESTABLISHMENT' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_HINDI_TRANSLATOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '326801', '326801',
        'DIPANNITA', 'DAS', 'dipannitad.kol.pdac@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (36 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (36 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_IT_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ROLL_OUT_SUPPORT_ENGINEER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '878245', '878245',
        'Diptanu', 'Deb', 'deb.diptanu09@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (37 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (37 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DATA_ENTRY_OPERATOR_OUTSO' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '786106', '786106',
        'Diptanu', 'Roy', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (38 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (38 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PAO_LOCAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DEO_GRADE_B' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '425230', '425230',
        'GAURAV', 'KUMAR TOMAR', 'gauravkumart.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (39 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (39 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_1_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '625079', '625079',
        'GAUTAM', 'KUMAR', 'gautamk.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (40 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (40 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '089422', '089422',
        'Gita', 'Rani Das Dhanuk', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (41 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (41 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DATA_ENTRY_OPERATOR_OUTSO' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '351307', '351307',
        'GOBINDA', 'BHOWMIK', 'bhowmikgobinda19@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (42 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (42 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_AG_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CASUAL_WORKER_TRIPURA' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '969535', '969535',
        'GOPAL', 'KARMAKAR', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (43 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (43 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASKING_STAFF_NON_G' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '829528', '829528',
        'Goutam', 'Roy', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (44 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (44 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '776568', '776568',
        'HARADHAN', 'DEY', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (45 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (45 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_PF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DATA_ENTRY_OPERATOR_B' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '073976', '073976',
        'HIMANSHU', 'KHOKHAR', 'himnshuk.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (46 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (46 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DEO_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '611223', '611223',
        'Hritam', 'Bhattacharyya', 'hrikbhattacharyya@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (47 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (47 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASKING_STAFF_OUTSO' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '117874', '117874',
        'Jadab', 'Das', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (48 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (48 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_CA_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '970806', '970806',
        'Jayanti', 'Saha', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (49 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (49 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_IT_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SAO' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '287245', '287245',
        'JHUNTU', 'DASGUPTA', 'jhuntudd.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (50 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (50 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_PF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '192266', '192266',
        'JISHAN', 'CHOUDHURI', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (51 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (51 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_PF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '570806', '570806',
        'KEYA', 'SARKAR', 'keyas.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (52 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (52 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_3_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '970592', '970592',
        'Kishlay', 'Raj', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (53 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (53 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '119700', '119700',
        'KOUSHIK', 'DAS', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (54 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (54 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '595944', '595944',
        'Kshitish', 'Chandra Das', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (55 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (55 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DEO_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '260758', '260758',
        'Kuldeep', 'Debnath', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (56 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (56 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_TMC' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '716775', '716775',
        'Lokesh', 'Singh Manral', 'manral.lokesh@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (57 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (57 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_2_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '177893', '177893',
        'Malabika', 'Rakshit', 'mablabikar.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (58 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (58 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '089261', '089261',
        'Manjushree', 'Das', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (59 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (59 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_2_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '222819', '222819',
        'Mohammad', 'Naqi Ali', 'naqimadina12@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (60 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (60 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PAO_LOCAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '300159', '300159',
        'Mrityunjoy', 'Bhowmik', 'mrityunjoyb.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (61 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (61 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_2_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '083321', '083321',
        'Nabajyoti', 'Debnath', 'nabajyotid.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (62 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (62 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_DEPARTMENTAL_CANTEEN' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CANTEEN_ATTENDANT_OUTSOUR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '711741', '711741',
        'Nayan', 'Das', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (63 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (63 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_3_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '258696', '258696',
        'Nipun', 'Jain', 'nipunj.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (64 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (64 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_SR_DAG_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '705463', '705463',
        'Nitai', 'Chandra Saha', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (65 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (65 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_ADMIN_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '419627', '419627',
        'Palash', 'Banerjee', 'banerjeepalas@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (66 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (66 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CONSULTANT_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '992660', '992660',
        'Pankaj', 'Kumar Sarkar', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (67 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (67 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_ESTABLISHMENT' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '229834', '229834',
        'Paramita', 'Bhattacharjee', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (68 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (68 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '789991', '789991',
        'Partha', 'Debnath', 'parthad.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (69 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (69 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_ESTABLISHMENT' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '008233', '008233',
        'Pilan', 'Ngullie', 'pilann.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (70 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (70 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_VLC' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '787234', '787234',
        'Piyush', 'Prabhakar', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (71 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (71 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_GPF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '280235', '280235',
        'PRADIP', 'KARMAKAR', 'pradipk.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (72 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (72 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_IT_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '042174', '042174',
        'Pradip', 'Kumar Nandi', 'pradipkn.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (73 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (73 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_CA_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DATA_ENTRY_OPERATOR_GR_B' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '358367', '358367',
        'PRAMOD', 'KUMAR', 'pramodp.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (74 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (74 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '275804', '275804',
        'PRANAV', 'KUMAR', 'pranavk.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (75 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (75 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DEO_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '773969', '773969',
        'Pranay', 'Singha', 'pranay.singha2011@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (76 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (76 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_1_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '483866', '483866',
        'Prasenjit', 'Pal', 'prasenjitp.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (77 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (77 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_PF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '382834', '382834',
        'Priyadarshini', 'Singh', 'prdrshn91113@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (78 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (78 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PAO_LOCAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '991014', '991014',
        'RAHUL', 'KUMAR', 'rahulk.wbl.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (79 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (79 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_GENERAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '558271', '558271',
        'Raj', 'Kumar Debbarma', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (80 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (80 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CASUAL_WORKER_TRIPURA' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '942482', '942482',
        'Raja', 'Biswas', 'rajabiswas16696@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (81 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (81 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '867836', '867836',
        'RAJANI', 'DHANUK', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (82 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (82 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_ESTABLISHMENT' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SR_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '952380', '952380',
        'Rajashree', 'Chakraborty', 'rajashreec.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (83 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (83 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_ESTABLISHMENT' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '405349', '405349',
        'Rajeev', 'Kumar', 'rajeevkr.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (84 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (84 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_FA_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '296851', '296851',
        'Rajeev', 'Kumar', 'rajeevkumarag1985@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (85 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (85 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DEO_GRADE_B' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '168844', '168844',
        'RAJEEV', 'RANJAN', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (86 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (86 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_DEPARTMENTAL_CANTEEN' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_OUTSOURCED_CANTEEN_MANAGE' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '989373', '989373',
        'Rajesh', 'Chakraborty', 'chakraj27@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (87 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (87 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASK_STAFF_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '266707', '266707',
        'Rajesh', 'Debbarma', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (88 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (88 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_3_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '551720', '551720',
        'RAKESH', 'CHANDRA SRIVASTAV', 'rakeshcs.wbl.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (89 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (89 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '605543', '605543',
        'Rama', 'Bhattacharya', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (90 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (90 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_HOD_ACCOUNTANT_GENERAL_A_' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT_GENERAL' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '871058', '871058',
        'Ranendu', 'Sarkar', 'sarkarr@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (91 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (91 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_DEPARTMENTAL_CANTEEN' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CANTEEN_ATTENDANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '037947', '037947',
        'RATAN', 'GHOSH', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (92 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (92 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '059931', '059931',
        'Rohit', 'Dhanuk', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (93 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (93 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_LEGAL_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '296861', '296861',
        'ROHIT', 'YADAV', 'rohity.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (94 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (94 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASK_STAFF_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '496988', '496988',
        'Sabitri', 'Podder Roy', 'sabitripodderr.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (95 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (95 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_GENERAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '991831', '991831',
        'Sagar', 'Majumder', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (96 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (96 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_1_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '508317', '508317',
        'SAMAR', 'CHANDRA DEB', 'samarchandrad.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (97 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (97 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '537725', '537725',
        'SAMIR', 'SUTRADHAR', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (98 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (98 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_GENERAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_STENOGRAPHER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '109614', '109614',
        'SANJAY', 'KUMAR YADAV', 'sanjoykumary.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (99 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (99 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_2_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '265793', '265793',
        'SANJOY', 'KRISHNA DEBBARMA', 'sanjoykd.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (100 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (100 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '837817', '837817',
        'SANJOY', 'KUMAR DEB', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (101 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (101 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PAO_LOCAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '599624', '599624',
        'Santosh', 'Das', 'das71santosh@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (102 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (102 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_AC_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '738761', '738761',
        'Satish', 'Debbarma', 'satish71debbarma@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (103 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (103 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_TMC' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CLERK_TYPIST' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '792890', '792890',
        'Saurabh', 'Das', 'saurabhd.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (104 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (104 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_LEGAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DATA_ENTRY_OPERATOR_GR_A' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '944337', '944337',
        'Sayani', 'Nandy', 'sayanin.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (105 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (105 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_DEPARTMENTAL_CANTEEN' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CANTEEN_ATTENDANT_OUTSOUR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '060574', '060574',
        'Shahil', 'Singha', 'shahilsingha321@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (106 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (106 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CASUAL_WORKER_TRIPURA' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '756473', '756473',
        'SHIBU', 'DAS', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (107 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (107 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '660611', '660611',
        'SIMAN', 'RAKSHIT', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (108 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (108 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_GENERAL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '677853', '677853',
        'Soumen', 'Banik', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (109 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (109 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_2_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '457386', '457386',
        'SOURAV', 'MAJI', 'souravm.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (110 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (110 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_3_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '318974', '318974',
        'Srilekha', 'Dey', 'srilekhad.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (111 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (111 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_3_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '502040', '502040',
        'Subh', 'Karan Chauhan', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (112 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (112 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_LEGAL_CELL' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '786890', '786890',
        'SUBHAM', 'GHOSH', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (113 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (113 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_ESTABLISHMENT' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SR_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '382713', '382713',
        'Subhrajit', 'Roy', 'subhrajitr.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (114 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (114 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DATA_ENTRY_OPERATOR_DEO' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '541791', '541791',
        'SUBHRANIL', 'DEBROY', 'subhranil191@gmail.com', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (115 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (115 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_3_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '799528', '799528',
        'Subodh', 'Debbarma', 'subodhd.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (116 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (116 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_TMC' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SR_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '980071', '980071',
        'SUBRATA', 'DAS CHOUDHURY', 'chowdhurysd.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (117 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (117 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_2_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '603680', '603680',
        'Suchana', 'Das', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (118 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (118 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_1_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '137660', '137660',
        'SUDHA', 'RANJAN DEBBARMA', 'sudharanjand.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (119 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (119 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '675239', '675239',
        'SUDHIR', 'URIA', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (120 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (120 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_ESTABLISHMENT' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '642211', '642211',
        'Sudip', 'Barman', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (121 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (121 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MULTI_TASK_STAFF' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '221497', '221497',
        'Sudip', 'Biswas', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (122 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (122 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS_OUTSOURCED' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '103575', '103575',
        'Sujal', 'Das', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (123 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (123 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_PF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '423533', '423533',
        'SUKHENDU', 'BHAUMIK', 'sukhendub.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (124 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (124 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CASUAL_WORKER_TRIPURA' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '859252', '859252',
        'Sumit', 'Dhanuk', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (125 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (125 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_PF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CLERK' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '258186', '258186',
        'SUMITA', 'BOSE DEY', 'sumitab.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (126 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (126 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_GPF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '482594', '482594',
        'Sunil', 'Kumar', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (127 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (127 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_FA_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '354091', '354091',
        'Suraj', 'Kishore', 'surajk.wbl.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (128 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (128 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_MTS' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '977332', '977332',
        'SWADESH', 'DHANUK', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (129 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (129 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_DEPARTMENTAL_CANTEEN' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_CANTEEN_CLERK' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '998024', '998024',
        'Swapan', 'Bhowmik', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (130 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (130 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_SENIOR_DEPUTY_ACCOUNTANT_' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_DEPUTY_ACCOUNTANT_' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '919704', '919704',
        'Tanushree', 'Biswas', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (131 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (131 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_1_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASSISTANT_SUPERVISOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '090908', '090908',
        'TAPAN', 'KUMAR SARKAR', 'tapankumars.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (132 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (132 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORD_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_DATA_ENTRY_OPERATOR' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '223506', '223506',
        'Thaingla', 'Mog', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (133 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (133 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_EDP_PF' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ACCOUNTANT' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '515186', '515186',
        'UDIYAN', 'BOSE', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (134 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (134 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_PENSION_1_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_SENIOR_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '923432', '923432',
        'UTTAM', 'CHAKRABORTY', 'uttamc.tri.ae@cag.gov.in', v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (135 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (135 * INTERVAL '1 millisecond')
    );
END $$;

DO $$
DECLARE
    v_sec_id uuid;
    v_des_id uuid;
BEGIN
    SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'SEC_RECORDS_SECTION' LIMIT 1;
    IF v_sec_id IS NULL THEN
        SELECT id INTO v_sec_id FROM sections WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' AND code = 'DES_ASST_ACCOUNTS_OFFICER' LIMIT 1;
    IF v_des_id IS NULL THEN
        SELECT id INTO v_des_id FROM designations WHERE organization_id = '01a029f9-4568-7c32-9782-f69a23782652' LIMIT 1;
    END IF;

    INSERT INTO employees (
        id, organization_id, employee_code, attendance_device_user_id,
        first_name, last_name, email, section_id, designation_id,
        attendance_rule_id, joining_date, status, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), '01a029f9-4568-7c32-9782-f69a23782652', '081342', '081342',
        'Vishal', 'Verma', NULL, v_sec_id, v_des_id,
        '01a02d55-d7a6-7df4-99b1-ee21116f52a6', CURRENT_DATE, 'ACTIVE',
        CURRENT_TIMESTAMP + (136 * INTERVAL '1 millisecond'),
        CURRENT_TIMESTAMP + (136 * INTERVAL '1 millisecond')
    );
END $$;