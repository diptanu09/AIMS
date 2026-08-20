-- 001_default_roles_permissions.sql
-- Default RBAC Roles and Permissions Seed Data (v1.1)

INSERT INTO roles (name, description) VALUES
('SUPER_ADMIN', 'Super Administrator with unrestricted access'),
('ADMIN', 'Organization Administrator'),
('ATTENDANCE_ADMIN', 'Attendance Operations Manager'),
('BO', 'Branch / Section Officer'),
('AAO', 'Assistant Accounts / Section Officer'),
('REPORT_USER', 'Report Generation User'),
('VIEW_ONLY', 'Read-only Section Access User')
ON CONFLICT (name) DO NOTHING;

INSERT INTO permissions (code, description) VALUES
('attendance.import', 'Upload and import raw attendance punch files'),
('attendance.view.all', 'View attendance logs across all sections'),
('attendance.view.section', 'View attendance logs within assigned section'),
('attendance.correct', 'Submit attendance correction requests'),
('attendance.approve', 'Approve or reject attendance correction requests'),
('employee.create', 'Create new employee master records'),
('employee.update', 'Update existing employee records'),
('employee.view', 'View employee details'),
('report.generate', 'Generate official PDF and Excel reports'),
('report.export', 'Export raw data and aggregates'),
('section.manage', 'Create and modify organizational sections'),
('rule.manage', 'Configure attendance rules and shift policies'),
('audit.view', 'Inspect system audit trails')
ON CONFLICT (code) DO NOTHING;

-- Map ALL permissions to SUPER_ADMIN and ADMIN
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name IN ('SUPER_ADMIN', 'ADMIN')
ON CONFLICT DO NOTHING;

-- Map ATTENDANCE_ADMIN permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'ATTENDANCE_ADMIN'
AND p.code IN (
    'attendance.import', 'attendance.view.all', 'attendance.view.section', 
    'attendance.correct', 'employee.create', 'employee.update', 'employee.view', 
    'report.generate', 'report.export'
)
ON CONFLICT DO NOTHING;

-- Map BO permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'BO'
AND p.code IN (
    'attendance.view.section', 'attendance.correct', 'attendance.approve', 
    'employee.view', 'report.generate', 'report.export'
)
ON CONFLICT DO NOTHING;

-- Map AAO permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'AAO'
AND p.code IN ('attendance.view.section', 'employee.view', 'report.generate', 'report.export')
ON CONFLICT DO NOTHING;

-- Map REPORT_USER permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'REPORT_USER'
AND p.code IN ('attendance.view.all', 'attendance.view.section', 'employee.view', 'report.generate', 'report.export')
ON CONFLICT DO NOTHING;

-- Map VIEW_ONLY permissions (v1.1 Correction: Restricted to section scope)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.name = 'VIEW_ONLY'
AND p.code IN ('attendance.view.section', 'employee.view')
ON CONFLICT DO NOTHING;
