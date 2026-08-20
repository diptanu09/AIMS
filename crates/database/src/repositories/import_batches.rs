use aims_common::{AimsError, Result};
use aims_domain::ImportBatchStatus;
use chrono::{DateTime, Utc};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow)]
pub struct ImportBatchRecord {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub file_name: String,
    pub file_hash: String,
    pub uploaded_by: Uuid,
    pub total_records: i32,
    pub valid_records: i32,
    pub duplicate_records: i32,
    pub unknown_employees: i32,
    pub invalid_records: i32,
    pub status: ImportBatchStatus,
    pub imported_at: DateTime<Utc>,
}

pub struct ImportBatchRepository;

impl ImportBatchRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        file_name: &str,
        file_hash: &str,
        uploaded_by: Uuid,
    ) -> Result<ImportBatchRecord> {
        let batch = sqlx::query_as::<_, ImportBatchRecord>(
            r#"
            INSERT INTO attendance_import_batches (
                organization_id, file_name, file_hash, uploaded_by, status
            )
            VALUES ($1, $2, $3, $4, 'PENDING')
            RETURNING id, organization_id, file_name, file_hash, uploaded_by,
                      total_records, valid_records, duplicate_records,
                      unknown_employees, invalid_records, status, imported_at
            "#
        )
        .bind(organization_id)
        .bind(file_name)
        .bind(file_hash)
        .bind(uploaded_by)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert import batch: {}", e)))?;

        Ok(batch)
    }
}
