# AIMS v1.0 Standard Operating Procedure (SOP) & Operational Governance

**System**: Attendance Intelligence & Management System (AIMS)  
**Version**: `v1.0.0` (Production Baseline)  
**Target Organization**: Office of the Comptroller & Auditor General of India (CAG)  
**Date**: 2026-08-22  

---

## 1. Monthly Operational Attendance Cycle SOP

Every monthly attendance reporting cycle must strictly execute through the following 12-step sequence:

```text
1. Export Biometric File  ──>  Extract monthly CSV/XLSX export from Aadhaar biometric portal.
2. Sign In to AIMS       ──>  Log in to https://aims.internal with Attendance Admin credentials.
3. Upload Biometric File  ──>  Navigate to /import and upload the raw biometric matrix file.
4. Validation Review      ──>  Review automated validation summary (valid rows, unknown IDs, dups).
5. Resolve Master Data    ──>  If unknown device IDs exist, map them in /employees before committing.
6. Execute Batch Import   ──>  Commit validated records into the immutable append-only ledger.
7. Engine Calculation     ──>  Trigger attendance processing job for target date range.
8. Exception Audit        ──>  Review /exceptions for unclosed punches and grace period breaches.
9. Correction Approval    ──>  Process & approve /corrections with dual-signoff (Requester ≠ Approver).
10. Generate PDF Report   ──>  Generate Monthly Section Attendance Register PDF via /reports.
11. Archive Official PDF  ──>  Download and archive signed PDF in organizational record repository.
12. Database Backup       ──>  Verify automated nightly database backup executed cleanly at 02:00 AM.
```

---

## 2. Role-Based Governance & Training Matrix

| System Role | Key Capabilities | Training Requirement |
| :--- | :--- | :--- |
| **System Administrator** | User management, RBAC assignment, audit trail inspection, system settings | Security controls, audit log reviews, disaster recovery |
| **Attendance Administrator** | Biometric import execution, master data mapping, shift rule configuration | File validation, exception management, rule versioning |
| **BO / Sr. AO** | Section dashboard overview, staff attendance review, correction approval | Section isolation rules, approval workflows, report validation |
| **AAO** | Section attendance tracking, correction request submission, daily view | Correction submission, exception resolution |
| **View Only** | Read-only access to dashboard statistics and section reports | Report generation, export filtering |

---

## 3. Historical Attendance Rule Versioning Policy

- Attendance rules must **never** overwrite existing rules in-place.
- Any change to shift timings, grace periods, or half-day thresholds requires creating a new `AttendanceRule` with `effective_from` and `effective_to` dates.
- Historical attendance records (`attendance_daily`, `attendance_sessions`) permanently preserve the rule ID active on the target date.
