CREATE TABLE report_definitions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    code VARCHAR(64) NOT NULL,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    category VARCHAR(64) NOT NULL DEFAULT 'ATTENDANCE',

    active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_report_definitions_org_code
        UNIQUE (organization_id, code)
);

CREATE TRIGGER trg_report_definitions_updated_at
BEFORE UPDATE ON report_definitions
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE report_runs (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    report_definition_id UUID NOT NULL
        REFERENCES report_definitions(id) ON DELETE CASCADE,

    generated_by UUID NOT NULL
        REFERENCES users(id),

    parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_format VARCHAR(16) NOT NULL DEFAULT 'PDF',

    status report_run_status NOT NULL DEFAULT 'QUEUED',
    file_path VARCHAR(512),
    error_message TEXT,

    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_report_runs_org_status
    ON report_runs(organization_id, status);
