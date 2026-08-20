use aims_common::{AimsError, Result};
use chrono::{DateTime, Utc};
use serde_json::Value;
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow)]
pub struct AuditLogRecord {
    pub id: Uuid,
    pub user_id: Option<Uuid>,
    pub action: String,
    pub entity_name: String,
    pub entity_id: Option<Uuid>,
    pub old_value: Option<Value>,
    pub new_value: Option<Value>,
    pub client_ip: Option<String>,
    pub created_at: DateTime<Utc>,
}

pub struct AuditLogRepository;

impl AuditLogRepository {
    pub async fn log(
        pool: &PgPool,
        user_id: Option<Uuid>,
        action: &str,
        entity_name: &str,
        entity_id: Option<Uuid>,
        old_value: Option<Value>,
        new_value: Option<Value>,
        client_ip: Option<&str>,
    ) -> Result<AuditLogRecord> {
        let entry = sqlx::query_as::<_, AuditLogRecord>(
            r#"
            INSERT INTO audit_logs (
                user_id, action, entity_name, entity_id, old_value, new_value, client_ip
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, user_id, action, entity_name, entity_id, old_value, new_value, client_ip, created_at
            "#
        )
        .bind(user_id)
        .bind(action)
        .bind(entity_name)
        .bind(entity_id)
        .bind(old_value)
        .bind(new_value)
        .bind(client_ip)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to record audit log: {}", e)))?;

        Ok(entry)
    }
}
