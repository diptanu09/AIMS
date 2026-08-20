-- 006_employees.sql
-- Employees Master Table Definition

CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_code VARCHAR(64) NOT NULL,
    attendance_device_user_id VARCHAR(64) NOT NULL,
    first_name VARCHAR(64) NOT NULL,
    last_name VARCHAR(64) NOT NULL,
    email VARCHAR(128),
    mobile VARCHAR(32),
    section_id UUID NOT NULL REFERENCES sections(id),
    designation_id UUID NOT NULL REFERENCES designations(id),
    attendance_rule_id UUID NOT NULL REFERENCES attendance_rules(id),
    joining_date DATE NOT NULL,
    leaving_date DATE,
    status employee_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, employee_code),
    UNIQUE(organization_id, attendance_device_user_id)
);
