CREATE OR REPLACE FUNCTION prevent_raw_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Immutable ledger table: attendance_raw_events records cannot be updated or deleted.'
        USING ERRCODE = '23000';
END;
$$;

CREATE TABLE attendance_raw_events (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    batch_id UUID NOT NULL
        REFERENCES attendance_import_batches(id) ON DELETE CASCADE,

    source_row_number INTEGER NOT NULL,

    attendance_device_user_id VARCHAR(64) NOT NULL,

    employee_id UUID
        REFERENCES employees(id) ON DELETE SET NULL,

    punch_timestamp TIMESTAMPTZ NOT NULL,
    punch_type punch_type NOT NULL DEFAULT 'UNKNOWN',
    source_mode punch_source_mode NOT NULL DEFAULT 'EXPLICIT_DIRECTION',

    device_terminal_id VARCHAR(64),
    event_fingerprint CHAR(64) NOT NULL,

    raw_payload JSONB,
    raw_text TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_raw_events_org_fingerprint
        UNIQUE (organization_id, event_fingerprint)
);

CREATE INDEX idx_raw_events_emp_time
    ON attendance_raw_events(employee_id, punch_timestamp);

CREATE INDEX idx_raw_events_org_device
    ON attendance_raw_events(organization_id, attendance_device_user_id, punch_timestamp);

CREATE TRIGGER trg_raw_events_no_update
BEFORE UPDATE ON attendance_raw_events
FOR EACH ROW
EXECUTE FUNCTION prevent_raw_event_mutation();

CREATE TRIGGER trg_raw_events_no_delete
BEFORE DELETE ON attendance_raw_events
FOR EACH ROW
EXECUTE FUNCTION prevent_raw_event_mutation();
