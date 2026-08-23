CREATE SCHEMA IF NOT EXISTS "AIMS";
SET search_path TO "AIMS", public;

CREATE TABLE IF NOT EXISTS "AIMS"._sqlx_migrations (
    version BIGINT PRIMARY KEY,
    description TEXT NOT NULL,
    installed_on TIMESTAMPTZ NOT NULL DEFAULT now(),
    success BOOLEAN NOT NULL,
    checksum BYTEA NOT NULL,
    execution_time BIGINT NOT NULL
);

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'employee_status') THEN
        CREATE TYPE employee_status AS ENUM ('ACTIVE', 'PROBATION', 'SUSPENDED', 'RESIGNED', 'RETIRED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'import_batch_status') THEN
        CREATE TYPE import_batch_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'PARTIAL');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'punch_type') THEN
        CREATE TYPE punch_type AS ENUM ('IN', 'OUT', 'UNKNOWN');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'punch_source_mode') THEN
        CREATE TYPE punch_source_mode AS ENUM ('EXPLICIT_DIRECTION', 'ALTERNATING', 'DEVICE_STATE', 'INFERRED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attendance_status') THEN
        CREATE TYPE attendance_status AS ENUM ('PRESENT', 'LATE', 'ABSENT', 'HALF_DAY', 'EARLY_EXIT', 'LATE_AND_EARLY_EXIT', 'INCOMPLETE', 'HOLIDAY', 'WEEKLY_OFF', 'LEAVE', 'ON_DUTY', 'EXEMPTED', 'UNKNOWN');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'correction_status') THEN
        CREATE TYPE correction_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'leave_status') THEN
        CREATE TYPE leave_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'report_run_status') THEN
        CREATE TYPE report_run_status AS ENUM ('QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED');
    END IF;
END $$;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;
