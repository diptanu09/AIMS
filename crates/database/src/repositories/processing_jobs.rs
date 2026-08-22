use aims_common::{AimsError, Result};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct AttendanceProcessingJobRecord {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub requested_by: Uuid,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub employee_id: Option<Uuid>,
    pub section_id: Option<Uuid>,
    pub status: String,
    pub total_days: i32,
    pub processed_days: i32,
    pub failed_days: i32,
    pub error_message: Option<String>,
    pub created_at: DateTime<Utc>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
}

pub struct ProcessingJobRepository;

impl ProcessingJobRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        requested_by: Uuid,
        start_date: NaiveDate,
        end_date: NaiveDate,
        employee_id: Option<Uuid>,
        section_id: Option<Uuid>,
        total_days: i32,
    ) -> Result<AttendanceProcessingJobRecord> {
        let rec = sqlx::query_as!(
            AttendanceProcessingJobRecord,
            r#"
            INSERT INTO attendance_processing_jobs
                (id, organization_id, requested_by, start_date, end_date, employee_id, section_id, total_days)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING
                id, organization_id, requested_by, start_date, end_date, employee_id, section_id,
                status, total_days, processed_days, failed_days, error_message, created_at, started_at, completed_at
            "#,
            Uuid::now_v7(),
            organization_id,
            requested_by,
            start_date,
            end_date,
            employee_id,
            section_id,
            total_days
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        Ok(rec)
    }

    pub async fn find_by_id(
        pool: &PgPool,
        id: Uuid,
    ) -> Result<Option<AttendanceProcessingJobRecord>> {
        let rec = sqlx::query_as!(
            AttendanceProcessingJobRecord,
            r#"
            SELECT
                id, organization_id, requested_by, start_date, end_date, employee_id, section_id,
                status, total_days, processed_days, failed_days, error_message, created_at, started_at, completed_at
            FROM attendance_processing_jobs
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        Ok(rec)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<AttendanceProcessingJobRecord>> {
        let recs = sqlx::query_as!(
            AttendanceProcessingJobRecord,
            r#"
            SELECT
                id, organization_id, requested_by, start_date, end_date, employee_id, section_id,
                status, total_days, processed_days, failed_days, error_message, created_at, started_at, completed_at
            FROM attendance_processing_jobs
            WHERE organization_id = $1
            ORDER BY created_at DESC
            LIMIT 50
            "#,
            organization_id
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        Ok(recs)
    }

    pub async fn update_progress(
        pool: &PgPool,
        id: Uuid,
        status: &str,
        processed_days: i32,
        failed_days: i32,
        error_message: Option<&str>,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE attendance_processing_jobs
            SET status = $2::VARCHAR,
                processed_days = $3,
                failed_days = $4,
                error_message = $5,
                started_at = CASE WHEN $2::VARCHAR = 'RUNNING' THEN COALESCE(started_at, CURRENT_TIMESTAMP) ELSE started_at END,
                completed_at = CASE WHEN $2::VARCHAR IN ('COMPLETED', 'FAILED') THEN CURRENT_TIMESTAMP ELSE completed_at END
            WHERE id = $1
            "#,
            id,
            status,
            processed_days,
            failed_days,
            error_message
        )
        .execute(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        Ok(())
    }
}
