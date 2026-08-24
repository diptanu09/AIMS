CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID
        REFERENCES organizations(id) ON DELETE CASCADE,

    user_id UUID
        REFERENCES users(id) ON DELETE SET NULL,

    action VARCHAR(64) NOT NULL,
    entity_name VARCHAR(64) NOT NULL,
    entity_id UUID,

    old_value JSONB,
    new_value JSONB,

    client_ip VARCHAR(45),
    user_agent TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_created
    ON audit_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_org_action
    ON audit_logs(organization_id, action);
