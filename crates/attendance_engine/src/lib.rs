use aims_common::{AimsError, Result};
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    attendance_rules::AttendanceRuleRepository,
    attendance_sessions::{AttendanceSessionRecord, AttendanceSessionRepository},
    employees::EmployeeRepository,
};
use aims_domain::{
    AttendanceDaily, AttendanceRule, AttendanceStatus, Employee, PunchInterpretationMode, PunchType,
};
use chrono::{DateTime, NaiveDate, Utc};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct RawPunchInput {
    pub timestamp: DateTime<Utc>,
    pub punch_type: PunchType,
}

#[derive(Debug, Clone, FromRow)]
struct QueryRawPunch {
    pub punch_timestamp: DateTime<Utc>,
    pub punch_type: PunchType,
}

#[derive(Debug, Clone)]
pub struct CalculatedSession {
    pub in_timestamp: DateTime<Utc>,
    pub out_timestamp: Option<DateTime<Utc>>,
    pub duration_minutes: i32,
    pub session_order: i32,
    pub is_inferred: bool,
}

#[derive(Debug, Clone)]
pub struct CalculationResult {
    pub daily: AttendanceDaily,
    pub sessions: Vec<CalculatedSession>,
}

pub fn deduplicate_punches(punches: &[RawPunchInput], jitter_seconds: i64) -> Vec<RawPunchInput> {
    if punches.is_empty() {
        return Vec::new();
    }

    let mut sorted = punches.to_vec();
    sorted.sort_by_key(|p| p.timestamp);

    let mut deduplicated = Vec::new();
    let mut last_timestamp: Option<DateTime<Utc>> = None;

    for p in sorted {
        if let Some(last) = last_timestamp {
            if (p.timestamp - last).num_seconds().abs() < jitter_seconds {
                continue; // Ignore jitter punch within 60s
            }
        }
        last_timestamp = Some(p.timestamp);
        deduplicated.push(p);
    }

    deduplicated
}

pub fn pair_sessions(
    punches: &[RawPunchInput],
    _mode: &PunchInterpretationMode,
) -> Vec<CalculatedSession> {
    if punches.is_empty() {
        return Vec::new();
    }

    let mut sessions = Vec::new();
    let mut order = 1;
    let mut current_in: Option<DateTime<Utc>> = None;

    for p in punches {
        match p.punch_type {
            PunchType::In => {
                if let Some(in_time) = current_in {
                    // Unclosed previous IN -> infer close session
                    sessions.push(CalculatedSession {
                        in_timestamp: in_time,
                        out_timestamp: None,
                        duration_minutes: 0,
                        session_order: order,
                        is_inferred: true,
                    });
                    order += 1;
                }
                current_in = Some(p.timestamp);
            }
            PunchType::Out => {
                if let Some(in_time) = current_in {
                    let dur = (p.timestamp - in_time).num_minutes().max(0) as i32;
                    sessions.push(CalculatedSession {
                        in_timestamp: in_time,
                        out_timestamp: Some(p.timestamp),
                        duration_minutes: dur,
                        session_order: order,
                        is_inferred: false,
                    });
                    order += 1;
                    current_in = None;
                } else {
                    // OUT without preceding IN -> inferred single OUT session
                    sessions.push(CalculatedSession {
                        in_timestamp: p.timestamp,
                        out_timestamp: Some(p.timestamp),
                        duration_minutes: 0,
                        session_order: order,
                        is_inferred: true,
                    });
                    order += 1;
                }
            }
            PunchType::Unknown => {
                // Heuristic direction based on active session state
                if let Some(in_time) = current_in {
                    let dur = (p.timestamp - in_time).num_minutes().max(0) as i32;
                    sessions.push(CalculatedSession {
                        in_timestamp: in_time,
                        out_timestamp: Some(p.timestamp),
                        duration_minutes: dur,
                        session_order: order,
                        is_inferred: false,
                    });
                    order += 1;
                    current_in = None;
                } else {
                    current_in = Some(p.timestamp);
                }
            }
        }
    }

    if let Some(in_time) = current_in {
        sessions.push(CalculatedSession {
            in_timestamp: in_time,
            out_timestamp: None,
            duration_minutes: 0,
            session_order: order,
            is_inferred: true,
        });
    }

    sessions
}

