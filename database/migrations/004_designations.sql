CREATE TABLE IF NOT EXISTS designations (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    code VARCHAR(32) NOT NULL,
    title VARCHAR(128) NOT NULL,

    level INTEGER NOT NULL DEFAULT 1
        CHECK (level >= 1),

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_designations_org_code
        UNIQUE (organization_id, code)
);

CREATE INDEX IF NOT EXISTS idx_designations_org_level
    ON designations(organization_id, level);

DROP TRIGGER IF EXISTS trg_designations_updated_at ON designations;
CREATE TRIGGER trg_designations_updated_at
BEFORE UPDATE ON designations
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
