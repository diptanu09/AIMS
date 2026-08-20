-- 012_calendar_leave.sql
-- Calendar, Holidays, Weekly Offs, and Leave Governance Tables

CREATE TABLE holidays (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    holiday_date DATE NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_optional BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE(organization_id, holiday_date)
);

CREATE TABLE weekly_offs (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(organization_id, day_of_week)
);

CREATE TABLE leave_records (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type VARCHAR(32) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