pub fn evaluate_attendance_status(
    rule: &AttendanceRule,
    _attendance_date: NaiveDate,
    first_in: Option<DateTime<Utc>>,
    last_out: Option<DateTime<Utc>>,
    total_duty_minutes: i32,
    has_inferred_session: bool,
) -> (AttendanceStatus, i32, i32, i32) {
    if first_in.is_none() || total_duty_minutes == 0 {
        return (AttendanceStatus::Absent, 0, 0, 0);
    }

    let first_in_dt = first_in.unwrap();
    let first_in_time = first_in_dt.time();

    let minutes_after_shift_start = if first_in_time > rule.shift_start_time {
        (first_in_time - rule.shift_start_time).num_minutes() as i32
    } else {
        0
    };

    let late_after_grace_minutes = (minutes_after_shift_start - rule.grace_period_minutes).max(0);

    let early_exit_minutes = if let Some(out_dt) = last_out {
        let out_time = out_dt.time();
        if out_time < rule.shift_end_time {
            (rule.shift_end_time - out_time).num_minutes() as i32
        } else {
            0
        }
    } else {
        0
    };

    let is_late = late_after_grace_minutes > 0;
    let is_early_exit = early_exit_minutes > rule.early_exit_threshold_minutes;

    let status = if has_inferred_session {
        AttendanceStatus::Incomplete
    } else if total_duty_minutes < rule.half_day_min_duration_minutes {
        AttendanceStatus::Absent
    } else if total_duty_minutes < rule.full_day_min_duration_minutes {
        AttendanceStatus::HalfDay
    } else if is_late && is_early_exit {
        AttendanceStatus::LateAndEarlyExit
    } else if is_late {
        AttendanceStatus::Late
    } else if is_early_exit {
        AttendanceStatus::EarlyExit
    } else {
        AttendanceStatus::Present
    };

    (
        status,
        minutes_after_shift_start,
        late_after_grace_minutes,
        early_exit_minutes,
    )
}

pub async fn process_employee_day(
    pool: &PgPool,
    organization_id: Uuid,
    employee: &Employee,
    target_date: NaiveDate,
) -> Result<CalculationResult> {
    let rule = AttendanceRuleRepository::find_by_id(pool, employee.attendance_rule_id)
        .await?
        .ok_or_else(|| AimsError::NotFound(format!("Attendance rule '{}' not found", employee.attendance_rule_id)))?;

    let raw_records = sqlx::query_as::<_, QueryRawPunch>(
        r#"
        SELECT punch_timestamp, punch_type
        FROM attendance_raw_events
        WHERE organization_id = $1
          AND employee_id = $2
          AND punch_timestamp::date = $3
        ORDER BY punch_timestamp ASC
        "#
    )
    .bind(organization_id)
    .bind(employee.id)
    .bind(target_date)
    .fetch_all(pool)
    .await
    .map_err(|e| AimsError::Database(format!("Failed to query raw events for calculation: {}", e)))?;

    let inputs: Vec<RawPunchInput> = raw_records
        .into_iter()
        .map(|r| RawPunchInput {
            timestamp: r.punch_timestamp,
            punch_type: r.punch_type,
        })
        .collect();

    let deduplicated = deduplicate_punches(&inputs, 60);
    let sessions = pair_sessions(&deduplicated, &PunchInterpretationMode::ExplicitDirection);

    let first_in = sessions.iter().find(|s| !s.is_inferred).map(|s| s.in_timestamp).or_else(|| sessions.first().map(|s| s.in_timestamp));
    let last_out = sessions.iter().rev().find_map(|s| s.out_timestamp);
    let total_duty_minutes: i32 = sessions.iter().map(|s| s.duration_minutes).sum();
    let has_inferred = sessions.iter().any(|s| s.is_inferred);

    let (status, minutes_after_start, late_after_grace, early_exit) = evaluate_attendance_status(
        &rule,
        target_date,
        first_in,
        last_out,
        total_duty_minutes,
        has_inferred,
    );

    let daily_id = uuid::Uuid::now_v7();
    let daily = AttendanceDaily {
        id: daily_id,
        organization_id,
        employee_id: employee.id,
        section_id: employee.section_id,
        attendance_date: target_date,
        first_in,
        last_out,
        total_duty_minutes,
        minutes_after_shift_start: minutes_after_start,
        late_after_grace_minutes: late_after_grace,
        early_exit_minutes: early_exit,
        status,
        is_corrected: false,
        processed_at: Utc::now(),
    };

    let saved_daily = DailyAttendanceRepository::save(pool, &daily).await?;

    let session_records: Vec<AttendanceSessionRecord> = sessions
        .iter()
        .map(|s| AttendanceSessionRecord {
            id: uuid::Uuid::now_v7(),
            attendance_daily_id: saved_daily.id,
            in_timestamp: s.in_timestamp,
            out_timestamp: s.out_timestamp,
            duration_minutes: s.duration_minutes,
            session_order: s.session_order,
            is_inferred: s.is_inferred,
        })
        .collect();

    AttendanceSessionRepository::replace_sessions_for_daily(pool, saved_daily.id, &session_records).await?;

    Ok(CalculationResult {
        daily: saved_daily,
        sessions,
    })
}

