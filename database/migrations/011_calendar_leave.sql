CREATE TABLE holidays (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    holiday_date DATE NOT NULL,
    name VARCHAR(128) NOT NULL,
    description TEXT,

    is_optional BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_holidays_org_date
        UNIQUE (organization_id, holiday_date)
);

CREATE TABLE weekly_offs (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    day_of_week INTEGER NOT NULL
        CHECK (day_of_week BETWEEN 0 AND 6),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_weekly_offs_org_day
        UNIQUE (organization_id, day_of_week)
);

CREATE TABLE leave_records (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    employee_id UUID NOT NULL
        REFERENCES employees(id) ON DELETE CASCADE,

    leave_type VARCHAR(32) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    status leave_status NOT NULL DEFAULT 'PENDING',
    reason TEXT,

    requested_by UUID NOT NULL
        REFERENCES users(id),

    approved_by UUID
        REFERENCES users(id),

    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_leave_dates
        CHECK (end_date >= start_date)
);

CREATE INDEX idx_leave_records_emp_dates
    ON leave_records(employee_id, start_date, end_date);

CREATE TRIGGER trg_leave_records_updated_at
BEFORE UPDATE ON leave_records
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
