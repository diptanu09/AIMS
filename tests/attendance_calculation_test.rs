use aims_attendance_engine::{
    AttendancePunch, AttendanceWarning, CalendarContext, PunchSourceMode,
    calculate_attendance_for_employee_date, deduplicate_jitter_punches,
};
use aims_domain::{AttendanceRule, AttendanceStatus, PunchType};
use chrono::{NaiveDate, NaiveTime, TimeZone, Utc};
use chrono_tz::Asia::Kolkata;
use uuid::Uuid;

fn sample_rule() -> AttendanceRule {
    AttendanceRule {
        id: Uuid::now_v7(),
        organization_id: Uuid::now_v7(),
        name: "Standard Office Shift".into(),
        shift_start_time: NaiveTime::from_hms_opt(9, 30, 0).unwrap(),
        shift_end_time: NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
        grace_period_minutes: 15,
        half_day_min_duration_minutes: 240,
        full_day_min_duration_minutes: 420,
        early_exit_threshold_minutes: 15,
        max_single_session_hours: 12,
        cross_midnight: false,
        effective_from: NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        effective_to: None,
        active: true,
        created_at: Utc::now(),
        updated_at: Utc::now(),
    }
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

#[test]
fn test_scenario_a_ontime_single_session() {
    let rule = sample_rule();
    let calendar = CalendarContext::default();
    let org_id = rule.organization_id;
    let emp_id = Uuid::now_v7();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:24:00"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "17:36:00"),
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let res =
        calculate_attendance_for_employee_date(org_id, emp_id, date, &rule, &calendar, &punches);
    assert_eq!(res.status, AttendanceStatus::Present);
    assert_eq!(res.total_duty_minutes, 492);
    assert_eq!(res.late_minutes, 0);
    assert_eq!(res.early_exit_minutes, 0);
}

#[test]
fn test_scenario_b_grace_period_arrival() {
    let rule = sample_rule();
    let calendar = CalendarContext::default();
    let org_id = rule.organization_id;
    let emp_id = Uuid::now_v7();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:44:00"), // 14m after 09:30 -> within 15m grace
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "17:36:00"),
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let res =
        calculate_attendance_for_employee_date(org_id, emp_id, date, &rule, &calendar, &punches);
    assert_eq!(res.status, AttendanceStatus::Present);
    assert_eq!(res.late_minutes, 14);
    assert_eq!(res.late_minutes_beyond_grace, 0);
}

#[test]
fn test_scenario_c_late_arrival_past_grace() {
    let rule = sample_rule();
    let calendar = CalendarContext::default();
    let org_id = rule.organization_id;
    let emp_id = Uuid::now_v7();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:51:00"), // 21m after start, 6m beyond grace
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "17:37:00"),
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let res =
        calculate_attendance_for_employee_date(org_id, emp_id, date, &rule, &calendar, &punches);
    assert_eq!(res.status, AttendanceStatus::Late);
    assert_eq!(res.late_minutes, 21);
    assert_eq!(res.late_minutes_beyond_grace, 6);
}

#[test]
fn test_scenario_d_early_exit() {
    let rule = sample_rule();
    let calendar = CalendarContext::default();
    let org_id = rule.organization_id;
    let emp_id = Uuid::now_v7();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:22:00"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "17:00:00"), // 30m early exit (> 15m threshold)
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let res =
        calculate_attendance_for_employee_date(org_id, emp_id, date, &rule, &calendar, &punches);
    assert_eq!(res.status, AttendanceStatus::EarlyExit);
    assert_eq!(res.early_exit_minutes, 30);
}

#[test]
fn test_scenario_e_late_and_early_exit() {
    let rule = sample_rule();
    let calendar = CalendarContext::default();
    let org_id = rule.organization_id;
    let emp_id = Uuid::now_v7();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:52:00"), // Late
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "17:02:00"), // Early exit
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let res =
        calculate_attendance_for_employee_date(org_id, emp_id, date, &rule, &calendar, &punches);
    assert_eq!(res.status, AttendanceStatus::LateAndEarlyExit);
}

#[test]
fn test_scenario_f_multiple_sessions_break() {
    let rule = sample_rule();
    let calendar = CalendarContext::default();
    let org_id = rule.organization_id;
    let emp_id = Uuid::now_v7();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:10:00"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "12:55:00"), // 225m
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "13:44:00"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "17:41:00"), // 237m
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let res =
        calculate_attendance_for_employee_date(org_id, emp_id, date, &rule, &calendar, &punches);
    assert_eq!(res.status, AttendanceStatus::Present);
    assert_eq!(res.sessions.len(), 2);
    assert_eq!(res.total_duty_minutes, 462);
}

#[test]
fn test_scenario_g_unclosed_session_missing_out() {
    let rule = sample_rule();
    let calendar = CalendarContext::default();
    let org_id = rule.organization_id;
    let emp_id = Uuid::now_v7();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    let punches = vec![AttendancePunch {
        id: Uuid::now_v7(),
        employee_id: emp_id,
        timestamp: make_utc("2026-08-20", "09:28:00"),
        punch_type: PunchType::In,
        source_mode: PunchSourceMode::ExplicitDirection,
        terminal_id: Some("BIO-01".into()),
    }];

    let res =
        calculate_attendance_for_employee_date(org_id, emp_id, date, &rule, &calendar, &punches);
    assert_eq!(res.status, AttendanceStatus::Incomplete);
    assert!(res.warnings.contains(&AttendanceWarning::MissingOut));
}

#[test]
fn test_scenario_h_duplicate_jitter_punches() {
    let emp_id = Uuid::now_v7();
    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:12:14"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:12:17"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let (filtered, warnings) = deduplicate_jitter_punches(&punches, 60);
    assert_eq!(filtered.len(), 1);
    assert_eq!(warnings.len(), 1);
}

#[test]
fn test_scenario_i_half_day_duration() {
    let rule = sample_rule();
    let calendar = CalendarContext::default();
    let org_id = rule.organization_id;
    let emp_id = Uuid::now_v7();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:32:00"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "13:47:00"), // 255m (>= 240m half day, < 420m full day)
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let res =
        calculate_attendance_for_employee_date(org_id, emp_id, date, &rule, &calendar, &punches);
    assert_eq!(res.status, AttendanceStatus::HalfDay);
    assert_eq!(res.total_duty_minutes, 255);
}

#[test]
fn test_scenario_j_severe_short_shift_absent() {
    let rule = sample_rule();
    let calendar = CalendarContext::default();
    let org_id = rule.organization_id;
    let emp_id = Uuid::now_v7();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

    let punches = vec![
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "09:30:00"),
            punch_type: PunchType::In,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
        AttendancePunch {
            id: Uuid::now_v7(),
            employee_id: emp_id,
            timestamp: make_utc("2026-08-20", "11:30:00"), // 120m (< 240m half day threshold)
            punch_type: PunchType::Out,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: Some("BIO-01".into()),
        },
    ];

    let res =
        calculate_attendance_for_employee_date(org_id, emp_id, date, &rule, &calendar, &punches);
    assert_eq!(res.status, AttendanceStatus::Absent);
    assert_eq!(res.total_duty_minutes, 120);
}
