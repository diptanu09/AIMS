use aims_common::Result;
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    attendance_rules::AttendanceRuleRepository,
    audit::AuditLogRepository,
    corrections::CorrectionRepository,
    designations::DesignationRepository,
    employees::EmployeeRepository,
    holidays::HolidayRepository,
    leave::LeaveRepository,
    organizations::OrganizationRepository,
    sections::SectionRepository,
    users::UserRepository,
};
use aims_domain::{AttendanceDaily, AttendanceStatus, CorrectionStatus, EmployeeStatus};
use chrono::{NaiveDate, NaiveTime, Utc};
use sqlx::PgPool;

async fn get_test_pool() -> PgPool {
    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://postgres:root@123@127.0.0.1:5432/AIMS?search_path=AIMS".to_string());
    PgPool::connect(&db_url)
        .await
        .expect("Failed to connect to test database")
}

#[tokio::test]
async fn test_employee_master_lifecycle() -> Result<()> {
    let pool = get_test_pool().await;

    // 1. Create Organization
    let org = OrganizationRepository::create(&pool, &format!("ORG-{}", Utc::now().timestamp_micros()), "Step 12 Org", "Asia/Kolkata")
        .await?;

    // 2. Create Sections
    let sec1 = SectionRepository::create(&pool, org.id, "SEC-ADM-1", "Accounts Section", None).await?;
    let sec2 = SectionRepository::create(&pool, org.id, "SEC-ADM-2", "Pension Section", None).await?;

    // 3. Create Designation & Rule
    let des = DesignationRepository::create(&pool, org.id, "AAO-ADM", "Assistant Accounts Officer", 3).await?;
    let rule = AttendanceRuleRepository::create(
        &pool,
        org.id,
        "Regular Shift",
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

    // 4. Create Employee
    let emp = EmployeeRepository::create(
        &pool,
        org.id,
        &format!("EMP-{}", Utc::now().timestamp_micros()),
        &format!("100{}", Utc::now().timestamp_micros() % 1000),
        "Rajesh",
        None,
        Some("Kumar"),
        None,
        None,
        sec1.id,
        des.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 15).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    assert_eq!(emp.status, EmployeeStatus::Active);
    assert_eq!(emp.section_id, sec1.id);

    // 5. Transfer Employee to sec2
    let eff_date = NaiveDate::from_ymd_opt(2026, 8, 22).unwrap();
    let transferred = EmployeeRepository::transfer_section(&pool, org.id, emp.id, sec2.id, eff_date, Some("Admin Transfer"), None).await?;
    assert_eq!(transferred.section_id, sec2.id);

    Ok(())
}

#[tokio::test]
async fn test_correction_workflow_and_audit() -> Result<()> {
    let pool = get_test_pool().await;

    let org = OrganizationRepository::create(&pool, &format!("ORG-C-{}", Utc::now().timestamp_micros()), "Correction Test Org", "Asia/Kolkata")
        .await?;
    let sec = SectionRepository::create(&pool, org.id, "SEC-CORR", "Audit Section", None).await?;
    let des = DesignationRepository::create(&pool, org.id, "DES-CORR", "Senior Officer", 1).await?;
    let rule = AttendanceRuleRepository::create(
        &pool,
        org.id,
        "Standard Shift",
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
        &format!("EMP-C-{}", Utc::now().timestamp_micros()),
        &format!("200{}", Utc::now().timestamp_micros() % 1000),
        "Anil",
        None,
        Some("Sharma"),
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

    let u_req_name = format!("req_{}", Utc::now().timestamp_micros());
    let u_app_name = format!("app_{}", Utc::now().timestamp_micros());

    // Create User (Requester) & User (Approver)
    let user_req = UserRepository::create(&pool, org.id, &u_req_name, &format!("{}@cag.gov.in", u_req_name), "hash", "Requester User").await?;
    let user_app = UserRepository::create(&pool, org.id, &u_app_name, &format!("{}@cag.gov.in", u_app_name), "hash", "Approver User").await?;

    // Create Daily Record
    let date = NaiveDate::from_ymd_opt(2026, 8, 22).unwrap();
    let daily_record = AttendanceDaily {
        id: uuid::Uuid::now_v7(),
        organization_id: org.id,
        employee_id: emp.id,
        section_id: sec.id,
        attendance_date: date,
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

    DailyAttendanceRepository::save(&pool, &daily_record).await?;

    // Request Correction
    let corr = CorrectionRepository::create(
        &pool,
        daily_record.id,
        user_req.id,
        None,
        None,
        AttendanceStatus::Absent,
        Some(Utc::now()),
        Some(Utc::now()),
        AttendanceStatus::Present,
        "Biometric Malfunction",
    )
    .await?;

    assert_eq!(corr.status, CorrectionStatus::Pending);
    assert_ne!(corr.requested_by, user_app.id, "Requester and Approver must be distinct");

    // Approve Correction
    let approved = CorrectionRepository::approve(&pool, corr.id, user_app.id).await?;
    assert_eq!(approved.status, CorrectionStatus::Approved);
    assert_eq!(approved.approved_by, Some(user_app.id));

    // Record & List Audit Entry
    AuditLogRepository::log(
        &pool,
        Some(org.id),
        Some(user_app.id),
        "CORRECTION_APPROVED",
        "attendance_corrections",
        Some(corr.id),
        None,
        None,
        None,
        None,
    )
    .await?;

    let audit_logs = AuditLogRepository::list_recent(&pool, org.id, 10, 0).await?;
    assert!(!audit_logs.is_empty());
    assert_eq!(audit_logs[0].action, "CORRECTION_APPROVED");

    Ok(())
}

#[tokio::test]
async fn test_holiday_and_leave_records() -> Result<()> {
    let pool = get_test_pool().await;

    let org = OrganizationRepository::create(&pool, &format!("ORG-HL-{}", Utc::now().timestamp_micros()), "Holiday Leave Org", "Asia/Kolkata")
        .await?;
    let sec = SectionRepository::create(&pool, org.id, "SEC-HL", "Leave Section", None).await?;
    let des = DesignationRepository::create(&pool, org.id, "DES-HL", "Officer", 1).await?;
    let rule = AttendanceRuleRepository::create(
        &pool,
        org.id,
        "Standard Shift",
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
        &format!("EMP-HL-{}", Utc::now().timestamp_micros()),
        &format!("300{}", Utc::now().timestamp_micros() % 1000),
        "Suresh",
        None,
        Some("Verma"),
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

    let u_hl_name = format!("user_hl_{}", Utc::now().timestamp_micros());
    let user = UserRepository::create(&pool, org.id, &u_hl_name, &format!("{}@cag.gov.in", u_hl_name), "hash", "Leave User").await?;

    // Create Holiday
    let h_date = NaiveDate::from_ymd_opt(2026, 8, 15).unwrap();
    let hol = HolidayRepository::create(&pool, org.id, h_date, "Independence Day", Some("National Holiday"), false).await?;
    assert_eq!(hol.holiday_date, h_date);

    let hol_list = HolidayRepository::list_by_organization(&pool, org.id).await?;
    assert_eq!(hol_list.len(), 1);

    // Submit Leave Application
    let start_date = NaiveDate::from_ymd_opt(2026, 8, 25).unwrap();
    let end_date = NaiveDate::from_ymd_opt(2026, 8, 26).unwrap();
    let leave_id = LeaveRepository::create(&pool, org.id, emp.id, "CASUAL_LEAVE", start_date, end_date, Some("Personal work"), user.id).await?;

    let leave_list = LeaveRepository::list_by_organization(&pool, org.id).await?;
    assert_eq!(leave_list.len(), 1);
    assert_eq!(leave_list[0].id, leave_id);
    assert_eq!(leave_list[0].status, "PENDING");

    Ok(())
}
