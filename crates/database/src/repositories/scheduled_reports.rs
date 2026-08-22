use aims_common::{AimsError, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct ScheduledReportRecord {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub cron_expression: String,
    pub report_type: String,
    pub section_id: Option<Uuid>,
    pub recipients: serde_json::Value,
    pub is_active: bool,
    pub last_run_at: Option<DateTime<Utc>>,
    pub next_run_at: Option<DateTime<Utc>>,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}

pub struct ScheduledReportRepository;

impl ScheduledReportRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        name: &str,
        cron_expression: &str,
        report_type: &str,
        section_id: Option<Uuid>,
        recipients: serde_json::Value,
        created_by: Option<Uuid>,
    ) -> Result<ScheduledReportRecord> {
        let record = sqlx::query_as::<_, ScheduledReportRecord>(
            r#"
            INSERT INTO scheduled_reports (
                organization_id, name, cron_expression, report_type, section_id, recipients, created_by
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, organization_id, name, cron_expression, report_type, section_id,
                      recipients, is_active, last_run_at, next_run_at, created_by, created_at
            "#
        )
        .bind(organization_id)
        .bind(name)
        .bind(cron_expression)
        .bind(report_type)
        .bind(section_id)
        .bind(recipients)
        .bind(created_by)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        Ok(record)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<ScheduledReportRecord>> {
        let records = sqlx::query_as::<_, ScheduledReportRecord>(
            r#"
            SELECT id, organization_id, name, cron_expression, report_type, section_id,
                   recipients, is_active, last_run_at, next_run_at, created_by, created_at
            FROM scheduled_reports
            WHERE organization_id = $1
            ORDER BY created_at DESC
            "#
        )
        .bind(organization_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        Ok(records)
    }
}
