CREATE TABLE IF NOT EXISTS attendance_rules (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    name VARCHAR(64) NOT NULL,

    shift_start_time TIME NOT NULL,
    shift_end_time TIME NOT NULL,

    grace_period_minutes INTEGER NOT NULL DEFAULT 15
        CHECK (grace_period_minutes BETWEEN 0 AND 1440),

    half_day_min_duration_minutes INTEGER NOT NULL DEFAULT 240
        CHECK (half_day_min_duration_minutes >= 0),

    full_day_min_duration_minutes INTEGER NOT NULL DEFAULT 420
        CHECK (full_day_min_duration_minutes >= 0),

    early_exit_threshold_minutes INTEGER NOT NULL DEFAULT 15
        CHECK (early_exit_threshold_minutes BETWEEN 0 AND 1440),

    max_single_session_hours INTEGER NOT NULL DEFAULT 14
        CHECK (max_single_session_hours BETWEEN 1 AND 48),

    cross_midnight BOOLEAN NOT NULL DEFAULT FALSE,

    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_attendance_rules_dates
        CHECK (
            effective_to IS NULL
            OR effective_to >= effective_from
        ),

    CONSTRAINT ck_attendance_rules_duration
        CHECK (
            full_day_min_duration_minutes
            >= half_day_min_duration_minutes
        ),

    CONSTRAINT uq_attendance_rules_name
        UNIQUE (organization_id, name, effective_from)
);

CREATE INDEX IF NOT EXISTS idx_attendance_rules_org_effective
    ON attendance_rules(
        organization_id,
        effective_from,
        effective_to
    );

DROP TRIGGER IF EXISTS trg_attendance_rules_updated_at ON attendance_rules;
CREATE TRIGGER trg_attendance_rules_updated_at
BEFORE UPDATE ON attendance_rules
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
