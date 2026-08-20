-- 0001_initial_schema.sql
-- AIMS PostgreSQL 18.4 Initial DDL Schema (v1.1)

-- Enums
CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED');
CREATE TYPE employee_status AS ENUM ('ACTIVE', 'PROBATION', 'SUSPENDED', 'RESIGNED', 'RETIRED');
CREATE TYPE import_batch_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'PARTIAL');
CREATE TYPE punch_type AS ENUM ('IN', 'OUT', 'UNKNOWN');
CREATE TYPE attendance_status AS ENUM (
    'PRESENT', 'LATE', 'ABSENT', 'HALF_DAY', 'EARLY_EXIT', 
    'LATE_AND_EARLY_EXIT', 'INCOMPLETE', 'HOLIDAY', 'WEEKLY_OFF', 
    'LEAVE', 'ON_DUTY', 'EXEMPTED', 'UNKNOWN'
);
CREATE TYPE correction_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');

-- Organizations
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    code VARCHAR(32) UNIQUE NOT NULL,
    name VARCHAR(128) NOT NULL,
    timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Kolkata',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Sections
CREATE TABLE sections (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    parent_section_id UUID REFERENCES sections(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, code)
);

-- Designations
CREATE TABLE designations (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    code VARCHAR(32) NOT NULL,
    title VARCHAR(128) NOT NULL,
    level INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, code)
);

-- Attendance Rules
CREATE TABLE attendance_rules (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    shift_start_time TIME NOT NULL,
    shift_end_time TIME NOT NULL,
    grace_period_minutes INT NOT NULL DEFAULT 15,
    half_day_min_duration_minutes INT DEFAULT 240,
    full_day_min_duration_minutes INT DEFAULT 420,
    early_exit_threshold_minutes INT DEFAULT 15,
    max_single_session_hours INT DEFAULT 14,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Employees
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_code VARCHAR(64) NOT NULL,
    attendance_device_user_id VARCHAR(64) NOT NULL,
    first_name VARCHAR(64) NOT NULL,
    last_name VARCHAR(64) NOT NULL,
    email VARCHAR(128),
    mobile VARCHAR(32),
    section_id UUID NOT NULL REFERENCES sections(id),
    designation_id UUID NOT NULL REFERENCES designations(id),
    attendance_rule_id UUID NOT NULL REFERENCES attendance_rules(id),
    joining_date DATE NOT NULL,
    leaving_date DATE,
    status employee_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, employee_code),
    UNIQUE(organization_id, attendance_device_user_id)
);

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    username VARCHAR(64) UNIQUE NOT NULL,
    email VARCHAR(128) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    status user_status NOT NULL DEFAULT 'ACTIVE',
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Roles & Permissions
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    name VARCHAR(64) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    code VARCHAR(64) UNIQUE NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE user_section_assignments (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    role_in_section VARCHAR(32) NOT NULL,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    PRIMARY KEY (user_id, section_id, effective_from)
);

-- Import Batches & Raw Events (v1.1 Immutability & Provenance)
CREATE TABLE attendance_import_batches (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_hash VARCHAR(64) NOT NULL,
    uploaded_by UUID NOT NULL REFERENCES users(id),
    total_records INT NOT NULL DEFAULT 0,
    valid_records INT NOT NULL DEFAULT 0,
    duplicate_records INT NOT NULL DEFAULT 0,
    unknown_employees INT NOT NULL DEFAULT 0,
    invalid_records INT NOT NULL DEFAULT 0,
    status import_batch_status NOT NULL DEFAULT 'PENDING',
    imported_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE attendance_raw_events (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES attendance_import_batches(id) ON DELETE CASCADE,
    source_row_number INT NOT NULL,
    attendance_device_user_id VARCHAR(64) NOT NULL,
    employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    punch_timestamp TIMESTAMPTZ NOT NULL,
    punch_type punch_type NOT NULL DEFAULT 'UNKNOWN',
    device_terminal_id VARCHAR(64),
    event_fingerprint CHAR(64) NOT NULL,
    raw_payload JSONB,
    raw_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, event_fingerprint)
);

-- Daily Attendance & Sessions
CREATE TABLE attendance_daily (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id),
    attendance_date DATE NOT NULL,
    first_in TIMESTAMPTZ,
    last_out TIMESTAMPTZ,
    total_duty_minutes INT NOT NULL DEFAULT 0,
    minutes_after_shift_start INT NOT NULL DEFAULT 0,
    late_after_grace_minutes INT NOT NULL DEFAULT 0,
    early_exit_minutes INT NOT NULL DEFAULT 0,
    status attendance_status NOT NULL,
    is_corrected BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (employee_id, attendance_date)
);

CREATE TABLE attendance_sessions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    attendance_daily_id UUID NOT NULL REFERENCES attendance_daily(id) ON DELETE CASCADE,
    in_timestamp TIMESTAMPTZ NOT NULL,
    out_timestamp TIMESTAMPTZ,
    duration_minutes INT NOT NULL DEFAULT 0,
    session_order INT NOT NULL DEFAULT 1,
    is_inferred BOOLEAN NOT NULL DEFAULT FALSE
);

-- Holidays, Weekly Offs, Leaves
CREATE TABLE holidays (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    holiday_date DATE NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_optional BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE(organization_id, holiday_date)
);

CREATE TABLE weekly_offs (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(organization_id, day_of_week)
);

CREATE TABLE leave_records (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type VARCHAR(32) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Attendance Corrections (v1.1 Separation-of-duties: requested_by != approved_by)
CREATE TABLE attendance_corrections (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    attendance_daily_id UUID NOT NULL REFERENCES attendance_daily(id) ON DELETE CASCADE,
    requested_by UUID NOT NULL REFERENCES users(id),
    original_first_in TIMESTAMPTZ,
    original_last_out TIMESTAMPTZ,
    original_status attendance_status NOT NULL,
    corrected_first_in TIMESTAMPTZ,
    corrected_last_out TIMESTAMPTZ,
    corrected_status attendance_status NOT NULL,
    reason TEXT NOT NULL,
    status correction_status NOT NULL DEFAULT 'PENDING',
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_different_approver CHECK (approved_by IS NULL OR approved_by <> requested_by)
);

-- Audit Logs
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(64) NOT NULL,
    entity_name VARCHAR(64) NOT NULL,
    entity_id UUID,
    old_value JSONB,
    new_value JSONB,
    client_ip VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Performance Indexes
CREATE INDEX idx_raw_events_emp_time ON attendance_raw_events(employee_id, punch_timestamp);
CREATE INDEX idx_raw_events_fingerprint ON attendance_raw_events(organization_id, event_fingerprint);
CREATE INDEX idx_daily_emp_date ON attendance_daily(employee_id, attendance_date);
CREATE INDEX idx_daily_section_date ON attendance_daily(section_id, attendance_date);
CREATE INDEX idx_daily_status_date ON attendance_daily(status, attendance_date);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);
