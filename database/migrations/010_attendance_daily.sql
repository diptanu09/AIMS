-- 010_attendance_daily.sql
-- Calculated Daily Attendance Summary Table Definition

CREATE TABLE attendance_daily (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id),
    attendance_date DATE NOT NULL,
    first_in TIMESTAMPTZ,
    last_out TIMESTAMPTZ,
    total_duty_minutes INT NOT NULL DEFAULT 0,
    minutes_after_shift_start INT NOT NULL DEFAULT 0,
    late_after_grace_minutes INT NOT NULL DEFAULT 0,
    early_exit_minutes INT NOT NULL DEFAULT 0,
    status attendance_status NOT NULL,
    is_corrected BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (employee_id, attendance_date)
);
