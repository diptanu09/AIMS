use aims_common::{AimsError, Result};
use aims_domain::ImportBatchStatus;
use chrono::{DateTime, Utc};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow, serde::Serialize)]
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
            "#,
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

    pub async fn update_stats(
        pool: &PgPool,
        batch_id: Uuid,
        total: i32,
        valid: i32,
        duplicate: i32,
        unknown: i32,
        invalid: i32,
        status: ImportBatchStatus,
    ) -> Result<()> {
        sqlx::query(
            r#"
            UPDATE attendance_import_batches
            SET total_records = $1,
                valid_records = $2,
                duplicate_records = $3,
                unknown_employees = $4,
                invalid_records = $5,
                status = $6
            WHERE id = $7
            "#,
        )
        .bind(total)
        .bind(valid)
        .bind(duplicate)
        .bind(unknown)
        .bind(invalid)
        .bind(status)
        .bind(batch_id)
        .execute(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to update import batch stats: {}", e)))?;

        Ok(())
    }

    pub async fn find_by_file_hash(
        pool: &PgPool,
        organization_id: Uuid,
        file_hash: &str,
    ) -> Result<Option<ImportBatchRecord>> {
        let batch = sqlx::query_as::<_, ImportBatchRecord>(
            r#"
            SELECT id, organization_id, file_name, file_hash, uploaded_by,
                   total_records, valid_records, duplicate_records,
                   unknown_employees, invalid_records, status, imported_at
            FROM attendance_import_batches
            WHERE organization_id = $1 AND file_hash = $2 AND status != 'FAILED'
            "#,
        )
        .bind(organization_id)
        .bind(file_hash)
        .fetch_optional(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to query import batch by file hash: {}", e))
        })?;

        Ok(batch)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<ImportBatchRecord>> {
        let batches = sqlx::query_as::<_, ImportBatchRecord>(
            r#"
            SELECT id, organization_id, file_name, file_hash, uploaded_by,
                   total_records, valid_records, duplicate_records,
                   unknown_employees, invalid_records, status, imported_at
            FROM attendance_import_batches
            WHERE organization_id = $1
            ORDER BY imported_at DESC
            "#,
        )
        .bind(organization_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list import batches: {}", e)))?;

        Ok(batches)
    }

    pub async fn find_by_id(pool: &PgPool, batch_id: Uuid) -> Result<Option<ImportBatchRecord>> {
        let batch = sqlx::query_as::<_, ImportBatchRecord>(
            r#"
            SELECT id, organization_id, file_name, file_hash, uploaded_by,
                   total_records, valid_records, duplicate_records,
                   unknown_employees, invalid_records, status, imported_at
            FROM attendance_import_batches
            WHERE id = $1
            "#,
        )
        .bind(batch_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query import batch: {}", e)))?;

        Ok(batch)
    }
}
