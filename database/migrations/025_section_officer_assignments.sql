-- Migration: 025_section_officer_assignments.sql
-- Enables linking Branch Officers (Sr. AO / AO / DAG) to multiple sections.

CREATE TABLE IF NOT EXISTS section_officer_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    role_title VARCHAR(64) NOT NULL DEFAULT 'BRANCH_OFFICER', -- 'BRANCH_OFFICER', 'SECTION_OFFICER', 'GROUP_OFFICER'
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_section_officer_assignment UNIQUE (section_id, employee_id, role_title)
);

CREATE INDEX IF NOT EXISTS idx_section_officer_section ON section_officer_assignments(section_id);
CREATE INDEX IF NOT EXISTS idx_section_officer_employee ON section_officer_assignments(employee_id);
