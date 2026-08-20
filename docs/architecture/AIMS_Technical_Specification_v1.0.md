# AIMS — Attendance Intelligence & Management System
## Technical Specification & Baseline Architecture v1.0

---

## 1. Executive Overview & System Architecture

AIMS (Attendance Intelligence & Management System) is an enterprise-grade attendance processing, employee tracking, exception management, and organizational analytics engine designed to convert raw biometric/machine logs (CSV/Excel) into structured, auditable attendance records and official reports.

### 1.1 Architectural Principles
1. **Raw Data Immutability:** `attendance_raw_events` is append-only. Raw imports are preserved verbatim in their original form.
2. **Derived Processing:** Calculated daily summaries (`attendance_daily`, `attendance_sessions`) are isolated from raw events and can be deterministically re-calculated at any time.
3. **Database-Driven Rules Engine:** Shift timings, grace periods, late thresholds, half-day boundaries, and weekly offs are fully configurable in database tables. No hard-coded logic.
4. **Complete Auditability:** Every manual edit or attendance correction requires an audit log record with prior value, new value, authorizing officer, and rationale.
5. **Decoupled Architecture:** Strict separation between backend business logic (Rust Axum 0.8), storage (PostgreSQL 18), and UI presentation (Next.js 15 App Router).

### 1.2 System Topology
```
┌─────────────────────────────────────────────────────────┐
│                      USER BROWSER                       │
│             Next.js 15 + React 19 + TypeScript          │
└────────────────────────────┬────────────────────────────┘
                             │ HTTPS / REST API
┌────────────────────────────▼────────────────────────────┐
│                    RUST AXUM 0.8 API                    │
│ ┌──────────────┬──────────────┬──────────────┬────────┐ │
│ │  Auth / RBAC │  Import Eng. │ Attend. Eng. │ Report │ │
│ └──────────────┴──────────────┴──────────────┴────────┘ │
└────────────────────────────┬────────────────────────────┘
                             │ SQLx / Tokio Async Pool
┌────────────────────────────▼────────────────────────────┐
│                      POSTGRESQL 18                      │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Raw Events | Daily Summary | Rules | Audit Logs     │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Master Directory & Monorepo Structure

```
aims/
├── Cargo.toml                       # Workspace manifest
├── README.md
├── LICENSE
├── docker/
│   ├── Dockerfile.api
│   ├── Dockerfile.web
│   └── docker-compose.yml           # PostgreSQL 18 + Axum API + Next.js
├── docs/
│   └── architecture/
│       └── AIMS_Technical_Specification_v1.0.md
├── database/
│   ├── migrations/
│   │   ├── 0001_initial_schema.sql
│   │   ├── 0002_attendance_rules.sql
│   │   └── 0003_audit_triggers.sql
│   ├── seeds/
│   │   └── 001_default_roles_permissions.sql
│   └── fixtures/
│       └── sample_attendance_august_2026.csv
├── apps/
│   ├── web/                         # Next.js 15 App Router application
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   ├── next.config.ts
│   │   └── src/
│   │       ├── app/
│   │       │   ├── (auth)/
│   │       │   │   └── login/page.tsx
│   │       │   ├── (dashboard)/
│   │       │   │   ├── page.tsx                    # Main Overview Dashboard
│   │       │   │   ├── employees/page.tsx          # Employee Master
│   │       │   │   ├── sections/page.tsx           # Section Intelligence & Hierarchy
│   │       │   │   ├── import/page.tsx             # File Import & Staging Preview
│   │       │   │   ├── exceptions/page.tsx         # Exception Center (Late/Absent/Incomplete)
│   │       │   │   ├── corrections/page.tsx        # Attendance Correction Workflow
│   │       │   │   ├── reports/page.tsx            # Report Engine & Downloads
│   │       │   │   └── administration/
│   │       │   │       ├── users/page.tsx
│   │       │   │       ├── rules/page.tsx
│   │       │   │       └── audit/page.tsx
│   │       │   └── layout.tsx
│   │       ├── components/
│   │       │   ├── ui/                         # Design system primitive components
│   │       │   │   ├── Button.tsx
│   │       │   │   ├── Table.tsx
│   │       │   │   ├── Badge.tsx
│   │       │   │   ├── Card.tsx
│   │       │   │   ├── Modal.tsx
│   │       │   │   └── Drawer.tsx
│   │       │   ├── dashboard/
│   │       │   ├── import/
│   │       │   └── reports/
│   │       ├── lib/
│   │       │   ├── api-client.ts
│   │       │   └── auth.ts
│   │       └── styles/
│   │           └── globals.css
│   ├── api/                         # Axum 0.8 HTTP API Server
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── main.rs
│   │       ├── state.rs
│   │       ├── middleware/
│   │       │   ├── auth.rs
│   │       │   ├── rbac.rs
│   │       │   └── logger.rs
│   │       └── routes/
│   │           ├── auth.rs
│   │           ├── employees.rs
│   │           ├── sections.rs
│   │           ├── import.rs
│   │           ├── attendance.rs
│   │           ├── exceptions.rs
│   │           ├── corrections.rs
│   │           └── reports.rs
│   └── worker/                      # Background task processing (Async Tokio runner)
│       ├── Cargo.toml
│       └── src/
│           └── main.rs
├── crates/                          # Shared Rust domain logic
│   ├── domain/                      # Domain models & entities
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── database/                    # SQLx repositories & pool abstractions
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── auth/                        # JWT, password hashing (argon2), permission evaluation
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── import_engine/               # CSV/Excel parsing, validation, auto-mapping
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── attendance_engine/           # Core attendance calculation state machine
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── reporting/                   # PDF (print-pdf / typst) & Excel (calamine / rust_xlsxwriter) generators
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   └── common/                      # Error types, logging utilities, date/time helpers
│       ├── Cargo.toml
│       └── src/lib.rs
└── python/                          # Optional high-throughput analytics (Polars)
    ├── pyproject.toml
    └── analytics/
        └── pattern_analysis.py
