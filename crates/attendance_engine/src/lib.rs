pub mod deduplicate;
pub mod duty;
pub mod pairing;
pub mod processor;
pub mod punctuality;
pub mod status;
pub mod types;

pub use deduplicate::deduplicate_jitter_punches;
pub use duty::calculate_duty_time;
pub use pairing::pair_sessions;
pub use processor::{calculate_attendance_for_employee_date, process_and_persist_employee_date};
pub use punctuality::{PunctualityResult, calculate_early_exit, calculate_lateness};
pub use status::evaluate_attendance_status;
pub use types::{
    AttendanceDailyResult, AttendancePunch, AttendanceSessionResult, AttendanceWarning,
    CalendarContext, CalendarStatus, PunchSourceMode,
};

#[cfg(test)]
mod tests {
    use super::*;
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
    fn test_v1_1_session_pairing_and_grace_separation() {
        let rule = sample_rule();
        let calendar = CalendarContext::default();
        let org_id = rule.organization_id;
        let emp_id = Uuid::now_v7();
        let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();

        let punches = vec![
            AttendancePunch {
                id: Uuid::now_v7(),
                employee_id: emp_id,
                timestamp: make_utc("2026-08-20", "09:48:00"), // 18m after start, 3m beyond grace
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

        let res = calculate_attendance_for_employee_date(
            org_id, emp_id, date, &rule, &calendar, &punches,
        );

        assert_eq!(res.status, AttendanceStatus::Late);
        assert_eq!(res.late_minutes, 18);
        assert_eq!(res.late_minutes_beyond_grace, 3);
        assert_eq!(res.total_duty_minutes, 468);
        assert_eq!(res.sessions.len(), 1);
    }

    #[test]
    fn test_deduplicate_jitter_punches() {
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
}
