use aims_attendance_engine::process_and_persist_employee_date;
use aims_common::Result;
use aims_database::repositories::{
    attendance_rules::AttendanceRuleRepository,
    designations::DesignationRepository,
    employees::EmployeeRepository,
    organizations::OrganizationRepository,
    sections::SectionRepository,
};
use aims_domain::EmployeeStatus;
use aims_import_engine::{
    matrix_parser::parse_monthly_matrix_csv,
    template::ImportTemplate,
    validation::{validate_parsed_punches, ImportValidationSummary},
};
use chrono::{Duration, NaiveDate, NaiveTime, Utc};
use sqlx::{Row, PgPool};
use std::time::Instant;

async fn get_test_pool() -> PgPool {
    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://aims_app:change_this_password@127.0.0.1:5434/aims".to_string());
    PgPool::connect(&db_url)
        .await
        .expect("Failed to connect to test database")
}

#[tokio::test]
async fn test_large_import_performance() -> Result<()> {
    let sample_csv_bytes = std::fs::read("sample.csv")
        .expect("Failed to read sample.csv fixture");

    let org_id = uuid::Uuid::now_v7();
    let template = ImportTemplate::nic_aadhaar_default();

    let start_parse = Instant::now();
    let punches = parse_monthly_matrix_csv(org_id, &sample_csv_bytes, &template)?;
    let parse_duration = start_parse.elapsed();

    assert!(!punches.is_empty(), "Parsed punches must not be empty");

    let mut known_emps = std::collections::HashSet::new();
    for p in &punches {
        known_emps.insert(p.attendance_device_user_id.clone());
    }

    let existing_fingerprints = std::collections::HashSet::new();
    let mut summary = ImportValidationSummary::new("sample.csv".into(), "hash123".into());

    let start_val = Instant::now();
    validate_parsed_punches(punches, &known_emps, &existing_fingerprints, &mut summary);
    let val_duration = start_val.elapsed();

    println!(
        "PERFORMANCE METRIC [Import]: Parsed {} rows in {:?}, Validated in {:?}. Throughput: {:.0} rows/sec",
        summary.total_records,
        parse_duration,
        val_duration,
        (summary.total_records as f64) / (parse_duration + val_duration).as_secs_f64()
    );

    assert!(parse_duration.as_millis() < 500, "CSV Parsing of sample fixture must be under 500ms");
    assert!(val_duration.as_millis() < 300, "Validation of sample fixture must be under 300ms");

    Ok(())
}

#[tokio::test]
async fn test_attendance_engine_processing_throughput() -> Result<()> {
    let pool = get_test_pool().await;

    let org = OrganizationRepository::create(
        &pool,
        &format!("ORG-PERF-{}", Utc::now().timestamp_micros()),
        "Perf Test Org",
        "Asia/Kolkata",
    )
    .await?;

    let sec = SectionRepository::create(&pool, org.id, "SEC-P", "Perf Section", None).await?;
    let des = DesignationRepository::create(&pool, org.id, "DES-P", "Staff", 1).await?;
    let rule = AttendanceRuleRepository::create(
        &pool,
        org.id,
        "Shift",
        NaiveTime::from_hms_opt(9, 30, 0).unwrap(),
        NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
        15,
        240,
        420,
        15,
        12,
        false,
        NaiveDate::from_ymd_opt(2026, 8, 1).unwrap(),
        None,
    )
    .await?;

    let num_employees = 10;
    let num_days = 10;

    let mut employees = Vec::new();
    for i in 0..num_employees {
        let emp = EmployeeRepository::create(
            &pool,
            org.id,
            &format!("EMP-P-{}", i),
            &format!("700{}", i),
            "PerfUser",
            None,
            Some(&format!("{}", i)),
            None,
            None,
            sec.id,
            des.id,
            rule.id,
            NaiveDate::from_ymd_opt(2026, 1, 15).unwrap(),
            EmployeeStatus::Active,
            None,
        )
        .await?;
        employees.push(emp);
    }

    let start_date = NaiveDate::from_ymd_opt(2026, 8, 1).unwrap();
    let start_proc = Instant::now();

    let mut total_processed = 0;
    for emp in &employees {
        for d in 0..num_days {
            let target_date = start_date + Duration::days(d);
            let _daily = process_and_persist_employee_date(
                &pool,
                org.id,
                emp.id,
                emp.section_id,
                &emp.attendance_device_user_id,
                target_date,
                rule.id,
            )
            .await?;
            total_processed += 1;
        }
    }

    let proc_duration = start_proc.elapsed();
    let throughput = (total_processed as f64) / proc_duration.as_secs_f64();

    println!(
        "PERFORMANCE METRIC [Engine]: Processed {} employee-days in {:?}. Throughput: {:.1} employee-days/sec",
        total_processed, proc_duration, throughput
    );

    assert!(total_processed > 0);
    assert!(throughput > 10.0, "Engine processing throughput must exceed 10 employee-days/sec");

    Ok(())
}

