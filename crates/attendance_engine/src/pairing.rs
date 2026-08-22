use crate::types::{AttendancePunch, AttendanceSessionResult, AttendanceWarning};
use aims_domain::{AttendanceRule, PunchType};

pub fn pair_sessions(
    punches: &[AttendancePunch],
    rule: &AttendanceRule,
) -> (Vec<AttendanceSessionResult>, Vec<AttendanceWarning>) {
    let mut sorted = punches.to_vec();
    sorted.sort_by_key(|p| p.timestamp);

    let mut sessions = Vec::new();
    let mut warnings = Vec::new();

    let mut current_in: Option<&AttendancePunch> = None;
    let mut session_num = 1;

    for punch in &sorted {
        match punch.punch_type {
            PunchType::In => {
                if let Some(existing_in) = current_in {
                    // Two consecutive INs without an OUT -> close previous as incomplete warning
                    warnings.push(AttendanceWarning::MissingOut);
                    sessions.push(AttendanceSessionResult {
                        session_number: session_num,
                        check_in: existing_in.timestamp,
                        check_out: None,
                        duration_minutes: 0,
                        is_inferred: existing_in.source_mode
                            != crate::types::PunchSourceMode::ExplicitDirection,
                    });
                    session_num += 1;
                }
                current_in = Some(punch);
            }
            PunchType::Out => {
                if let Some(existing_in) = current_in {
                    let duration = (punch.timestamp - existing_in.timestamp).num_minutes() as i32;
                    let max_dur = rule.max_single_session_hours * 60;

                    if duration < 0 {
                        warnings.push(AttendanceWarning::InvalidPunchSequence);
                    } else {
                        if duration > max_dur {
                            warnings.push(AttendanceWarning::ExcessiveSessionDuration);
                        }

                        sessions.push(AttendanceSessionResult {
                            session_number: session_num,
                            check_in: existing_in.timestamp,
                            check_out: Some(punch.timestamp),
                            duration_minutes: duration.max(0),
                            is_inferred: existing_in.source_mode
                                != crate::types::PunchSourceMode::ExplicitDirection,
                        });
                        session_num += 1;
                    }
                    current_in = None;
                } else {
                    // OUT without prior IN
                    warnings.push(AttendanceWarning::MissingIn);
                }
            }
            PunchType::Unknown => {
                warnings.push(AttendanceWarning::UnknownPunchDirection);
            }
        }
    }

    // Trailing IN without OUT
    if let Some(existing_in) = current_in {
        warnings.push(AttendanceWarning::MissingOut);
        sessions.push(AttendanceSessionResult {
            session_number: session_num,
            check_in: existing_in.timestamp,
            check_out: None,
            duration_minutes: 0,
            is_inferred: existing_in.source_mode
                != crate::types::PunchSourceMode::ExplicitDirection,
        });
    }

    (sessions, warnings)
}
