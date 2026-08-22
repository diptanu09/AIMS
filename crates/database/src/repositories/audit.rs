use aims_common::{AimsError, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DetailedAuditLogRecord {
    pub id: Uuid,
    pub organization_id: Option<Uuid>,
    pub user_id: Option<Uuid>,
    pub username: Option<String>,
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

    pub async fn list_recent(
        pool: &PgPool,
        organization_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<DetailedAuditLogRecord>> {
        let rows = sqlx::query!(
            r#"
            SELECT
                a.id,
                a.organization_id,
                a.user_id,
                u.username AS "username?",
                a.action,
                a.entity_name,
                a.entity_id,
                a.old_value,
                a.new_value,
                a.client_ip,
                a.user_agent,
                a.created_at
            FROM audit_logs a
            LEFT JOIN users u ON a.user_id = u.id
            WHERE a.organization_id = $1 OR a.organization_id IS NULL
            ORDER BY a.created_at DESC
            LIMIT $2 OFFSET $3
            "#,
            organization_id,
            limit,
            offset
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query audit log: {}", e)))?;

        let items = rows
            .into_iter()
            .map(|r| DetailedAuditLogRecord {
                id: r.id,
                organization_id: r.organization_id,
                user_id: r.user_id,
                username: r.username,
                action: r.action,
                entity_name: r.entity_name,
                entity_id: r.entity_id,
                old_value: r.old_value,
                new_value: r.new_value,
                client_ip: r.client_ip,
                user_agent: r.user_agent,
                created_at: r.created_at,
            })
            .collect();

        Ok(items)
    }
}
