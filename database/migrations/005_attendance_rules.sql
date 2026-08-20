-- 005_attendance_rules.sql
-- Attendance Rules Table Definition

CREATE TABLE attendance_rules (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    shift_start_time TIME NOT NULL,
    shift_end_time TIME NOT NULL,
    grace_period_minutes INT NOT NULL DEFAULT 15,
    half_day_min_duration_minutes INT DEFAULT 240,
    full_day_min_duration_minutes INT DEFAULT 420,
    early_exit_threshold_minutes INT DEFAULT 15,
    max_single_session_hours INT DEFAULT 14,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
