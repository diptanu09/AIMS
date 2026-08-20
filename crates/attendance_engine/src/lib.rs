use aims_common::Result;
use aims_domain::{AttendanceDaily, AttendanceRule, AttendanceStatus, Employee, PunchInterpretationMode, PunchType};
use chrono::{DateTime, NaiveDate, NaiveDateTime, Utc};
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct RawPunchInput {
    pub punch_timestamp: DateTime<Utc>,
    pub punch_type: PunchType,
}

#[derive(Debug, Clone)]
pub struct CalculationResult {
    pub daily: AttendanceDaily,
    pub sessions: Vec<AttendanceSessionCalculated>,
}

#[derive(Debug, Clone)]
pub struct AttendanceSessionCalculated {
    pub in_timestamp: DateTime<Utc>,
    pub out_timestamp: Option<DateTime<Utc>>,
    pub duration_minutes: i32,
    pub session_order: i32,
    pub is_inferred: bool,
}

pub struct AttendanceCalculator;

impl AttendanceCalculator {
    pub fn calculate_day(
        employee: &Employee,
        rule: &AttendanceRule,
        attendance_date: NaiveDate,
        mode: PunchInterpretationMode,
        is_holiday: bool,
        is_leave: bool,
        is_weekly_off: bool,
        mut raw_punches: Vec<RawPunchInput>,
    ) -> Result<CalculationResult> {
        let daily_id = Uuid::now_v7();

        // 1. Calendar overrides priority (HOLIDAY > LEAVE > WEEKLY_OFF)
        if is_holiday {
            return Ok(Self::create_override_result(daily_id, employee, attendance_date, AttendanceStatus::Holiday));
        }
        if is_leave {
            return Ok(Self::create_override_result(daily_id, employee, attendance_date, AttendanceStatus::Leave));
        }
        if is_weekly_off {
            return Ok(Self::create_override_result(daily_id, employee, attendance_date, AttendanceStatus::WeeklyOff));
        }

        // 2. Sort punches chronologically and deduplicate (60s threshold)
        raw_punches.sort_by_key(|p| p.punch_timestamp);
        let mut clean_punches: Vec<RawPunchInput> = Vec::new();
        for p in raw_punches {
            if let Some(last) = clean_punches.last() {
                if (p.punch_timestamp - last.punch_timestamp).num_seconds() < 60 {
                    continue; // Skip duplicate punch within 60s
                }
            }
            clean_punches.push(p);
        }

        // 3. Absence check (zero logs recorded)
        if clean_punches.is_empty() {
            return Ok(Self::create_override_result(daily_id, employee, attendance_date, AttendanceStatus::Absent));
        }

        // 4. Session Pairing Logic (Construct valid IN->OUT pairs per configured interpretation mode)
        let mut sessions: Vec<AttendanceSessionCalculated> = Vec::new();
        let mut total_duty_minutes = 0;
        let mut is_incomplete = false;

        match mode {
            PunchInterpretationMode::ExplicitDirection | PunchInterpretationMode::SessionPairingHeuristic => {
                let mut current_in: Option<DateTime<Utc>> = None;

                for (_idx, p) in clean_punches.iter().enumerate() {
                    match p.punch_type {
                        PunchType::In => {
                            if let Some(prev_in) = current_in {
                                // Double IN without OUT: Push unclosed session
                                sessions.push(AttendanceSessionCalculated {
                                    in_timestamp: prev_in,
                                    out_timestamp: None,
                                    duration_minutes: 0,
                                    session_order: sessions.len() as i32 + 1,
                                    is_inferred: true,
                                });
                                is_incomplete = true;
                            }
                            current_in = Some(p.punch_timestamp);
                        }
                        PunchType::Out => {
                            if let Some(prev_in) = current_in {
                                let duration = (p.punch_timestamp - prev_in).num_minutes() as i32;
                                total_duty_minutes += duration;
                                sessions.push(AttendanceSessionCalculated {
                                    in_timestamp: prev_in,
                                    out_timestamp: Some(p.punch_timestamp),
                                    duration_minutes: duration,
                                    session_order: sessions.len() as i32 + 1,
                                    is_inferred: false,
                                });
                                current_in = None;
                            } else {
                                // Orphan OUT punch
                                is_incomplete = true;
                            }
                        }
                        PunchType::Unknown => {
                            // Fallback alternating or single punch logic
                            if let Some(prev_in) = current_in {
                                let duration = (p.punch_timestamp - prev_in).num_minutes() as i32;
                                total_duty_minutes += duration;
                                sessions.push(AttendanceSessionCalculated {
                                    in_timestamp: prev_in,
                                    out_timestamp: Some(p.punch_timestamp),
                                    duration_minutes: duration,
                                    session_order: sessions.len() as i32 + 1,
                                    is_inferred: true,
                                });
                                current_in = None;
                            } else {
                                current_in = Some(p.punch_timestamp);
                            }
                        }
                    }
                }

                // Handle remaining unclosed IN punch
                if let Some(remaining_in) = current_in {
                    sessions.push(AttendanceSessionCalculated {
                        in_timestamp: remaining_in,
                        out_timestamp: None,
                        duration_minutes: 0,
                        session_order: sessions.len() as i32 + 1,
                        is_inferred: true,
                    });
                    is_incomplete = true;
                }
            }

            PunchInterpretationMode::AlternatingPunches | PunchInterpretationMode::DeviceStateBased => {
                let chunks = clean_punches.chunks(2);
                for (idx, chunk) in chunks.enumerate() {
                    let in_ts = chunk[0].punch_timestamp;
                    if chunk.len() == 2 {
                        let out_ts = chunk[1].punch_timestamp;
                        let duration = (out_ts - in_ts).num_minutes() as i32;
                        total_duty_minutes += duration;
                        sessions.push(AttendanceSessionCalculated {
                            in_timestamp: in_ts,
                            out_timestamp: Some(out_ts),
                            duration_minutes: duration,
                            session_order: (idx + 1) as i32,
                            is_inferred: false,
                        });
                    } else {
                        sessions.push(AttendanceSessionCalculated {
                            in_timestamp: in_ts,
                            out_timestamp: None,
                            duration_minutes: 0,
                            session_order: (idx + 1) as i32,
                            is_inferred: true,
                        });
                        is_incomplete = true;
                    }
                }
            }
        }

        // 5. Derive Summary `first_in` and `last_out` from valid constructed sessions
        let first_in = sessions.first().map(|s| s.in_timestamp);
        let last_out = sessions.iter().filter_map(|s| s.out_timestamp).last();

        // 6. Punctuality & Early Exit Calculations (v1.1: Separating shift-start vs grace)
        let expected_shift_start = NaiveDateTime::new(attendance_date, rule.shift_start_time).and_utc();
        let expected_shift_end = NaiveDateTime::new(attendance_date, rule.shift_end_time).and_utc();

        let (minutes_after_shift_start, late_after_grace_minutes) = if let Some(in_time) = first_in {
            if in_time > expected_shift_start {
                let total_delay = (in_time - expected_shift_start).num_minutes() as i32;
                let late_grace = if total_delay > rule.grace_period_minutes {
                    total_delay - rule.grace_period_minutes
                } else {
                    0
                };
                (total_delay, late_grace)
            } else {
                (0, 0)
            }
        } else {
            (0, 0)
        };

        let early_exit_cutoff = expected_shift_end - chrono::Duration::minutes(rule.early_exit_threshold_minutes as i64);
        let early_exit_minutes = if let Some(out_time) = last_out {
            if out_time < early_exit_cutoff {
                (expected_shift_end - out_time).num_minutes() as i32
            } else {
                0
            }
        } else {
            0
        };

        // 7. Status Precedence Evaluation
        let status = if is_incomplete {
            AttendanceStatus::Incomplete
        } else if total_duty_minutes < rule.half_day_min_duration_minutes {
            AttendanceStatus::Absent
        } else if total_duty_minutes < rule.full_day_min_duration_minutes {
            AttendanceStatus::HalfDay
        } else if late_after_grace_minutes > 0 && early_exit_minutes > 0 {
            AttendanceStatus::LateAndEarlyExit
        } else if late_after_grace_minutes > 0 {
            AttendanceStatus::Late
        } else if early_exit_minutes > 0 {
            AttendanceStatus::EarlyExit
        } else {
            AttendanceStatus::Present
        };

        let daily = AttendanceDaily {
            id: daily_id,
            organization_id: employee.organization_id,
            employee_id: employee.id,
            section_id: employee.section_id,
            attendance_date,
            first_in,
            last_out,
            total_duty_minutes,
            minutes_after_shift_start,
            late_after_grace_minutes,
            early_exit_minutes,
            status,
            is_corrected: false,
            processed_at: Utc::now(),
        };

        Ok(CalculationResult { daily, sessions })
    }

