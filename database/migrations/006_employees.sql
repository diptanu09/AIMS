CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    employee_code VARCHAR(64) NOT NULL,

    attendance_device_user_id VARCHAR(64) NOT NULL,

    first_name VARCHAR(64) NOT NULL,
    middle_name VARCHAR(64),
    last_name VARCHAR(64),

    email VARCHAR(128),
    mobile VARCHAR(32),

    section_id UUID NOT NULL
        REFERENCES sections(id),

    designation_id UUID NOT NULL
        REFERENCES designations(id),

    attendance_rule_id UUID NOT NULL
        REFERENCES attendance_rules(id),

    joining_date DATE NOT NULL,
    leaving_date DATE,

    status employee_status NOT NULL DEFAULT 'ACTIVE',

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_employees_org_code
        UNIQUE (organization_id, employee_code),

    CONSTRAINT uq_employees_org_attendance_id
        UNIQUE (
            organization_id,
            attendance_device_user_id
        ),

    CONSTRAINT ck_employees_dates
        CHECK (
            leaving_date IS NULL
            OR leaving_date >= joining_date
        )
);

CREATE INDEX idx_employees_org_section
    ON employees(organization_id, section_id);

CREATE INDEX idx_employees_org_designation
    ON employees(organization_id, designation_id);

CREATE INDEX idx_employees_attendance_device
    ON employees(
        organization_id,
        attendance_device_user_id
    );

CREATE TRIGGER trg_employees_updated_at
BEFORE UPDATE ON employees
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
