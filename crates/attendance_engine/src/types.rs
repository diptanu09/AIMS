use aims_domain::{AttendanceStatus, PunchType};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum PunchSourceMode {
    ExplicitDirection,
    Alternating,
    DeviceState,
    Inferred,
}

#[derive(Debug, Clone)]
pub struct AttendancePunch {
    pub id: Uuid,
    pub employee_id: Uuid,
    pub timestamp: DateTime<Utc>,
    pub punch_type: PunchType,
    pub source_mode: PunchSourceMode,
    pub terminal_id: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum CalendarStatus {
    WorkingDay,
    Holiday,
    WeeklyOff,
    Leave,
    OnDuty,
    Exempted,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalendarContext {
    pub status: CalendarStatus,
    pub holiday_name: Option<String>,
    pub leave_type: Option<String>,
}

impl Default for CalendarContext {
    fn default() -> Self {
        Self {
            status: CalendarStatus::WorkingDay,
            holiday_name: None,
            leave_type: None,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum AttendanceWarning {
    DuplicateCandidate,
    UnknownPunchDirection,
    InvalidPunchSequence,
    MissingIn,
    MissingOut,
    ExcessiveSessionDuration,
    MultipleUnexpectedPunches,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttendanceSessionResult {
    pub session_number: i32,
    pub check_in: DateTime<Utc>,
    pub check_out: Option<DateTime<Utc>>,
    pub duration_minutes: i32,
    pub is_inferred: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttendanceDailyResult {
    pub organization_id: Uuid,
    pub employee_id: Uuid,
    pub attendance_date: NaiveDate,
    pub rule_id: Uuid,
    pub first_in: Option<DateTime<Utc>>,
    pub last_out: Option<DateTime<Utc>>,
    pub total_duty_minutes: i32,
    pub late_minutes: i32,
    pub late_minutes_beyond_grace: i32,
    pub early_exit_minutes: i32,
    pub status: AttendanceStatus,
    pub calendar_status: CalendarStatus,
    pub sessions: Vec<AttendanceSessionResult>,
    pub warnings: Vec<AttendanceWarning>,
    pub calculation_version: String,
}