    fn create_override_result(
        daily_id: Uuid,
        employee: &Employee,
        attendance_date: NaiveDate,
        status: AttendanceStatus,
    ) -> CalculationResult {
        let daily = AttendanceDaily {
            id: daily_id,
            organization_id: employee.organization_id,
            employee_id: employee.id,
            section_id: employee.section_id,
            attendance_date,
            first_in: None,
            last_out: None,
            total_duty_minutes: 0,
            minutes_after_shift_start: 0,
            late_after_grace_minutes: 0,
            early_exit_minutes: 0,
            status,
            is_corrected: false,
            processed_at: Utc::now(),
        };

        CalculationResult { daily, sessions: Vec::new() }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use aims_domain::EmployeeStatus;
    use chrono::NaiveTime;

    #[test]
    fn test_v1_1_session_pairing_and_grace_separation() {
        let org_id = Uuid::new_v4();
        let sec_id = Uuid::new_v4();
        let rule_id = Uuid::new_v4();
        let des_id = Uuid::new_v4();
        let emp_id = Uuid::new_v4();

        let rule = AttendanceRule {
            id: rule_id,
            organization_id: org_id,
            name: "Standard Shift".into(),
            shift_start_time: NaiveTime::from_hms_opt(9, 30, 0).unwrap(),
            shift_end_time: NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
            grace_period_minutes: 15,
            half_day_min_duration_minutes: 240,
            full_day_min_duration_minutes: 420,
            early_exit_threshold_minutes: 15,
            max_single_session_hours: 14,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let employee = Employee {
            id: emp_id,
            organization_id: org_id,
            employee_code: "EMP001".into(),
            attendance_device_user_id: "DEV001".into(),
            first_name: "John".into(),
            last_name: "Doe".into(),
            email: None,
            mobile: None,
            section_id: sec_id,
            designation_id: des_id,
            attendance_rule_id: rule_id,
            joining_date: NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
            leaving_date: None,
            status: EmployeeStatus::Active,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let date = NaiveDate::from_ymd_opt(2026, 8, 20).unwrap();
        // Employee arrives at 09:50 (20 min after start, 5 min after grace period)
        let punches = vec![
            RawPunchInput { punch_timestamp: NaiveDateTime::new(date, NaiveTime::from_hms_opt(9, 50, 0).unwrap()).and_utc(), punch_type: PunchType::In },
            RawPunchInput { punch_timestamp: NaiveDateTime::new(date, NaiveTime::from_hms_opt(17, 35, 0).unwrap()).and_utc(), punch_type: PunchType::Out },
        ];

        let res = AttendanceCalculator::calculate_day(
            &employee, &rule, date, PunchInterpretationMode::ExplicitDirection, false, false, false, punches
        ).unwrap();

        assert_eq!(res.daily.status, AttendanceStatus::Late);
        assert_eq!(res.daily.minutes_after_shift_start, 20);
        assert_eq!(res.daily.late_after_grace_minutes, 5);
        assert_eq!(res.sessions.len(), 1);
        assert_eq!(res.sessions[0].is_inferred, false);
    }
}