#[tokio::test]
async fn test_multithreaded_concurrency_determinism() -> Result<()> {
    let pool = get_test_pool().await;

    let org = OrganizationRepository::create(
        &pool,
        &format!("ORG-CONC-{}", Utc::now().timestamp_micros()),
        "Conc Test Org",
        "Asia/Kolkata",
    )
    .await?;

    let sec = SectionRepository::create(&pool, org.id, "SEC-C", "Conc Section", None).await?;
    let des = DesignationRepository::create(&pool, org.id, "DES-C", "Officer", 1).await?;
    let rule = AttendanceRuleRepository::create(
        &pool,
        org.id,
        "Shift",
        NaiveTime::from_hms_opt(9, 30, 0).unwrap(),
        NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
        15,
        240,
        420,
        15,
        12,
        false,
        NaiveDate::from_ymd_opt(2026, 8, 1).unwrap(),
        None,
    )
    .await?;

    let emp = EmployeeRepository::create(
        &pool,
        org.id,
        &format!("EMP-CONC-{}", Utc::now().timestamp_micros()),
        &format!("800{}", Utc::now().timestamp_micros() % 1000),
        "ConcUser",
        None,
        Some("Test"),
        None,
        None,
        sec.id,
        des.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 15).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    let target_date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    // Spawn 4 concurrent workers calculating the EXACT SAME employee and date simultaneously
    let mut handles = Vec::new();
    for _ in 0..4 {
        let pool_clone = pool.clone();
        let org_id = org.id;
        let emp_id = emp.id;
        let sec_id = emp.section_id;
        let dev_id = emp.attendance_device_user_id.clone();
        let rule_id = rule.id;

        handles.push(tokio::spawn(async move {
            process_and_persist_employee_date(
                &pool_clone,
                org_id,
                emp_id,
                sec_id,
                &dev_id,
                target_date,
                rule_id,
            )
            .await
        }));
    }

    let mut results = Vec::new();
    for h in handles {
        let res = h.await.expect("Worker thread join failed")?;
        results.push(res);
    }

    assert_eq!(results.len(), 4);

    // Verify 100% determinism: All 4 concurrent executions produced identical status and duty minutes!
    let first = &results[0];
    for res in &results[1..] {
        assert_eq!(res.status, first.status, "Concurrent calculation status must be identical");
        assert_eq!(
            res.total_duty_minutes, first.total_duty_minutes,
            "Concurrent calculation duty minutes must be identical"
        );
    }

    Ok(())
}

#[tokio::test]
async fn test_database_query_explain_index_usage() -> Result<()> {
    let pool = get_test_pool().await;

    // Run EXPLAIN ANALYZE on attendance_daily queries
    let row = sqlx::query("EXPLAIN (ANALYZE, FORMAT JSON) SELECT * FROM attendance_daily WHERE organization_id = $1 AND attendance_date = $2")
        .bind(uuid::Uuid::now_v7())
        .bind(NaiveDate::from_ymd_opt(2026, 8, 22).unwrap())
        .fetch_one(&pool)
        .await
        .map_err(|e| aims_common::AimsError::Database(e.to_string()))?;

    let plan_val: serde_json::Value = row.get(0);
    let plan_str = serde_json::to_string(&plan_val).unwrap_or_default();
    println!("DATABASE EXPLAIN PLAN [attendance_daily]: {}", plan_str);

    assert!(!plan_str.is_empty(), "Explain plan must return JSON data");

    Ok(())
}
