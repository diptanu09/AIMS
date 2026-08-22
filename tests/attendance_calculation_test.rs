use aims_attendance_engine::{
    RawPunchInput, deduplicate_punches, evaluate_attendance_status, pair_sessions,
};
use aims_domain::{AttendanceRule, AttendanceStatus, PunchInterpretationMode, PunchType};
use chrono::{DateTime, NaiveDate, NaiveTime, Utc};
use uuid::Uuid;

fn create_test_rule() -> AttendanceRule {
    AttendanceRule {
        id: Uuid::now_v7(),
        organization_id: Uuid::now_v7(),
        name: "General Office Shift".into(),
        shift_start_time: NaiveTime::from_hms_opt(9, 0, 0).unwrap(),
        shift_end_time: NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
        grace_period_minutes: 15,
        half_day_min_duration_minutes: 240,
        full_day_min_duration_minutes: 420,
        early_exit_threshold_minutes: 15,
        max_single_session_hours: 14,
        created_at: Utc::now(),
        updated_at: Utc::now(),
    }
}

fn parse_dt(iso_str: &str) -> DateTime<Utc> {
    DateTime::parse_from_rfc3339(iso_str)
        .unwrap()
        .with_timezone(&Utc)
}

#[test]
fn test_scenario_a_ontime_single_session() {
    let rule = create_test_rule();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
    let t_in = parse_dt("2026-08-20T09:00:00Z");
    let t_out = parse_dt("2026-08-20T17:30:00Z");

    let punches = vec![
        RawPunchInput {
            timestamp: t_in,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t_out,
            punch_type: PunchType::Out,
        },
    ];

    let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
    assert_eq!(sessions.len(), 1);
    assert_eq!(sessions[0].duration_minutes, 510);
    assert!(!sessions[0].is_inferred);

    let (status, start_delay, late_after_grace, early_exit) = evaluate_attendance_status(
        &rule,
        date,
        Some(t_in),
        Some(t_out),
        sessions[0].duration_minutes,
        false,
    );

    assert_eq!(status, AttendanceStatus::Present);
    assert_eq!(start_delay, 0);
    assert_eq!(late_after_grace, 0);
    assert_eq!(early_exit, 0);
}

#[test]
fn test_scenario_b_grace_period_arrival() {
    let rule = create_test_rule();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
    let t_in = parse_dt("2026-08-20T09:10:00Z"); // 10m after start (within 15m grace)
    let t_out = parse_dt("2026-08-20T17:30:00Z");

    let punches = vec![
        RawPunchInput {
            timestamp: t_in,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t_out,
            punch_type: PunchType::Out,
        },
    ];

    let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
    let (status, start_delay, late_after_grace, early_exit) = evaluate_attendance_status(
        &rule,
        date,
        Some(t_in),
        Some(t_out),
        sessions[0].duration_minutes,
        false,
    );

    assert_eq!(status, AttendanceStatus::Present);
    assert_eq!(start_delay, 10);
    assert_eq!(late_after_grace, 0);
    assert_eq!(early_exit, 0);
}

#[test]
fn test_scenario_c_late_arrival_past_grace() {
    let rule = create_test_rule();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
    let t_in = parse_dt("2026-08-20T09:22:00Z"); // 22m after start (grace 15m)
    let t_out = parse_dt("2026-08-20T17:35:00Z");

    let punches = vec![
        RawPunchInput {
            timestamp: t_in,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t_out,
            punch_type: PunchType::Out,
        },
    ];

    let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
    let (status, start_delay, late_after_grace, early_exit) = evaluate_attendance_status(
        &rule,
        date,
        Some(t_in),
        Some(t_out),
        sessions[0].duration_minutes,
        false,
    );

    assert_eq!(status, AttendanceStatus::Late);
    assert_eq!(start_delay, 22);
    assert_eq!(late_after_grace, 7);
    assert_eq!(early_exit, 0);
}

#[test]
fn test_scenario_d_early_exit() {
    let rule = create_test_rule();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
    let t_in = parse_dt("2026-08-20T08:55:00Z");
    let t_out = parse_dt("2026-08-20T16:50:00Z"); // 40m early exit (end 17:30, threshold 15m)

    let punches = vec![
        RawPunchInput {
            timestamp: t_in,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t_out,
            punch_type: PunchType::Out,
        },
    ];

    let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
    let (status, start_delay, late_after_grace, early_exit) = evaluate_attendance_status(
        &rule,
        date,
        Some(t_in),
        Some(t_out),
        sessions[0].duration_minutes,
        false,
    );

    assert_eq!(status, AttendanceStatus::EarlyExit);
    assert_eq!(start_delay, 0);
    assert_eq!(late_after_grace, 0);
    assert_eq!(early_exit, 40);
}

