# AIMS

Attendance Intelligence & Management System

AIMS converts raw biometric / attendance-machine CSV and Excel exports into:

- Structured attendance records
- Late / absence / incomplete-punch detection
- Duty-hour calculation
- Section-wise attendance intelligence
- Employee attendance history
- Auditable corrections
- Official PDF and Excel reports

## Architecture

- Frontend: Next.js + React + TypeScript
- Backend: Rust + Axum
- Database: PostgreSQL
- Data Processing: Rust + optional Python/Polars
- Deployment: Organization LAN

## Repository

- `apps/web` — Web application
- `apps/api` — REST API
- `apps/worker` — Background processing
- `crates/*` — Shared Rust domain modules
- `database` — Migrations, seeds, fixtures
- `docs` — Technical documentation
