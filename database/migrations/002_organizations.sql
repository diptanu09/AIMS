CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Kolkata',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_organizations_code UNIQUE (code)
);

CREATE TRIGGER trg_organizations_updated_at
BEFORE UPDATE ON organizations
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
