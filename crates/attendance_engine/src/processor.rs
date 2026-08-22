use aims_common::Result;
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    attendance_rules::AttendanceRuleRepository,
    attendance_sessions::{AttendanceSessionRecord, AttendanceSessionRepository},
    raw_events::RawEventRepository,
};
use aims_domain::{AttendanceDaily, AttendanceRule, PunchType};
use chrono::{NaiveDate, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::deduplicate::deduplicate_jitter_punches;
use crate::duty::calculate_duty_time;
use crate::pairing::pair_sessions;
use crate::punctuality::{calculate_early_exit, calculate_lateness};
use crate::status::evaluate_attendance_status;
use crate::types::{
    AttendanceDailyResult, AttendancePunch, CalendarContext, CalendarStatus, PunchSourceMode,
};

pub fn calculate_attendance_for_employee_date(
    organization_id: Uuid,
    employee_id: Uuid,
    date: NaiveDate,
    rule: &AttendanceRule,
    calendar: &CalendarContext,
    raw_punches: &[AttendancePunch],
) -> AttendanceDailyResult {
    // 1. Deduplicate jitter punches (e.g. within 60s)
    let (deduped, mut warnings) = deduplicate_jitter_punches(raw_punches, 60);

    // 2. Session pairing
    let (sessions, pairing_warnings) = pair_sessions(&deduped, rule);
    warnings.extend(pairing_warnings);

    // 3. First IN and Last OUT
    let first_in = deduped
        .iter()
        .filter(|p| p.punch_type == PunchType::In)
        .map(|p| p.timestamp)
        .min();

    let last_out = deduped
        .iter()
        .filter(|p| p.punch_type == PunchType::Out)
        .map(|p| p.timestamp)
        .max();

    // 4. Duty calculations
    let total_duty_minutes = calculate_duty_time(&sessions);

    // 5. Punctuality
    let punctuality = calculate_lateness(first_in, rule);
    let (early_exit_minutes, is_early_exit) = calculate_early_exit(last_out, rule);

    // 6. Final Status Evaluation
    let status = evaluate_attendance_status(
        total_duty_minutes,
        punctuality.is_late,
        is_early_exit,
        calendar,
        rule,
        &sessions,
    );

    AttendanceDailyResult {
        organization_id,
        employee_id,
        attendance_date: date,
        rule_id: rule.id,
        first_in,
        last_out,
        total_duty_minutes,
        late_minutes: punctuality.late_minutes,
        late_minutes_beyond_grace: punctuality.late_minutes_beyond_grace,
        early_exit_minutes,
        status,
        calendar_status: calendar.status,
        sessions,
        warnings,
        calculation_version: "1.0".to_string(),
    }
}

pub async fn process_and_persist_employee_date(
    pool: &PgPool,
    organization_id: Uuid,
    employee_id: Uuid,
    section_id: Uuid,
    device_user_id: &str,
    date: NaiveDate,
    rule_id: Uuid,
) -> Result<AttendanceDailyResult> {
    // 1. Load attendance rule
    let rule = AttendanceRuleRepository::find_by_id(pool, organization_id, rule_id)
        .await?
        .ok_or_else(|| aims_common::AimsError::NotFound("Attendance rule not found".into()))?;

    // 2. Load raw events for employee date
    let db_events =
        RawEventRepository::list_by_employee_and_date(pool, organization_id, device_user_id, date)
            .await?;

    let raw_punches: Vec<AttendancePunch> = db_events
        .into_iter()
        .map(|e| AttendancePunch {
            id: e.id,
            employee_id,
            timestamp: e.punch_timestamp,
            punch_type: e.punch_type,
            source_mode: PunchSourceMode::ExplicitDirection,
            terminal_id: e.device_terminal_id,
        })
        .collect();

    let calendar = CalendarContext {
        status: CalendarStatus::WorkingDay,
        holiday_name: None,
        leave_type: None,
    };

    // 3. Perform pure deterministic calculation
    let result = calculate_attendance_for_employee_date(
        organization_id,
        employee_id,
        date,
        &rule,
        &calendar,
        &raw_punches,
    );

    let daily_record = AttendanceDaily {
        id: Uuid::now_v7(),
        organization_id,
        employee_id,
        section_id,
        attendance_date: date,
        first_in: result.first_in,
        last_out: result.last_out,
        total_duty_minutes: result.total_duty_minutes,
        minutes_after_shift_start: result.late_minutes,
        late_after_grace_minutes: result.late_minutes_beyond_grace,
        early_exit_minutes: result.early_exit_minutes,
        status: result.status.clone(),
        is_corrected: false,
        processed_at: Utc::now(),
    };

    // 4. Idempotently save summary into database
    let daily_saved = DailyAttendanceRepository::save(pool, &daily_record).await?;

    // Rebuild sessions for this daily record
    let session_records: Vec<AttendanceSessionRecord> = result
        .sessions
        .iter()
        .map(|s| AttendanceSessionRecord {
            id: Uuid::now_v7(),
            attendance_daily_id: daily_saved.id,
            in_timestamp: s.check_in,
            out_timestamp: s.check_out,
            duration_minutes: s.duration_minutes,
            session_order: s.session_number,
            is_inferred: s.is_inferred,
        })
        .collect();

    AttendanceSessionRepository::replace_sessions_for_daily(pool, daily_saved.id, &session_records)
        .await?;

    Ok(result)
}
