CREATE TABLE IF NOT EXISTS employee_section_assignments (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    employee_id UUID NOT NULL
        REFERENCES employees(id) ON DELETE CASCADE,

    section_id UUID NOT NULL
        REFERENCES sections(id) ON DELETE RESTRICT,

    effective_from DATE NOT NULL,
    effective_to DATE,

    reason TEXT,

    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_employee_section_assignment_dates
        CHECK (
            effective_to IS NULL
            OR effective_to >= effective_from
        )
);

CREATE INDEX IF NOT EXISTS idx_employee_section_assignments_employee
    ON employee_section_assignments(
        employee_id,
        effective_from
    );

CREATE INDEX IF NOT EXISTS idx_employee_section_assignments_section
    ON employee_section_assignments(
        section_id,
        effective_from
    );
