CREATE TABLE IF NOT EXISTS attendance_corrections (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    attendance_daily_id UUID NOT NULL
        REFERENCES attendance_daily(id) ON DELETE CASCADE,

    requested_by UUID NOT NULL
        REFERENCES users(id),

    original_first_in TIMESTAMPTZ,
    original_last_out TIMESTAMPTZ,
    original_status attendance_status NOT NULL,

    corrected_first_in TIMESTAMPTZ,
    corrected_last_out TIMESTAMPTZ,
    corrected_status attendance_status NOT NULL,

    reason TEXT NOT NULL,

    status correction_status NOT NULL DEFAULT 'PENDING',

    approved_by UUID
        REFERENCES users(id),

    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_different_approver
        CHECK (approved_by IS NULL OR approved_by <> requested_by)
);

CREATE INDEX IF NOT EXISTS idx_corrections_daily_status
    ON attendance_corrections(attendance_daily_id, status);

DROP TRIGGER IF EXISTS trg_attendance_corrections_updated_at ON attendance_corrections;
CREATE TRIGGER trg_attendance_corrections_updated_at
BEFORE UPDATE ON attendance_corrections
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
