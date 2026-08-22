CREATE TABLE sections (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,

    parent_section_id UUID
        REFERENCES sections(id) ON DELETE SET NULL,

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_sections_org_code
        UNIQUE (organization_id, code)
);

CREATE INDEX idx_sections_org_parent
    ON sections(organization_id, parent_section_id);

CREATE TRIGGER trg_sections_updated_at
BEFORE UPDATE ON sections
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
