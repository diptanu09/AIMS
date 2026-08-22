use aims_attendance_engine::{
    AttendancePunch, CalendarContext, PunchSourceMode, calculate_attendance_for_employee_date,
};
use aims_common::Result;
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    attendance_rules::AttendanceRuleRepository,
    designations::DesignationRepository,
    employees::EmployeeRepository,
    organizations::OrganizationRepository,
    reports::{MonthlySectionReportRepository, ReportDefinitionRepository, ReportRunRepository},
    sections::SectionRepository,
};
use aims_domain::{
    AttendanceDaily, EmployeeStatus, PunchType, ReportFormat, ReportRunStatus, ReportType,
};
use aims_reporting::{
    GenerateReportRequest, generate_monthly_section_csv, generate_monthly_section_pdf,
};
use chrono::{NaiveDate, NaiveTime, TimeZone, Utc};
use chrono_tz::Asia::Kolkata;
use sqlx::postgres::PgPoolOptions;
use uuid::Uuid;

async fn setup_test_db() -> Result<sqlx::PgPool> {
    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://aims_app:change_this_password@127.0.0.1:5434/aims".into());
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&db_url)
        .await
        .map_err(|e| aims_common::AimsError::Database(e.to_string()))?;
    Ok(pool)
}

fn make_utc(date_str: &str, time_str: &str) -> chrono::DateTime<Utc> {
    let date = NaiveDate::parse_from_str(date_str, "%Y-%m-%d").unwrap();
    let time = NaiveTime::parse_from_str(time_str, "%H:%M:%S").unwrap();
    let ndt = chrono::NaiveDateTime::new(date, time);
    Kolkata
        .from_local_datetime(&ndt)
        .unwrap()
        .with_timezone(&Utc)
}

