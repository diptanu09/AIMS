use aims_common::{AimsError, Result};
use aims_domain::{AttendanceCorrection, AttendanceStatus};
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

pub struct CorrectionRepository;

impl CorrectionRepository {
    pub async fn create(
        pool: &PgPool,
        attendance_daily_id: Uuid,
        requested_by: Uuid,
        original_first_in: Option<DateTime<Utc>>,
        original_last_out: Option<DateTime<Utc>>,
        original_status: AttendanceStatus,
        corrected_first_in: Option<DateTime<Utc>>,
        corrected_last_out: Option<DateTime<Utc>>,
        corrected_status: AttendanceStatus,
        reason: &str,
    ) -> Result<AttendanceCorrection> {
        let correction = sqlx::query_as::<_, AttendanceCorrection>(
            r#"
            INSERT INTO attendance_corrections (
                attendance_daily_id, requested_by, original_first_in, original_last_out,
                original_status, corrected_first_in, corrected_last_out, corrected_status, reason
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING id, attendance_daily_id, requested_by, original_first_in, original_last_out,
                      original_status, corrected_first_in, corrected_last_out,
                      corrected_status, reason, status, approved_by, approved_at, rejection_reason, created_at
            "#
        )
        .bind(attendance_daily_id)
        .bind(requested_by)
        .bind(original_first_in)
        .bind(original_last_out)
        .bind(original_status)
        .bind(corrected_first_in)
        .bind(corrected_last_out)
        .bind(corrected_status)
        .bind(reason)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert attendance correction: {}", e)))?;

        Ok(correction)
    }
}
