CREATE TABLE IF NOT EXISTS attendance_daily (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    employee_id UUID NOT NULL
        REFERENCES employees(id) ON DELETE CASCADE,

    section_id UUID NOT NULL
        REFERENCES sections(id),

    attendance_date DATE NOT NULL,

    first_in TIMESTAMPTZ,
    last_out TIMESTAMPTZ,

    total_duty_minutes INTEGER NOT NULL DEFAULT 0,
    minutes_after_shift_start INTEGER NOT NULL DEFAULT 0,
    late_after_grace_minutes INTEGER NOT NULL DEFAULT 0,
    early_exit_minutes INTEGER NOT NULL DEFAULT 0,

    status attendance_status NOT NULL,

    is_corrected BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_daily_emp_date
        UNIQUE (employee_id, attendance_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_emp_date
    ON attendance_daily(employee_id, attendance_date);

CREATE INDEX IF NOT EXISTS idx_daily_section_date
    ON attendance_daily(section_id, attendance_date);

CREATE INDEX IF NOT EXISTS idx_daily_status_date
    ON attendance_daily(status, attendance_date);

DROP TRIGGER IF EXISTS trg_attendance_daily_updated_at ON attendance_daily;
CREATE TRIGGER trg_attendance_daily_updated_at
BEFORE UPDATE ON attendance_daily
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS attendance_sessions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    attendance_daily_id UUID NOT NULL
        REFERENCES attendance_daily(id) ON DELETE CASCADE,

    in_timestamp TIMESTAMPTZ NOT NULL,
    out_timestamp TIMESTAMPTZ,

    duration_minutes INTEGER NOT NULL DEFAULT 0,
    session_order INTEGER NOT NULL DEFAULT 1,

    is_inferred BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_sessions_daily
    ON attendance_sessions(attendance_daily_id, session_order);
