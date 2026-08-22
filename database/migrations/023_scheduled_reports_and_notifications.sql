-- 023_scheduled_reports_and_notifications.sql
-- Enables Step 18 automated scheduled reporting & proactive notification engine

CREATE TABLE scheduled_reports (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    cron_expression VARCHAR(64) NOT NULL DEFAULT '0 8 1 * *',
    report_type VARCHAR(64) NOT NULL DEFAULT 'MONTHLY_SECTION_ATTENDANCE',
    section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
    recipients JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_run_at TIMESTAMPTZ,
    next_run_at TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE in_app_notifications (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(256) NOT NULL,
    message TEXT NOT NULL,
    alert_type VARCHAR(64) NOT NULL DEFAULT 'INFO',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scheduled_reports_org ON scheduled_reports(organization_id, is_active);
CREATE INDEX idx_notifications_user_unread ON in_app_notifications(user_id, is_read, created_at DESC);
