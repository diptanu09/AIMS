CREATE TYPE user_status AS ENUM (
    'ACTIVE',
    'INACTIVE',
    'SUSPENDED'
);

CREATE TYPE employee_status AS ENUM (
    'ACTIVE',
    'PROBATION',
    'SUSPENDED',
    'RESIGNED',
    'RETIRED'
);

CREATE TYPE import_batch_status AS ENUM (
    'PENDING',
    'PROCESSING',
    'COMPLETED',
    'FAILED',
    'PARTIAL'
);

CREATE TYPE punch_type AS ENUM (
    'IN',
    'OUT',
    'UNKNOWN'
);

CREATE TYPE punch_source_mode AS ENUM (
    'EXPLICIT_DIRECTION',
    'ALTERNATING',
    'DEVICE_STATE',
    'INFERRED'
);

CREATE TYPE attendance_status AS ENUM (
    'PRESENT',
    'LATE',
    'ABSENT',
    'HALF_DAY',
    'EARLY_EXIT',
    'LATE_AND_EARLY_EXIT',
    'INCOMPLETE',
    'HOLIDAY',
    'WEEKLY_OFF',
    'LEAVE',
    'ON_DUTY',
    'EXEMPTED',
    'UNKNOWN'
);

CREATE TYPE correction_status AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED'
);

CREATE TYPE leave_status AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED'
);

CREATE TYPE report_run_status AS ENUM (
    'QUEUED',
    'PROCESSING',
    'COMPLETED',
    'FAILED'
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;
