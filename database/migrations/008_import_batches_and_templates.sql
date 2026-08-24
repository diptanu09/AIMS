CREATE TABLE IF NOT EXISTS import_templates (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    name VARCHAR(64) NOT NULL,
    description TEXT,

    employee_code_column VARCHAR(64) NOT NULL,
    punch_time_column VARCHAR(64) NOT NULL,
    punch_type_column VARCHAR(64),
    device_id_column VARCHAR(64),

    date_format VARCHAR(32) NOT NULL DEFAULT 'YYYY-MM-DD HH24:MI:SS',

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_import_templates_org_name
        UNIQUE (organization_id, name)
);

DROP TRIGGER IF EXISTS trg_import_templates_updated_at ON import_templates;
CREATE TRIGGER trg_import_templates_updated_at
BEFORE UPDATE ON import_templates
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS attendance_import_batches (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    template_id UUID
        REFERENCES import_templates(id) ON DELETE SET NULL,

    file_name VARCHAR(255) NOT NULL,
    file_hash VARCHAR(64) NOT NULL,

    uploaded_by UUID NOT NULL
        REFERENCES users(id),

    total_records INTEGER NOT NULL DEFAULT 0,
    valid_records INTEGER NOT NULL DEFAULT 0,
    duplicate_records INTEGER NOT NULL DEFAULT 0,
    unknown_employees INTEGER NOT NULL DEFAULT 0,
    invalid_records INTEGER NOT NULL DEFAULT 0,

    status import_batch_status NOT NULL DEFAULT 'PENDING',
    error_summary JSONB,

    imported_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_import_batches_org_status
    ON attendance_import_batches(organization_id, status);
