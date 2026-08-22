use aims_domain::AttendanceRule;
use chrono::{DateTime, Timelike, Utc};
use chrono_tz::Asia::Kolkata;

pub struct PunctualityResult {
    pub late_minutes: i32,
    pub late_minutes_beyond_grace: i32,
    pub is_late: bool,
}

pub fn calculate_lateness(
    first_in: Option<DateTime<Utc>>,
    rule: &AttendanceRule,
) -> PunctualityResult {
    let Some(utc_in) = first_in else {
        return PunctualityResult {
            late_minutes: 0,
            late_minutes_beyond_grace: 0,
            is_late: false,
        };
    };

    let local_in = utc_in.with_timezone(&Kolkata);
    let in_time = local_in.time();

    let shift_start_mins =
        (rule.shift_start_time.hour() * 60 + rule.shift_start_time.minute()) as i32;
    let in_mins = (in_time.hour() * 60 + in_time.minute()) as i32;

    let diff = in_mins - shift_start_mins;

    if diff > rule.grace_period_minutes {
        let beyond = diff - rule.grace_period_minutes;
        PunctualityResult {
            late_minutes: diff,
            late_minutes_beyond_grace: beyond,
            is_late: true,
        }
    } else if diff > 0 {
        PunctualityResult {
            late_minutes: diff,
            late_minutes_beyond_grace: 0,
            is_late: false,
        }
    } else {
        PunctualityResult {
            late_minutes: 0,
            late_minutes_beyond_grace: 0,
            is_late: false,
        }
    }
}

pub fn calculate_early_exit(last_out: Option<DateTime<Utc>>, rule: &AttendanceRule) -> (i32, bool) {
    let Some(utc_out) = last_out else {
        return (0, false);
    };

    let local_out = utc_out.with_timezone(&Kolkata);
    let out_time = local_out.time();

    let shift_end_mins = (rule.shift_end_time.hour() * 60 + rule.shift_end_time.minute()) as i32;
    let out_mins = (out_time.hour() * 60 + out_time.minute()) as i32;

    let diff = shift_end_mins - out_mins;

    if diff > rule.early_exit_threshold_minutes {
        (diff, true)
    } else {
        (0, false)
    }
}
