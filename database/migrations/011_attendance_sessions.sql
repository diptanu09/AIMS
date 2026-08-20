-- 011_attendance_sessions.sql
-- Constructed Attendance Session Pairs Table Definition

CREATE TABLE attendance_sessions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    attendance_daily_id UUID NOT NULL REFERENCES attendance_daily(id) ON DELETE CASCADE,
    in_timestamp TIMESTAMPTZ NOT NULL,
    out_timestamp TIMESTAMPTZ,
    duration_minutes INT NOT NULL DEFAULT 0,
    session_order INT NOT NULL DEFAULT 1,
    is_inferred BOOLEAN NOT NULL DEFAULT FALSE
);
