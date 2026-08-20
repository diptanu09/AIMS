use aims_common::{AimsError, Result};
use aims_domain::{AttendanceRawEvent, PunchType};
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

pub struct RawEventRepository;

impl RawEventRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        batch_id: Uuid,
        source_row_number: i32,
        attendance_device_user_id: &str,
        employee_id: Option<Uuid>,
        punch_timestamp: DateTime<Utc>,
        punch_type: PunchType,
        device_terminal_id: Option<&str>,
        event_fingerprint: &str,
        raw_text: Option<&str>,
    ) -> Result<AttendanceRawEvent> {
        let event = sqlx::query_as::<_, AttendanceRawEvent>(
            r#"
            INSERT INTO attendance_raw_events (
                organization_id, batch_id, source_row_number,
                attendance_device_user_id, employee_id, punch_timestamp,
                punch_type, device_terminal_id, event_fingerprint, raw_text
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING id, organization_id, batch_id, source_row_number,
                      attendance_device_user_id, employee_id, punch_timestamp,
                      punch_type, device_terminal_id, event_fingerprint,
                      raw_text, created_at
            "#
        )
        .bind(organization_id)
        .bind(batch_id)
        .bind(source_row_number)
        .bind(attendance_device_user_id)
        .bind(employee_id)
        .bind(punch_timestamp)
        .bind(punch_type)
        .bind(device_terminal_id)
        .bind(event_fingerprint)
        .bind(raw_text)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert raw punch event: {}", e)))?;

        Ok(event)
    }
}