pub async fn run_calculation_for_date_range(
    pool: &PgPool,
    organization_id: Uuid,
    start_date: NaiveDate,
    end_date: NaiveDate,
    employee_id: Option<Uuid>,
) -> Result<i32> {
    let employees = if let Some(emp_id) = employee_id {
        let emp = EmployeeRepository::find_by_id(pool, emp_id)
            .await?
            .ok_or_else(|| AimsError::NotFound(format!("Employee '{}' not found", emp_id)))?;
        vec![emp]
    } else {
        EmployeeRepository::list_by_organization(pool, organization_id).await?
    };

    let mut processed_days = 0;
    let mut current_date = start_date;

    while current_date <= end_date {
        for emp in &employees {
            process_employee_day(pool, organization_id, emp, current_date).await?;
            processed_days += 1;
        }
        current_date += chrono::Duration::days(1);
    }

    Ok(processed_days)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::NaiveTime;

    #[test]
    fn test_v1_1_session_pairing_and_grace_separation() {
        let rule = AttendanceRule {
            id: Uuid::now_v7(),
            organization_id: Uuid::now_v7(),
            name: "General Shift".into(),
            shift_start_time: NaiveTime::from_hms_opt(9, 0, 0).unwrap(),
            shift_end_time: NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
            grace_period_minutes: 15,
            half_day_min_duration_minutes: 240,
            full_day_min_duration_minutes: 420,
            early_exit_threshold_minutes: 15,
            max_single_session_hours: 14,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let t_in = DateTime::parse_from_rfc3339("2026-08-20T09:22:00Z").unwrap().with_timezone(&Utc);
        let t_out = DateTime::parse_from_rfc3339("2026-08-20T17:35:00Z").unwrap().with_timezone(&Utc);

        let punches = vec![
            RawPunchInput { timestamp: t_in, punch_type: PunchType::In },
            RawPunchInput { timestamp: t_out, punch_type: PunchType::Out },
        ];

        let sessions = pair_sessions(&punches, &PunchInterpretationMode::ExplicitDirection);
        assert_eq!(sessions.len(), 1);
        assert_eq!(sessions[0].duration_minutes, 493);

        let (status, start_delay, late_after_grace, early_exit) = evaluate_attendance_status(
            &rule,
            NaiveDate::from_ymd_opt(2026, 8, 20).unwrap(),
            Some(t_in),
            Some(t_out),
            sessions[0].duration_minutes,
            false,
        );

        assert_eq!(start_delay, 22);
        assert_eq!(late_after_grace, 7);
        assert_eq!(early_exit, 0);
        assert_eq!(status, AttendanceStatus::Late);
    }

    #[test]
    fn test_deduplicate_jitter_punches() {
        let t1 = DateTime::parse_from_rfc3339("2026-08-20T09:00:00Z").unwrap().with_timezone(&Utc);
        let t2 = DateTime::parse_from_rfc3339("2026-08-20T09:00:15Z").unwrap().with_timezone(&Utc); // 15s jitter
        let t3 = DateTime::parse_from_rfc3339("2026-08-20T17:00:00Z").unwrap().with_timezone(&Utc);

        let punches = vec![
            RawPunchInput { timestamp: t1, punch_type: PunchType::In },
            RawPunchInput { timestamp: t2, punch_type: PunchType::In },
            RawPunchInput { timestamp: t3, punch_type: PunchType::Out },
        ];

        let deduplicated = deduplicate_punches(&punches, 60);
        assert_eq!(deduplicated.len(), 2);
        assert_eq!(deduplicated[0].timestamp, t1);
        assert_eq!(deduplicated[1].timestamp, t3);
    }
}
