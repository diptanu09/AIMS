CREATE TABLE attendance_processing_jobs (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    requested_by UUID NOT NULL
        REFERENCES users(id),

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    employee_id UUID
        REFERENCES employees(id) ON DELETE CASCADE,

    section_id UUID
        REFERENCES sections(id) ON DELETE CASCADE,

    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',

    total_days INTEGER NOT NULL DEFAULT 0,
    processed_days INTEGER NOT NULL DEFAULT 0,
    failed_days INTEGER NOT NULL DEFAULT 0,

    error_message TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_processing_jobs_org_status
    ON attendance_processing_jobs(organization_id, status);
