-- 009_raw_attendance.sql
-- Raw Attendance Punch Events Table Definition (Immutable Provenance)

CREATE TABLE attendance_raw_events (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES attendance_import_batches(id) ON DELETE CASCADE,
    source_row_number INT NOT NULL,
    attendance_device_user_id VARCHAR(64) NOT NULL,
    employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    punch_timestamp TIMESTAMPTZ NOT NULL,
    punch_type punch_type NOT NULL DEFAULT 'UNKNOWN',
    device_terminal_id VARCHAR(64),
    event_fingerprint CHAR(64) NOT NULL,
    raw_payload JSONB,
    raw_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, event_fingerprint)
);
