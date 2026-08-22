use aims_common::{AimsError, Result};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Holiday {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub holiday_date: NaiveDate,
    pub name: String,
    pub description: Option<String>,
    pub is_optional: bool,
    pub created_at: DateTime<Utc>,
}

pub struct HolidayRepository;

impl HolidayRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        holiday_date: NaiveDate,
        name: &str,
        description: Option<&str>,
        is_optional: bool,
    ) -> Result<Holiday> {
        let rec = sqlx::query_as!(
            Holiday,
            r#"
            INSERT INTO holidays (organization_id, holiday_date, name, description, is_optional)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, organization_id, holiday_date, name, description, is_optional, created_at
            "#,
            organization_id,
            holiday_date,
            name,
            description,
            is_optional
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to create holiday: {}", e)))?;

        Ok(rec)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<Holiday>> {
        let recs = sqlx::query_as!(
            Holiday,
            r#"
            SELECT id, organization_id, holiday_date, name, description, is_optional, created_at
            FROM holidays
            WHERE organization_id = $1
            ORDER BY holiday_date ASC
            "#,
            organization_id
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list holidays: {}", e)))?;

        Ok(recs)
    }
}