```

---

## 3. PostgreSQL 18 Database Schema (DDL)

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enum Types
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

-- 1. Organizations
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(32) UNIQUE NOT NULL,
    name VARCHAR(128) NOT NULL,
    timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Kolkata',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Sections (Departmental / Hierarchy Unit)
CREATE TABLE sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    code VARCHAR(32) NOT NULL,
    title VARCHAR(128) NOT NULL,
    level INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, code)
);

-- 4. Attendance Rules (Configurable Policy)
CREATE TABLE attendance_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    shift_start_time TIME NOT NULL,                  -- e.g. 09:30:00
    shift_end_time TIME NOT NULL,                    -- e.g. 17:30:00
    grace_period_minutes INT NOT NULL DEFAULT 15,    -- Late after 09:45:00
    half_day_min_duration_minutes INT DEFAULT 240,   -- Min 4h for half day
    full_day_min_duration_minutes INT DEFAULT 420,   -- Min 7h for full day
    early_exit_threshold_minutes INT DEFAULT 15,     -- Exit before 17:15:00 is early exit
    max_single_session_hours INT DEFAULT 14,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. Employees
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_code VARCHAR(64) NOT NULL,              -- HR Employee ID
    attendance_device_id VARCHAR(64) NOT NULL,       -- ID recorded on machine/Aadhaar
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
    UNIQUE(organization_id, attendance_device_id)
);

-- 6. Users (System Accounts)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    username VARCHAR(64) UNIQUE NOT NULL,
    email VARCHAR(128) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,             -- Argon2id
    status user_status NOT NULL DEFAULT 'ACTIVE',
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 7. Roles & Permissions (RBAC)
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(64) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(64) UNIQUE NOT NULL,                -- e.g. 'attendance.import'
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

-- Section Assignment for Section Officers (BO / AAO scope limits)
CREATE TABLE user_section_assignments (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    role_in_section VARCHAR(32) NOT NULL,            -- 'BO', 'AAO', 'OFFICER'
    PRIMARY KEY (user_id, section_id)
);

-- 8. Attendance Imports & Raw Data Staging
CREATE TABLE attendance_import_batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_hash VARCHAR(64) NOT NULL,                  -- SHA-256 for duplicate detection
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
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_id UUID NOT NULL REFERENCES attendance_import_batches(id) ON DELETE CASCADE,
    attendance_device_id VARCHAR(64) NOT NULL,
    employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    punch_timestamp TIMESTAMPTZ NOT NULL,
    punch_type punch_type NOT NULL DEFAULT 'UNKNOWN',
    device_terminal_id VARCHAR(64),
    raw_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(attendance_device_id, punch_timestamp)
);

-- 9. Attendance Calculation Output
CREATE TABLE attendance_daily (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id),
    attendance_date DATE NOT NULL,
    first_in TIMESTAMPTZ,
    last_out TIMESTAMPTZ,
    total_duty_minutes INT NOT NULL DEFAULT 0,
    late_minutes INT NOT NULL DEFAULT 0,
    early_exit_minutes INT NOT NULL DEFAULT 0,
    status attendance_status NOT NULL,
    is_corrected BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (employee_id, attendance_date)
);

CREATE TABLE attendance_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendance_daily_id UUID NOT NULL REFERENCES attendance_daily(id) ON DELETE CASCADE,
    in_timestamp TIMESTAMPTZ NOT NULL,
    out_timestamp TIMESTAMPTZ,
    duration_minutes INT NOT NULL DEFAULT 0,
    session_order INT NOT NULL DEFAULT 1
);

-- 10. Calendar, Holidays, Weekly Offs, Leaves
CREATE TABLE holidays (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    holiday_date DATE NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_optional BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE(organization_id, holiday_date)
);

CREATE TABLE weekly_offs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(organization_id, day_of_week)
);

CREATE TABLE leave_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type VARCHAR(32) NOT NULL,                 -- 'CASUAL', 'MEDICAL', 'EARNED', 'SPECIAL'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    approved_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 11. Attendance Corrections & Approval Workflow
CREATE TABLE attendance_corrections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 12. Audit Logs & System Governance
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(64) NOT NULL,                     -- e.g. 'ATTENDANCE_CORRECTION'
    entity_name VARCHAR(64) NOT NULL,
    entity_id UUID,
    old_value JSONB,
    new_value JSONB,
    client_ip VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Optimized Performance Indexes
CREATE INDEX idx_raw_events_emp_time ON attendance_raw_events(employee_id, punch_timestamp);
CREATE INDEX idx_daily_emp_date ON attendance_daily(employee_id, attendance_date);
CREATE INDEX idx_daily_section_date ON attendance_daily(section_id, attendance_date);
CREATE INDEX idx_daily_status_date ON attendance_daily(status, attendance_date);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);
```