#[test]
fn test_scenario_e_late_and_early_exit() {
    let rule = create_test_rule();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
    let t_in = parse_dt("2026-08-20T09:25:00Z"); // Late
    let t_out = parse_dt("2026-08-20T16:50:00Z"); // Early Exit

    let punches = vec![
        RawPunchInput {
            timestamp: t_in,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t_out,
            punch_type: PunchType::Out,
        },
    ];

    let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
    let (status, start_delay, late_after_grace, early_exit) = evaluate_attendance_status(
        &rule,
        date,
        Some(t_in),
        Some(t_out),
        sessions[0].duration_minutes,
        false,
    );

    assert_eq!(status, AttendanceStatus::LateAndEarlyExit);
    assert_eq!(start_delay, 25);
    assert_eq!(late_after_grace, 10);
    assert_eq!(early_exit, 40);
}

#[test]
fn test_scenario_f_multiple_sessions_break() {
    let rule = create_test_rule();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
    let t1_in = parse_dt("2026-08-20T09:00:00Z");
    let t1_out = parse_dt("2026-08-20T13:00:00Z"); // 240m
    let t2_in = parse_dt("2026-08-20T14:00:00Z");
    let t2_out = parse_dt("2026-08-20T17:30:00Z"); // 210m

    let punches = vec![
        RawPunchInput {
            timestamp: t1_in,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t1_out,
            punch_type: PunchType::Out,
        },
        RawPunchInput {
            timestamp: t2_in,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t2_out,
            punch_type: PunchType::Out,
        },
    ];

    let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
    assert_eq!(sessions.len(), 2);
    let total_duty: i32 = sessions.iter().map(|s| s.duration_minutes).sum();
    assert_eq!(total_duty, 450); // 240 + 210

    let (status, _, _, _) =
        evaluate_attendance_status(&rule, date, Some(t1_in), Some(t2_out), total_duty, false);

    assert_eq!(status, AttendanceStatus::Present);
}

#[test]
fn test_scenario_g_unclosed_session_missing_out() {
    let rule = create_test_rule();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
    let t_in = parse_dt("2026-08-20T09:00:00Z");

    let punches = vec![RawPunchInput {
        timestamp: t_in,
        punch_type: PunchType::In,
    }];

    let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
    assert_eq!(sessions.len(), 1);
    assert!(sessions[0].is_inferred);

    let (status, _, _, _) = evaluate_attendance_status(&rule, date, Some(t_in), None, 0, true);

    assert_eq!(status, AttendanceStatus::Incomplete);
}

#[test]
fn test_scenario_h_duplicate_jitter_punches() {
    let t1 = parse_dt("2026-08-20T08:59:50Z");
    let t2 = parse_dt("2026-08-20T09:00:10Z"); // 20s jitter
    let t3 = parse_dt("2026-08-20T17:30:00Z");

    let punches = vec![
        RawPunchInput {
            timestamp: t1,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t2,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t3,
            punch_type: PunchType::Out,
        },
    ];

    let deduplicated = deduplicate_punches(&punches, 60);
    assert_eq!(deduplicated.len(), 2);
    assert_eq!(deduplicated[0].timestamp, t1);
    assert_eq!(deduplicated[1].timestamp, t3);
}

#[test]
fn test_scenario_i_half_day_duration() {
    let rule = create_test_rule();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
    let t_in = parse_dt("2026-08-20T09:00:00Z");
    let t_out = parse_dt("2026-08-20T13:30:00Z"); // 270m (>= half 240m, < full 420m)

    let punches = vec![
        RawPunchInput {
            timestamp: t_in,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t_out,
            punch_type: PunchType::Out,
        },
    ];

    let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
    let (status, _, _, _) = evaluate_attendance_status(
        &rule,
        date,
        Some(t_in),
        Some(t_out),
        sessions[0].duration_minutes,
        false,
    );

    assert_eq!(status, AttendanceStatus::HalfDay);
}

#[test]
fn test_scenario_j_severe_short_shift_absent() {
    let rule = create_test_rule();
    let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
    let t_in = parse_dt("2026-08-20T09:00:00Z");
    let t_out = parse_dt("2026-08-20T11:30:00Z"); // 150m (< half 240m)

    let punches = vec![
        RawPunchInput {
            timestamp: t_in,
            punch_type: PunchType::In,
        },
        RawPunchInput {
            timestamp: t_out,
            punch_type: PunchType::Out,
        },
    ];

    let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
    let (status, _, _, _) = evaluate_attendance_status(
        &rule,
        date,
        Some(t_in),
        Some(t_out),
        sessions[0].duration_minutes,
        false,
    );

    assert_eq!(status, AttendanceStatus::Absent);
}
