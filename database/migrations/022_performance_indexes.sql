-- 022_performance_indexes.sql
-- Optimizes organization-level dashboard queries & reporting lookups

CREATE INDEX IF NOT EXISTS idx_daily_org_date
    ON attendance_daily(organization_id, attendance_date);

CREATE INDEX IF NOT EXISTS idx_daily_org_section_date
    ON attendance_daily(organization_id, section_id, attendance_date);

CREATE INDEX IF NOT EXISTS idx_raw_events_batch_emp
    ON attendance_raw_events(batch_id, employee_id);
