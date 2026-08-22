-- 021_roles_and_least_privilege.sql
-- Enforces raw attendance event append-only protection & database role isolation

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'aims_owner') THEN
        CREATE ROLE aims_owner;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'aims_migrator') THEN
        CREATE ROLE aims_migrator;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'aims_app') THEN
        CREATE ROLE aims_app;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'aims_readonly') THEN
        CREATE ROLE aims_readonly;
    END IF;
END
$$;

-- Raw attendance append-only trigger enforcement
CREATE OR REPLACE FUNCTION prevent_raw_attendance_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'SECURITY ERROR: Raw attendance events are immutable append-only records. UPDATE or DELETE is strictly prohibited under CAG audit policy.'
        USING ERRCODE = 'AIMS1';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_raw_attendance ON attendance_raw_events;

CREATE TRIGGER trg_protect_raw_attendance
BEFORE UPDATE OR DELETE ON attendance_raw_events
FOR EACH ROW
EXECUTE FUNCTION prevent_raw_attendance_mutation();