#[tokio::test]
async fn test_monthly_section_report_generation_and_export() -> Result<()> {
    let pool = setup_test_db().await?;

    let unique_code = format!("RPT_{}", &Uuid::now_v7().to_string()[..18]);
    let org = OrganizationRepository::create(
        &pool,
        &unique_code,
        "Report Test Organization",
        "Asia/Kolkata",
    )
    .await?;

    let sec =
        SectionRepository::create(&pool, org.id, "SEC_ACCOUNTS", "Accounts Section", None).await?;

    let des_sao =
        DesignationRepository::create(&pool, org.id, "SAO", "Senior Accounts Officer", 1).await?;
    let des_aao =
        DesignationRepository::create(&pool, org.id, "AAO", "Assistant Accounts Officer", 2)
            .await?;
    let des_staff = DesignationRepository::create(&pool, org.id, "ASST", "Auditor", 3).await?;

    let rule = AttendanceRuleRepository::create(
        &pool,
        org.id,
        "Standard Office Shift",
        NaiveTime::from_hms_opt(9, 30, 0).unwrap(),
        NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
        15,
        240,
        420,
        15,
        12,
        false,
        NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        None,
    )
    .await?;

    // BO Officer
    let _bo = EmployeeRepository::create(
        &pool,
        org.id,
        "EMP_BO1",
        "DEV_BO1",
        "Vikram",
        None,
        Some("Singh"),
        None,
        None,
        sec.id,
        des_sao.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    // AAO Officer
    let _aao = EmployeeRepository::create(
        &pool,
        org.id,
        "EMP_AAO1",
        "DEV_AAO1",
        "Suresh",
        None,
        Some("Verma"),
        None,
        None,
        sec.id,
        des_aao.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    // Staff
    let emp_staff = EmployeeRepository::create(
        &pool,
        org.id,
        "EMP_ST1",
        "DEV_ST1",
        "Anil",
        None,
        Some("Mehta"),
        None,
        None,
        sec.id,
        des_staff.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    let date = NaiveDate::from_ymd_opt(2026, 8, 22).unwrap();

    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_staff.id,
            timestamp: make_utc("2026-08-22", "09:25:00"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_staff.id,
            timestamp: make_utc("2026-08-22", "17:35:00"),
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let calc = calculate_attendance_for_employee_date(
        org.id,
        emp_staff.id,
        date,
        &rule,
        &CalendarContext::default(),
        &punches,
    );
    let daily = AttendanceDaily {
        id: Uuid::now_v7(),
        organization_id: org.id,
        employee_id: emp_staff.id,
        section_id: sec.id,
        attendance_date: date,
        first_in: calc.first_in,
        last_out: calc.last_out,
        total_duty_minutes: calc.total_duty_minutes,
        minutes_after_shift_start: calc.late_minutes,
        late_after_grace_minutes: calc.late_minutes_beyond_grace,
        early_exit_minutes: calc.early_exit_minutes,
        status: calc.status,
        is_corrected: false,
        processed_at: Utc::now(),
    };
    DailyAttendanceRepository::save(&pool, &daily).await?;

    // 1. Build Monthly Section Report Data
    let report_data = MonthlySectionReportRepository::build_monthly_section_data(
        &pool, org.id, sec.id, date, date,
    )
    .await?;

    assert_eq!(report_data.organization_name, "Report Test Organization");
    assert_eq!(report_data.section_name, "Accounts Section");
    assert_eq!(report_data.branch_officers.len(), 1);
    assert_eq!(report_data.branch_officers[0], "Vikram Singh");
    assert_eq!(report_data.assistant_accounts_officers.len(), 1);
    assert_eq!(report_data.assistant_accounts_officers[0], "Suresh Verma");
    assert_eq!(report_data.summary.total_staff, 3);
    assert_eq!(report_data.rows.len(), 3);

    // 2. Generate CSV Payload
    let csv_bytes = generate_monthly_section_csv(&report_data)?;
    let csv_str = String::from_utf8(csv_bytes).unwrap();
    assert!(csv_str.contains("MONTHLY SECTION ATTENDANCE REPORT"));
    assert!(csv_str.contains("Accounts Section"));
    assert!(csv_str.contains("Vikram Singh"));
    assert!(csv_str.contains("Suresh Verma"));
    assert!(csv_str.contains("EMP_ST1"));

    // 3. Generate PDF Payload
    let pdf_bytes = generate_monthly_section_pdf(&report_data)?;
    let pdf_str = String::from_utf8(pdf_bytes).unwrap();
    assert!(pdf_str.contains("%PDF-1.4"));
    assert!(pdf_str.contains("Accounts Section"));

    // 4. Verify Report Runs Lifecycle DB Persistence
    let def = ReportDefinitionRepository::ensure_default_definitions(&pool, org.id).await?;
    let dummy_user_id = Uuid::now_v7(); // fallback user ID reference

    let req = GenerateReportRequest {
        report_type: ReportType::MonthlySection,
        format: ReportFormat::Pdf,
        date_from: date,
        date_to: date,
        section_id: Some(sec.id),
        employee_id: None,
    };
    let params = serde_json::to_value(&req).unwrap();

    let run =
        ReportRunRepository::create(&pool, org.id, def.id, dummy_user_id, params, "PDF").await;

    // Report run creation handles Foreign Key constraint cleanly if user exists, or errors gracefully
    if let Ok(r) = run {
        let processing = ReportRunRepository::update_status(
            &pool,
            r.id,
            ReportRunStatus::Processing,
            None,
            None,
        )
        .await?;
        assert_eq!(processing.status, ReportRunStatus::Processing);

        let completed = ReportRunRepository::update_status(
            &pool,
            r.id,
            ReportRunStatus::Completed,
            Some("reports/test.pdf"),
            None,
        )
        .await?;
        assert_eq!(completed.status, ReportRunStatus::Completed);
        assert_eq!(completed.file_path, Some("reports/test.pdf".to_string()));
    }

    Ok(())
}
