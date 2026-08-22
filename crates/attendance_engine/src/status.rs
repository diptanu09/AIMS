use crate::types::{AttendanceSessionResult, CalendarContext, CalendarStatus};
use aims_domain::{AttendanceRule, AttendanceStatus};

pub fn evaluate_attendance_status(
    total_duty_minutes: i32,
    is_late: bool,
    is_early_exit: bool,
    calendar: &CalendarContext,
    rule: &AttendanceRule,
    sessions: &[AttendanceSessionResult],
) -> AttendanceStatus {
    // 1. Calendar override
    match calendar.status {
        CalendarStatus::Holiday => return AttendanceStatus::Holiday,
        CalendarStatus::WeeklyOff => return AttendanceStatus::WeeklyOff,
        CalendarStatus::Leave => return AttendanceStatus::Leave,
        CalendarStatus::OnDuty => return AttendanceStatus::OnDuty,
        CalendarStatus::Exempted => return AttendanceStatus::Exempted,
        CalendarStatus::WorkingDay => {}
    }

    // 2. No sessions at all -> ABSENT
    if sessions.is_empty() {
        return AttendanceStatus::Absent;
    }

    // 3. Any incomplete session (missing OUT) -> INCOMPLETE
    if sessions.iter().any(|s| s.check_out.is_none()) {
        return AttendanceStatus::Incomplete;
    }

    // 4. Check duty thresholds
    let half_day_min = rule.half_day_min_duration_minutes;
    let full_day_min = rule.full_day_min_duration_minutes;

    if total_duty_minutes < half_day_min {
        AttendanceStatus::Absent
    } else if total_duty_minutes < full_day_min {
        AttendanceStatus::HalfDay
    } else {
        // Full day eligible
        match (is_late, is_early_exit) {
            (true, true) => AttendanceStatus::LateAndEarlyExit,
            (true, false) => AttendanceStatus::Late,
            (false, true) => AttendanceStatus::EarlyExit,
            (false, false) => AttendanceStatus::Present,
        }
    }
}
