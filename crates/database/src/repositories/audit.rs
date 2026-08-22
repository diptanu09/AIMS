use aims_common::{AimsError, Result};
use chrono::{DateTime, Utc};
use serde_json::Value;
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow)]
pub struct AuditLogRecord {
    pub id: Uuid,
    pub organization_id: Option<Uuid>,
    pub user_id: Option<Uuid>,
    pub action: String,
    pub entity_name: String,
    pub entity_id: Option<Uuid>,
    pub old_value: Option<Value>,
    pub new_value: Option<Value>,
    pub client_ip: Option<String>,
    pub user_agent: Option<String>,
    pub created_at: DateTime<Utc>,
}

pub struct AuditLogRepository;

impl AuditLogRepository {
    pub async fn log(
        pool: &PgPool,
        organization_id: Option<Uuid>,
        user_id: Option<Uuid>,
        action: &str,
        entity_name: &str,
        entity_id: Option<Uuid>,
        old_value: Option<Value>,
        new_value: Option<Value>,
        client_ip: Option<&str>,
        user_agent: Option<&str>,
    ) -> Result<AuditLogRecord> {
        let entry = sqlx::query_as::<_, AuditLogRecord>(
            r#"
            INSERT INTO audit_logs (
                organization_id, user_id, action, entity_name, entity_id, old_value, new_value, client_ip, user_agent
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING id, organization_id, user_id, action, entity_name, entity_id, old_value, new_value, client_ip, user_agent, created_at
            "#
        )
        .bind(organization_id)
        .bind(user_id)
        .bind(action)
        .bind(entity_name)
        .bind(entity_id)
        .bind(old_value)
        .bind(new_value)
        .bind(client_ip)
        .bind(user_agent)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to record audit log: {}", e)))?;

        Ok(entry)
    }
}
