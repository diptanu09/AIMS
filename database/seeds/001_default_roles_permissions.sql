-- 001_default_roles_permissions.sql
-- Default Permissions & Roles Seed Data

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

-- Create default organization if not exists for seed mapping
INSERT INTO organizations (code, name, timezone)
VALUES ('DEFAULT', 'Default Organization', 'Asia/Kolkata')
ON CONFLICT (code) DO NOTHING;

-- Seed default roles for DEFAULT organization
INSERT INTO roles (organization_id, code, name, description, is_system)
SELECT
    o.id,
    role_code,
    role_name,
    role_description,
    TRUE
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
WHERE o.code = 'DEFAULT'
  AND r.name IN ('SUPER_ADMIN', 'ADMIN')
ON CONFLICT DO NOTHING;

-- Map ATTENDANCE_ADMIN permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'attendance.import', 'attendance.view.all', 'attendance.view.section',
    'attendance.correct', 'employee.create', 'employee.update', 'employee.view',
    'report.generate', 'report.export'
)
JOIN organizations o ON o.id = r.organization_id
WHERE o.code = 'DEFAULT' AND r.name = 'ATTENDANCE_ADMIN'
ON CONFLICT DO NOTHING;

-- Map BO permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'attendance.view.section', 'attendance.correct', 'attendance.approve',
    'employee.view', 'report.generate', 'report.export'
)
JOIN organizations o ON o.id = r.organization_id
WHERE o.code = 'DEFAULT' AND r.name = 'BO'
ON CONFLICT DO NOTHING;

-- Map AAO permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'attendance.view.section', 'employee.view', 'report.generate', 'report.export'
)
JOIN organizations o ON o.id = r.organization_id
WHERE o.code = 'DEFAULT' AND r.name = 'AAO'
ON CONFLICT DO NOTHING;

-- Map REPORT_USER permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'attendance.view.all', 'attendance.view.section', 'employee.view', 'report.generate', 'report.export'
)
JOIN organizations o ON o.id = r.organization_id
WHERE o.code = 'DEFAULT' AND r.name = 'REPORT_USER'
ON CONFLICT DO NOTHING;

-- Map VIEW_ONLY permissions (section-scoped view only)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.code IN (
    'attendance.view.section', 'employee.view'
)
JOIN organizations o ON o.id = r.organization_id
WHERE o.code = 'DEFAULT' AND r.name = 'VIEW_ONLY'
ON CONFLICT DO NOTHING;
