use aims_common::{AimsError, Result};
use aims_domain::{AttendanceRawEvent, PunchType};
use chrono::{DateTime, NaiveDate, Utc};
use sqlx::PgPool;
use std::collections::HashSet;
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
            "#,
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

    pub async fn create_ignore_duplicate(
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
    ) -> Result<bool> {
        let result = sqlx::query(
            r#"
            INSERT INTO attendance_raw_events (
                organization_id, batch_id, source_row_number,
                attendance_device_user_id, employee_id, punch_timestamp,
                punch_type, device_terminal_id, event_fingerprint, raw_text
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            ON CONFLICT (organization_id, event_fingerprint) DO NOTHING
            "#,
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
        .execute(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert raw punch event: {}", e)))?;

        Ok(result.rows_affected() > 0)
    }

    pub async fn list_fingerprints_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<HashSet<String>> {
        let rows = sqlx::query_scalar::<_, String>(
            r#"
            SELECT event_fingerprint
            FROM attendance_raw_events
            WHERE organization_id = $1
            "#,
        )
        .bind(organization_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query event fingerprints: {}", e)))?;

        Ok(rows.into_iter().collect())
    }

    pub async fn list_by_batch(pool: &PgPool, batch_id: Uuid) -> Result<Vec<AttendanceRawEvent>> {
        let events = sqlx::query_as::<_, AttendanceRawEvent>(
            r#"
            SELECT id, organization_id, batch_id, source_row_number,
                   attendance_device_user_id, employee_id, punch_timestamp,
                   punch_type, device_terminal_id, event_fingerprint,
                   raw_text, created_at
            FROM attendance_raw_events
            WHERE batch_id = $1
            ORDER BY source_row_number ASC
            "#,
        )
        .bind(batch_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list raw events by batch: {}", e)))?;

        Ok(events)
    }

    pub async fn list_by_employee_and_date(
        pool: &PgPool,
        organization_id: Uuid,
        attendance_device_user_id: &str,
        date: NaiveDate,
    ) -> Result<Vec<AttendanceRawEvent>> {
        let events = sqlx::query_as::<_, AttendanceRawEvent>(
            r#"
            SELECT id, organization_id, batch_id, source_row_number,
                   attendance_device_user_id, employee_id, punch_timestamp,
                   punch_type, device_terminal_id, event_fingerprint,
                   raw_text, created_at
            FROM attendance_raw_events
            WHERE organization_id = $1
              AND attendance_device_user_id = $2
              AND (punch_timestamp AT TIME ZONE 'Asia/Kolkata')::date = $3
            ORDER BY punch_timestamp ASC
            "#,
        )
        .bind(organization_id)
        .bind(attendance_device_user_id)
        .bind(date)
        .fetch_all(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!(
                "Failed to query raw events for employee date: {}",
                e
            ))
        })?;

        Ok(events)
    }
}
