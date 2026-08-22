use crate::types::{AttendancePunch, AttendanceWarning};

pub fn deduplicate_jitter_punches(
    punches: &[AttendancePunch],
    window_seconds: i64,
) -> (Vec<AttendancePunch>, Vec<AttendanceWarning>) {
    let mut sorted = punches.to_vec();
    sorted.sort_by_key(|p| p.timestamp);

    let mut filtered: Vec<AttendancePunch> = Vec::new();
    let mut warnings: Vec<AttendanceWarning> = Vec::new();

    for punch in sorted {
        let is_dup = if let Some(last) = filtered.last() {
            let same_direction = last.punch_type == punch.punch_type;
            let time_diff = (punch.timestamp - last.timestamp).num_seconds();
            same_direction && time_diff >= 0 && time_diff <= window_seconds
        } else {
            false
        };

        if is_dup {
            warnings.push(AttendanceWarning::DuplicateCandidate);
        } else {
            filtered.push(punch);
        }
    }

    (filtered, warnings)
}
