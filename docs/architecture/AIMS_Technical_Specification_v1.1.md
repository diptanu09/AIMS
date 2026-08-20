# AIMS — Attendance Intelligence & Management System
## Technical Specification & Baseline Architecture v1.1

---

## v1.1 Change Summary
This revision is approved as the official implementation baseline. Key updates:
- Updated frontend baseline to Next.js 16.3 / React 19.2.
- Updated backend baseline to Axum 0.8.9.
- Aligned PostgreSQL baseline with PostgreSQL 18.4.
- Replaced `uuid-ossp`/`uuid_generate_v4()` with native PostgreSQL 18 `uuidv7()` for time-ordered primary key indexes.
- Enforced raw-event provenance with SHA-256 `event_fingerprint`, `source_row_number`, `raw_text`, and database-level immutability.
- Added explicit `PunchInterpretationMode` (`ExplicitDirection`, `AlternatingPunches`, `DeviceStateBased`, `SessionPairingHeuristic`).
- Reworked session pairing: valid IN→OUT session pairs are constructed first; `first_in` and `last_out` are derived summary fields.
- Separated `minutes_after_shift_start` from `late_after_grace`.
- Corrected RBAC matrix: `VIEW_ONLY` role no longer holds `attendance.view.all` (restricted to section scope).
- Enforced separation-of-duties on corrections (`requested_by != approved_by`).

---

## 1. Executive Overview & System Architecture

### 1.1 Architectural Principles
1. **Raw Data Immutability:** `attendance_raw_events` is append-only with database permission triggers preventing UPDATE/DELETE.
2. **Derived Processing:** Daily summaries (`attendance_daily`, `attendance_sessions`) are derived deterministically from raw events and configurable rules.
3. **Database-Driven Rules Engine:** Shift schedules, grace windows, late thresholds, half-day minimums, and weekly-off calendars live in PostgreSQL.
4. **Complete Auditability:** Every correction requires a audit log entry recording prior state, new state, authorizing officer, and rationale.
5. **Decoupled Architecture:** Axum 0.8.9 backend API + Next.js 16.3 frontend UI + PostgreSQL 18.4 database.

---

## 2. PostgreSQL 18.4 Database Schema (DDL v1.1)

```sql
-- 1. Organizations
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    code VARCHAR(32) UNIQUE NOT NULL,
    name VARCHAR(128) NOT NULL,
    timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Kolkata',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Sections
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

-- 3. Designations
CREATE TABLE designations (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    code VARCHAR(32) NOT NULL,
    title VARCHAR(128) NOT NULL,
    level INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, code)
);

-- 4. Attendance Rules
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

-- 5. Employees
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

-- 6. Attendance Raw Events (v1.1 Provenance & Immutability)
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
```

---

## 3. RBAC Matrix (v1.1 Corrected)

| Permission Code | SUPER_ADMIN | ADMIN | ATTENDANCE_ADMIN | BO | AAO | REPORT_USER | VIEW_ONLY |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `attendance.import` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `attendance.view.all` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ |
| `attendance.view.section` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `attendance.correct` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `attendance.approve` | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| `employee.create` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `employee.update` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `employee.view` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `report.generate` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| `report.export` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
