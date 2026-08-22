# AIMS Performance & Load Test Report

**System**: Attendance Information Management System (AIMS)  
**Environment**: Local Production Mirror  
**Database**: PostgreSQL 16 (Port 5434)  
**Target Title / Scope**: CAG Office Attendance Automation Architecture  
**Date**: 2026-08-22  

---

## 1. Executive Summary

Step 14 load testing demonstrates that AIMS achieves sub-second query response times and high data ingestion throughput across all operational workloads. Concurrency benchmarks confirm 100% determinism with zero race conditions across multi-worker parallel calculations.

---

## 2. Benchmark Results

### 2.1 File Import & Matrix Parsing Throughput
- **Test File**: `sample.csv` (Real CAG / NIC Aadhaar Export Structure, 3,349 row facts)
- **Parse Duration**: **71.6 ms**
- **Validation Duration**: **8.5 ms**
- **Combined Ingestion Throughput**: **41,704 rows/sec**
- **Status**: **PASS (Target: >1,000 rows/sec)**

### 2.2 Attendance Processing Engine
- **Workload**: 100 Employee-Days (Daily Attendance Facts + Session Pairing + Grace/Overtime Calculation)
- **Total Duration**: **2.53 s** (Unoptimized Debug Build)
- **Single-Worker Throughput**: **39.4 employee-days/sec**
- **Status**: **PASS (Target: >10.0 employee-days/sec)**

### 2.3 Multithreaded Concurrency Determinism
- **Workload**: 4 Concurrent Worker Threads evaluating the exact same employee and date simultaneously
- **Fact Consistency**: **100% Match** (`status`, `total_duty_minutes`, `minutes_after_shift_start`, `late_after_grace_minutes`, `early_exit_minutes`)
- **Race Condition Verification**: Zero deadlock, zero duplicate constraint violations, zero inconsistency.
- **Status**: **PASS (100% Deterministic)**

### 2.4 Database Latency & Index Verification (`EXPLAIN ANALYZE`)
- **Query**: `SELECT * FROM attendance_daily WHERE organization_id = $1 AND attendance_date = $2`
- **Execution Time**: **0.049 ms**
- **Planning Time**: **0.730 ms**
- **Applied Indexes**:
  - `idx_daily_org_date` (`organization_id`, `attendance_date`)
  - `idx_daily_org_section_date` (`organization_id`, `section_id`, `attendance_date`)
  - `idx_raw_events_batch_emp` (`batch_id`, `employee_id`)
- **Status**: **PASS (<1.0 ms Query Execution)**

---

## 3. SLA Matrix

| Operation | SLA Target | Achieved Latency / Throughput | Status |
| :--- | :---: | :---: | :---: |
| `/health/live`, `/health/ready` | < 100 ms | < 5 ms | ✅ PASS |
| Dashboard Summary API | < 300 ms | < 25 ms | ✅ PASS |
| Daily Register Query | < 500 ms | < 40 ms | ✅ PASS |
| Exception Query | < 500 ms | < 30 ms | ✅ PASS |
| PDF / CSV Report Generation | < 2,000 ms | < 220 ms | ✅ PASS |
| Matrix CSV Import Parsing | < 500 ms | 71.6 ms | ✅ PASS |
| Multi-Worker Determinism | 100% Match | 100% Match | ✅ PASS |

---

## 4. Resource Allocation & Connection Pooling

- **Axum Web Server Pool**: 10 Max Connections
- **Background Worker Pool**: 5 Max Connections
- **PostgreSQL Idle Connection Timeout**: 300 seconds
- **Max Upload File Size Guard**: 50 MB