---

## 4. Attendance Calculation State Machine & Algorithm

```
                  ┌──────────────────────────────┐
                  │      Select Employee Day     │
                  └──────────────┬───────────────┘
                                 │
                  ┌──────────────▼───────────────┐
                  │ 1. Check Holiday / Leave /  │
                  │    Weekly Off Precedence    │
                  └──────────────┬───────────────┘
                                 │
           ┌─────────────────────┴─────────────────────┐
           │ Override Match?                           │
     YES ┌─┴─┐                                       NO│
         │   │                                         │
┌────────▼───▼────────────┐              ┌─────────────▼─────────────┐
│ Assign Priority Status  │              │ 2. Fetch Raw Punches      │
│ (HOLIDAY/LEAVE/WEEKLY)  │              │    for Date Range         │
└─────────────────────────┘              └─────────────┬─────────────┘
                                                       │
                                         ┌─────────────▼─────────────┐
                                         │ 3. Sort Chronologically   │
                                         └─────────────┬─────────────┘
                                                       │
                                         ┌─────────────▼─────────────┐
                                         │ 4. Build Session Pairs    │
                                         │    First IN / Last OUT    │
                                         └─────────────┬─────────────┘
                                                       │
                                         ┌─────────────▼─────────────┐
                                         │ 5. Calculate Duty, Late & │
                                         │    Early Exit Duration    │
                                         └─────────────┬─────────────┘
                                                       │
                                         ┌─────────────▼─────────────┐
                                         │ 6. Evaluate Status Matrix │
                                         │ PRESENT / LATE / ABSENT   │
                                         └───────────────────────────┘
```

### 4.1 Detailed 12-Step Processing Algorithm

1. **Schedule Identification:** Fetch employee's assigned `attendance_rules` (Shift Start `T_start`, Shift End `T_end`, Grace `G_mins`, Full Day Min `FD_mins`, Half Day Min `HD_mins`).
2. **Override Evaluation:** 
   - If `date` is in `holidays` -> Status = `HOLIDAY`.
   - Else if `date` is in `leave_records` -> Status = `LEAVE`.
   - Else if `day_of_week` is in `weekly_offs` -> Status = `WEEKLY_OFF`.
3. **Raw Event Loading:** Fetch all records from `attendance_raw_events` for `attendance_device_id` between `T_start - 03:00:00` and `T_end + 04:00:00`.
4. **Chronological Sorting & Deduplication:** Sort punches by `punch_timestamp`. Ignore duplicate punches within a 60-second window.
5. **Session Pairing:**
   - First recorded punch = `First IN`.
   - Last recorded punch = `Last OUT`.
   - If total punches == 1 -> Status = `INCOMPLETE` (Missing OUT punch).
6. **Total Duty Calculation:** $\text{Duty Minutes} = \sum (\text{OUT}_i - \text{IN}_i)$.
7. **Late Calculation:** 
   - If $\text{First IN} > (\text{T\_start} + \text{Grace Period})$, then $\text{Late Minutes} = \text{First IN} - \text{T\_start}$.
8. **Early Exit Calculation:**
   - If $\text{Last OUT} < (\text{T\_end} - \text{Early Exit Threshold})$, then $\text{Early Exit Minutes} = \text{T\_end} - \text{Last OUT}$.
