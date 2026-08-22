# AIMS Change Control & Data Quality Policy

**Document Reference**: AIMS-POL-002  
**Effective Date**: 2026-09-01  
**Classification**: Official Internal Policy  

---

## 1. Change Control Workflow

Direct SQL updates or manual database interventions in production are strictly forbidden. All structural, master-data, and configuration changes must adhere to:

```text
Change Request Submitted  ──>  QA Testing & Validation  ──>  Security & BO Approval  ──>  Migration & Audit Log
```

1. **Schema Changes**: Managed exclusively via numbered SQL migrations (`database/migrations/xxx_*.sql`).
2. **Shift Rule Edits**: Managed through historical rule versioning in `/admin/rules`.
3. **Employee Section Transfers**: Recorded with effective dates and remarks in `/employees`.

---

## 2. Continuous Data-Quality Audit Standard

The AIMS worker and administrative dashboard automatically flag data quality anomalies every 24 hours:

- **Unmapped Device User IDs**: Biometric punches with device IDs not linked to an active employee.
- **Incomplete Punch Sessions**: Punches lacking matching OUT times beyond the 12-hour session window.
- **Inactive Employee Events**: Biometric events received for deactivated or retired personnel.
- **Unassigned Sections**: Employees without active section or designation assignments.
