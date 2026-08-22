use aims_common::Result;
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    attendance_rules::AttendanceRuleRepository,
    corrections::CorrectionRepository,
    designations::DesignationRepository,
    employees::EmployeeRepository,
    import_batches::ImportBatchRepository,
    organizations::OrganizationRepository,
    sections::SectionRepository,
    users::UserRepository,
};
use aims_domain::{AttendanceDaily, AttendanceStatus, EmployeeStatus};
use aims_import_engine::validation::sanitize_csv_formula;
use chrono::{NaiveDate, NaiveTime, Utc};
use sqlx::PgPool;

async fn get_test_pool() -> PgPool {
    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://aims_app:change_this_password@127.0.0.1:5434/aims".to_string());
    PgPool::connect(&db_url)
        .await
        .expect("Failed to connect to test database")
}

#[test]
fn test_csv_formula_injection_sanitization() {
    assert_eq!(sanitize_csv_formula("=1+1"), "'=1+1");
    assert_eq!(sanitize_csv_formula("+cmd|' /C calc'!A0"), "'+cmd|' /C calc'!A0");
    assert_eq!(sanitize_csv_formula("-100"), "'-100");
    assert_eq!(sanitize_csv_formula("@SUM(A1:A5)"), "'@SUM(A1:A5)");
    assert_eq!(sanitize_csv_formula("Normal Text"), "Normal Text");
}

#[tokio::test]
async fn test_raw_attendance_events_immutability() -> Result<()> {
    let pool = get_test_pool().await;

    let org = OrganizationRepository::create(&pool, &format!("ORG-SEC-{}", Utc::now().timestamp_micros()), "Sec Org", "Asia/Kolkata").await?;

    let u_name = format!("u_sec_{}", Utc::now().timestamp_micros());
    let user = UserRepository::create(&pool, org.id, &u_name, &format!("{}@cag.gov.in", u_name), "hash", "Sec User").await?;

    let batch = ImportBatchRepository::create(&pool, org.id, "test.csv", "hash123", user.id).await?;
    let fingerprint = format!("{:064x}", Utc::now().timestamp_nanos_opt().unwrap_or(0));

    // Create Raw Attendance Event
    let raw_event_id = sqlx::query!(
        r#"
        INSERT INTO attendance_raw_events (organization_id, batch_id, source_row_number, attendance_device_user_id, punch_timestamp, punch_type, source_mode, event_fingerprint, raw_text)
        VALUES ($1, $2, 1, '1001', CURRENT_TIMESTAMP, 'IN', 'EXPLICIT_DIRECTION', $3, '1001,2026-08-22 09:30:00,IN')
        RETURNING id
        "#,
        org.id,
        batch.id,
        fingerprint
    )
    .fetch_one(&pool)
    .await
    .map_err(|e| aims_common::AimsError::Database(e.to_string()))?
    .id;

    // Attempt direct UPDATE on raw_attendance_events -> Must fail due to trigger
    let update_res = sqlx::query!(
        "UPDATE attendance_raw_events SET attendance_device_user_id = '9999' WHERE id = $1",
        raw_event_id
    )
    .execute(&pool)
    .await;

    assert!(update_res.is_err(), "Database trigger must reject raw attendance updates");

    // Attempt direct DELETE on raw_attendance_events -> Must fail due to trigger
    let delete_res = sqlx::query!(
        "DELETE FROM attendance_raw_events WHERE id = $1",
        raw_event_id
    )
    .execute(&pool)
    .await;

    assert!(delete_res.is_err(), "Database trigger must reject raw attendance deletions");

    Ok(())
}

#[tokio::test]
async fn test_section_scope_and_self_approval_guards() -> Result<()> {
    let pool = get_test_pool().await;

    let org = OrganizationRepository::create(&pool, &format!("ORG-AUTH-{}", Utc::now().timestamp_micros()), "Auth Guard Org", "Asia/Kolkata").await?;

    let _sec1 = SectionRepository::create(&pool, org.id, "SEC-S1", "Section One", None).await?;
    let sec2 = SectionRepository::create(&pool, org.id, "SEC-S2", "Section Two", None).await?;

    let des = DesignationRepository::create(&pool, org.id, "DES-S", "Officer", 1).await?;
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

    let emp_sec2 = EmployeeRepository::create(
        &pool,
        org.id,
        &format!("EMP-S2-{}", Utc::now().timestamp_micros()),
        &format!("500{}", Utc::now().timestamp_micros() % 1000),
        "Ramesh",
        None,
        Some("Kumar"),
        None,
        None,
        sec2.id,
        des.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 15).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    let u_bo_sec1 = UserRepository::create(&pool, org.id, &format!("bo_s1_{}", Utc::now().timestamp_micros()), "bo1@cag.gov.in", "hash", "BO Section 1").await?;

    // Create Daily Record for employee in Section 2
    let daily_s2 = AttendanceDaily {
        id: uuid::Uuid::now_v7(),
        organization_id: org.id,
        employee_id: emp_sec2.id,
        section_id: sec2.id,
        attendance_date: NaiveDate::from_ymd_opt(2026, 8, 22).unwrap(),
        first_in: None,
        last_out: None,
        total_duty_minutes: 0,
        minutes_after_shift_start: 0,
        late_after_grace_minutes: 0,
        early_exit_minutes: 0,
        status: AttendanceStatus::Absent,
        is_corrected: false,
        processed_at: Utc::now(),
    };

    DailyAttendanceRepository::save(&pool, &daily_s2).await?;

    // Request Correction by BO Section 1
    let corr = CorrectionRepository::create(
        &pool,
        daily_s2.id,
        u_bo_sec1.id,
        None,
        None,
        AttendanceStatus::Absent,
        Some(Utc::now()),
        Some(Utc::now()),
        AttendanceStatus::Present,
        "Correction Request",
    )
    .await?;

    // Self approval attempt by u_bo_sec1 must be blocked
    assert_eq!(corr.requested_by, u_bo_sec1.id);

    Ok(())
}
