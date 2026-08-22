use aims_common::{AimsError, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct ImportTemplateRecord {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub file_type: String,
    pub delimiter: String,
    pub header_row_index: i32,
    pub column_mapping: Value,
    pub date_format: String,
    pub time_format: String,
    pub interpretation_mode: String,
    pub active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

pub struct ImportTemplateRepository;

impl ImportTemplateRepository {
    #[allow(clippy::too_many_arguments)]
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        name: &str,
        description: Option<&str>,
        file_type: &str,
        delimiter: &str,
        header_row_index: i32,
        column_mapping: &Value,
        date_format: &str,
        time_format: &str,
        interpretation_mode: &str,
    ) -> Result<ImportTemplateRecord> {
        let tpl = sqlx::query_as::<_, ImportTemplateRecord>(
            r#"
            INSERT INTO import_templates (
                organization_id, name, description, file_type, delimiter,
                header_row_index, column_mapping, date_format, time_format,
                interpretation_mode, employee_code_column, punch_time_column
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, '', '')
            RETURNING id, organization_id, name, description, file_type, delimiter,
                      header_row_index, column_mapping, date_format, time_format,
                      interpretation_mode, active, created_at, updated_at
            "#,
        )
        .bind(organization_id)
        .bind(name)
        .bind(description)
        .bind(file_type)
        .bind(delimiter)
        .bind(header_row_index)
        .bind(column_mapping)
        .bind(date_format)
        .bind(time_format)
        .bind(interpretation_mode)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert import template: {}", e)))?;

        Ok(tpl)
    }

    pub async fn find_by_id(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
    ) -> Result<Option<ImportTemplateRecord>> {
        let tpl = sqlx::query_as::<_, ImportTemplateRecord>(
            r#"
            SELECT id, organization_id, name, description, file_type, delimiter,
                   header_row_index, column_mapping, date_format, time_format,
                   interpretation_mode, active, created_at, updated_at
            FROM import_templates
            WHERE id = $1 AND organization_id = $2
            "#,
        )
        .bind(id)
        .bind(organization_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query import template: {}", e)))?;

        Ok(tpl)
    }

    pub async fn find_by_name(
        pool: &PgPool,
        organization_id: Uuid,
        name: &str,
    ) -> Result<Option<ImportTemplateRecord>> {
        let tpl = sqlx::query_as::<_, ImportTemplateRecord>(
            r#"
            SELECT id, organization_id, name, description, file_type, delimiter,
                   header_row_index, column_mapping, date_format, time_format,
                   interpretation_mode, active, created_at, updated_at
            FROM import_templates
            WHERE organization_id = $1 AND name = $2
            "#,
        )
        .bind(organization_id)
        .bind(name)
        .fetch_optional(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to query import template by name: {}", e))
        })?;

        Ok(tpl)
    }

    pub async fn list_active_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<ImportTemplateRecord>> {
        let tpls = sqlx::query_as::<_, ImportTemplateRecord>(
            r#"
            SELECT id, organization_id, name, description, file_type, delimiter,
                   header_row_index, column_mapping, date_format, time_format,
                   interpretation_mode, active, created_at, updated_at
            FROM import_templates
            WHERE organization_id = $1 AND active = TRUE
            ORDER BY name ASC
            "#,
        )
        .bind(organization_id)
        .fetch_all(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to list active import templates: {}", e))
        })?;

        Ok(tpls)
    }

    pub async fn list_all_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<ImportTemplateRecord>> {
        let tpls = sqlx::query_as::<_, ImportTemplateRecord>(
            r#"
            SELECT id, organization_id, name, description, file_type, delimiter,
                   header_row_index, column_mapping, date_format, time_format,
                   interpretation_mode, active, created_at, updated_at
            FROM import_templates
            WHERE organization_id = $1
            ORDER BY name ASC
            "#,
        )
        .bind(organization_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list import templates: {}", e)))?;

        Ok(tpls)
    }
}
