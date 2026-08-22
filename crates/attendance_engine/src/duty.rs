use crate::types::AttendanceSessionResult;

pub fn calculate_duty_time(sessions: &[AttendanceSessionResult]) -> i32 {
    sessions
        .iter()
        .filter(|s| s.check_out.is_some())
        .map(|s| s.duration_minutes)
        .sum()
}
