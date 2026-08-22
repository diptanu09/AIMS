use aims_attendance_engine::{
    AttendancePunch, CalendarContext, PunchSourceMode, calculate_attendance_for_employee_date,
};
use aims_common::Result;
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    attendance_query::AttendanceQueryRepository,
    attendance_rules::AttendanceRuleRepository,
    dashboard::DashboardRepository,
    designations::DesignationRepository,
    employees::EmployeeRepository,
    exceptions::{ExceptionFilter, ExceptionsRepository},
    organizations::OrganizationRepository,
    sections::SectionRepository,
};
use aims_domain::{AttendanceDaily, EmployeeStatus, PunchType};
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
async fn test_dashboard_and_exception_query_flow() -> Result<()> {
    let pool = setup_test_db().await?;

    let unique_code = format!("QTY_{}", &Uuid::now_v7().to_string()[..18]);
    let org = OrganizationRepository::create(&pool, &unique_code, "Query Test Org", "Asia/Kolkata")
        .await?;

    let sec =
        SectionRepository::create(&pool, org.id, "SEC_ACCOUNTS", "Accounts Section", None).await?;
    let des =
        DesignationRepository::create(&pool, org.id, "SAO", "Senior Accounts Officer", 1).await?;

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

    let emp1 = EmployeeRepository::create(
        &pool,
        org.id,
        "EMP_Q1",
        "DEV_Q1",
        "Rajesh",
        None,
        Some("Kumar"),
        None,
        None,
        sec.id,
        des.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    let emp2 = EmployeeRepository::create(
        &pool,
        org.id,
        "EMP_Q2",
        "DEV_Q2",
        "Amit",
        None,
        Some("Sharma"),
        None,
        None,
        sec.id,
        des.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    let date = NaiveDate::from_ymd_opt(2026, 8, 22).unwrap();

    // Emp 1: Present (09:24 -> 17:36)
    let p1 = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp1.id,
            timestamp: make_utc("2026-08-22", "09:24:00"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp1.id,
            timestamp: make_utc("2026-08-22", "17:36:00"),
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let calc1 = calculate_attendance_for_employee_date(
        org.id,
        emp1.id,
        date,
        &rule,
        &CalendarContext::default(),
        &p1,
    );
    let daily1 = AttendanceDaily {
        id: Uuid::now_v7(),
        organization_id: org.id,
        employee_id: emp1.id,
        section_id: sec.id,
        attendance_date: date,
        first_in: calc1.first_in,
        last_out: calc1.last_out,
        total_duty_minutes: calc1.total_duty_minutes,
        minutes_after_shift_start: calc1.late_minutes,
        late_after_grace_minutes: calc1.late_minutes_beyond_grace,
        early_exit_minutes: calc1.early_exit_minutes,
        status: calc1.status,
        is_corrected: false,
        processed_at: Utc::now(),
    };
    DailyAttendanceRepository::save(&pool, &daily1).await?;

    // Emp 2: Late (09:55 -> 17:35)
    let p2 = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp2.id,
            timestamp: make_utc("2026-08-22", "09:55:00"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp2.id,
            timestamp: make_utc("2026-08-22", "17:35:00"),
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let calc2 = calculate_attendance_for_employee_date(
        org.id,
        emp2.id,
        date,
        &rule,
        &CalendarContext::default(),
        &p2,
    );
    let daily2 = AttendanceDaily {
        id: Uuid::now_v7(),
        organization_id: org.id,
        employee_id: emp2.id,
        section_id: sec.id,
        attendance_date: date,
        first_in: calc2.first_in,
        last_out: calc2.last_out,
        total_duty_minutes: calc2.total_duty_minutes,
        minutes_after_shift_start: calc2.late_minutes,
        late_after_grace_minutes: calc2.late_minutes_beyond_grace,
        early_exit_minutes: calc2.early_exit_minutes,
        status: calc2.status,
        is_corrected: false,
        processed_at: Utc::now(),
    };
    DailyAttendanceRepository::save(&pool, &daily2).await?;

    // 1. Verify Dashboard Summary
    let summary = DashboardRepository::get_summary(&pool, org.id, date).await?;
    assert_eq!(summary.total_employees, 2);
    assert_eq!(summary.present, 1);
    assert_eq!(summary.late, 1);
    assert_eq!(summary.attendance_rate, 100.0);

    // 2. Verify Section Summaries
    let sec_summaries = DashboardRepository::get_section_summaries(&pool, org.id, date).await?;
    assert_eq!(sec_summaries.len(), 1);
    assert_eq!(sec_summaries[0].section_id, sec.id);
    assert_eq!(sec_summaries[0].present, 1);
    assert_eq!(sec_summaries[0].late, 1);

    // 3. Verify Exception Queries
    let (exceptions, total_exc) = ExceptionsRepository::list_exceptions(
        &pool,
        org.id,
        ExceptionFilter {
            date_from: Some(date),
            date_to: Some(date),
            section_id: None,
            employee_id: None,
            exception_type: Some("LATE".into()),
            limit: 10,
            offset: 0,
        },
    )
    .await?;

    assert_eq!(total_exc, 1);
    assert_eq!(exceptions[0].employee_id, emp2.id);
    assert_eq!(exceptions[0].exception_type, "LATE");

    // 4. Verify Section Hierarchy
    let hierarchy = AttendanceQueryRepository::get_section_hierarchy(&pool, sec.id).await?;
    assert_eq!(hierarchy.section_id, sec.id);
    assert_eq!(hierarchy.total_employees, 2);
    assert_eq!(hierarchy.branch_officers.len(), 2); // Senior Accounts Officers

    Ok(())
}
