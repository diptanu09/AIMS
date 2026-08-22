CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    key VARCHAR(64) NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    is_sensitive BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_system_settings_org_key
        UNIQUE (organization_id, key)
);

CREATE TRIGGER trg_system_settings_updated_at
BEFORE UPDATE ON system_settings
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
