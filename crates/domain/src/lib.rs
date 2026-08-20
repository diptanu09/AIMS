use chrono::{DateTime, NaiveDate, NaiveTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "user_status", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum UserStatus {
    Active,
    Inactive,
    Suspended,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "employee_status", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum EmployeeStatus {
    Active,
    Probation,
    Suspended,
    Resigned,
    Retired,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "import_batch_status", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ImportBatchStatus {
    Pending,
    Processing,
    Completed,
    Failed,
    Partial,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "punch_type", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum PunchType {
    In,
    Out,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum PunchInterpretationMode {
    ExplicitDirection,
    AlternatingPunches,
    DeviceStateBased,
    SessionPairingHeuristic,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "attendance_status", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum AttendanceStatus {
    Present,
    Late,
    Absent,
    HalfDay,
    EarlyExit,
    LateAndEarlyExit,
    Incomplete,
    Holiday,
    WeeklyOff,
    Leave,
    OnDuty,
    Exempted,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "correction_status", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum CorrectionStatus {
    Pending,
    Approved,
    Rejected,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Organization {
    pub id: Uuid,
    pub code: String,
    pub name: String,
    pub timezone: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Section {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub code: String,
    pub name: String,
    pub parent_section_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Designation {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub code: String,
    pub title: String,
    pub level: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AttendanceRule {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub shift_start_time: NaiveTime,
    pub shift_end_time: NaiveTime,
    pub grace_period_minutes: i32,
    pub half_day_min_duration_minutes: i32,
    pub full_day_min_duration_minutes: i32,
    pub early_exit_threshold_minutes: i32,
    pub max_single_session_hours: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Employee {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub employee_code: String,
    pub attendance_device_user_id: String,
    pub first_name: String,
    pub last_name: String,
    pub email: Option<String>,
    pub mobile: Option<String>,
    pub section_id: Uuid,
    pub designation_id: Uuid,
    pub attendance_rule_id: Uuid,
    pub joining_date: NaiveDate,
    pub leaving_date: Option<NaiveDate>,
    pub status: EmployeeStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AttendanceRawEvent {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub batch_id: Uuid,
    pub source_row_number: i32,
    pub attendance_device_user_id: String,
    pub employee_id: Option<Uuid>,
    pub punch_timestamp: DateTime<Utc>,
    pub punch_type: PunchType,
    pub device_terminal_id: Option<String>,
    pub event_fingerprint: String,
    pub raw_text: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AttendanceDaily {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub employee_id: Uuid,
    pub section_id: Uuid,
    pub attendance_date: NaiveDate,
    pub first_in: Option<DateTime<Utc>>,
    pub last_out: Option<DateTime<Utc>>,
    pub total_duty_minutes: i32,
    pub minutes_after_shift_start: i32,
    pub late_after_grace_minutes: i32,
    pub early_exit_minutes: i32,
    pub status: AttendanceStatus,
    pub is_corrected: bool,
    pub processed_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AttendanceCorrection {
    pub id: Uuid,
    pub attendance_daily_id: Uuid,
    pub requested_by: Uuid,
    pub original_first_in: Option<DateTime<Utc>>,
    pub original_last_out: Option<DateTime<Utc>>,
    pub original_status: AttendanceStatus,
    pub corrected_first_in: Option<DateTime<Utc>>,
    pub corrected_last_out: Option<DateTime<Utc>>,
    pub corrected_status: AttendanceStatus,
    pub reason: String,
    pub status: CorrectionStatus,
    pub approved_by: Option<Uuid>,
    pub approved_at: Option<DateTime<Utc>>,
    pub rejection_reason: Option<String>,
    pub created_at: DateTime<Utc>,
}