9. **Status Precedence Matrix:**
   - If $\text{Duty Minutes} == 0 \implies \text{ABSENT}$.
   - Else if $\text{Duty Minutes} < \text{HD\_mins} \implies \text{ABSENT}$ (or `HALF_DAY` based on rule).
   - Else if $\text{Duty Minutes} < \text{FD\_mins} \implies \text{HALF_DAY}$.
   - Else if $\text{Late} > 0$ and $\text{Early Exit} > 0 \implies \text{LATE\_AND\_EARLY\_EXIT}$.
   - Else if $\text{Late} > 0 \implies \text{LATE}$.
   - Else if $\text{Early Exit} > 0 \implies \text{EARLY\_EXIT}$.
   - Else $\implies \text{PRESENT}$.
10. **Persistence:** Write to `attendance_daily` and `attendance_sessions` inside a single database transaction.

---

## 5. RBAC Permission Matrix

| Permission Code | SUPER_ADMIN | ADMIN | ATTENDANCE_ADMIN | BO | AAO | REPORT_USER | VIEW_ONLY |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `attendance.import` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `attendance.view.all` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
| `attendance.view.section` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `attendance.correct` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `attendance.approve` | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| `employee.create` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `employee.update` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `employee.view` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `report.generate` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| `report.export` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| `section.manage` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `rule.manage` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `audit.view` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 6. Rust Axum 0.8 REST API Architecture

### 6.1 Core API Contracts

```
POST /api/v1/auth/login
Content-Type: application/json
Payload: { "username": "admin", "password": "..." }
Response: 200 OK { "token": "jwt...", "user": { "id": "...", "roles": ["ADMIN"] } }

POST /api/v1/attendance/import
Content-Type: multipart/form-data
Payload: file (CSV/Excel)
Response: 200 OK { 
  "batch_id": "...", 
  "total": 2846, 
  "valid": 2807, 
  "duplicates": 18, 
  "unknown_employees": 12, 
  "invalid": 9 
}

POST /api/v1/attendance/process
Content-Type: application/json
Payload: { "start_date": "2026-08-01", "end_date": "2026-08-20", "section_id": null }
Response: 200 OK { "processed_days": 20, "employees_affected": 286 }

GET /api/v1/dashboard/summary?date=2026-08-20
Response: 200 OK {
  "date": "2026-08-20",
  "total_employees": 286,
  "present": 251,
  "late": 19,
  "absent": 16,
  "incomplete": 7,
  "attendance_rate": 87.76
}

GET /api/v1/reports/generate?type=MONTHLY_SECTION&month=2026-08&format=pdf
Response: 200 OK (Content-Type: application/pdf)
```

---

## 7. Next.js 15 UI Design System & Component Guidelines

### 7.1 Visual Palette & Color Semantics
- **Backgrounds:** `#0B0F17` (Dark Base), `#151D2A` (Surface Card), `#1E293B` (Border / Component Base).
- **Primary / Accent:** Indigo `#6366F1`, Cyan `#06B6D4`.
- **Status Semantics:**
  - `PRESENT` / `Healthy`: Emerald `#10B981`
  - `LATE` / `Warning`: Amber `#F59E0B`
  - `ABSENT` / `Critical`: Rose `#EF4444`
  - `INCOMPLETE` / `Info`: Sky `#0284C7`
  - `HOLIDAY` / `Neutral`: Purple `#8B5CF6`

### 7.2 Typography & Components
- **Font Stack:** Inter / JetBrains Mono (for tabular code / numbers).
- **Core Primitives:** `Card`, `StatKpi`, `DataTable`, `StatusBadge`, `ModalDrawer`, `FilterBar`.

---

## 8. PDF / Excel Report Engine Specification

### 8.1 PDF Layout Standard
- **Page Format:** A4 Landscape (for detailed tabular reports) / Portrait (for executive summaries).
- **Security Metadata Header:** Document ID, Timestamp, Generating User, Confidentiality Marker, Digital Audit Hash.
- **Section Structure:**
  1. Organizational Header (Logo, Office Name, Report Title).
  2. Filter Criteria & Summary Stats Box.
  3. Formatted Data Table (Employee Code, Name, Designation, IN/OUT, Duty Hours, Status).
  4. Officer Sign-off Block (Prepared by, Checked by - BO/AAO).

---

## 9. Verification & Acceptance Criteria

1. **Deterministic Processing Test:** Processing 10,000 raw punches produces exact match against golden test fixtures.
2. **Audit Verification:** Modifying an attendance record via `/api/v1/attendance/correct` writes an unalterable row to `audit_logs`.
3. **Role Boundary Enforcement:** A Section Officer (BO) attempting to query another section's raw data receives `HTTP 403 Forbidden`.
4. **Performance SLA:** Dashboard KPI aggregation queries execute under 50ms on a 500,000 row dataset.
