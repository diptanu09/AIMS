-- 015_indexes.sql
-- Performance SLA & Provenance Query Indexes

CREATE INDEX idx_raw_events_emp_time ON attendance_raw_events(employee_id, punch_timestamp);
CREATE INDEX idx_raw_events_fingerprint ON attendance_raw_events(organization_id, event_fingerprint);
CREATE INDEX idx_daily_emp_date ON attendance_daily(employee_id, attendance_date);
CREATE INDEX idx_daily_section_date ON attendance_daily(section_id, attendance_date);
CREATE INDEX idx_daily_status_date ON attendance_daily(status, attendance_date);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);
