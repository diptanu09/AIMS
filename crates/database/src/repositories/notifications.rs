use aims_common::{AimsError, Result};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct NotificationRecord {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub user_id: Uuid,
    pub title: String,
    pub message: String,
    pub alert_type: String,
    pub is_read: bool,
    pub created_at: DateTime<Utc>,
}

pub struct NotificationRepository;

impl NotificationRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        user_id: Uuid,
        title: &str,
        message: &str,
        alert_type: &str,
    ) -> Result<NotificationRecord> {
        let record = sqlx::query_as::<_, NotificationRecord>(
            r#"
            INSERT INTO in_app_notifications (
                organization_id, user_id, title, message, alert_type
            )
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, organization_id, user_id, title, message, alert_type, is_read, created_at
            "#
        )
        .bind(organization_id)
        .bind(user_id)
        .bind(title)
        .bind(message)
        .bind(alert_type)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        Ok(record)
    }

    pub async fn list_unread_for_user(
        pool: &PgPool,
        user_id: Uuid,
        limit: i64,
    ) -> Result<Vec<NotificationRecord>> {
        let records = sqlx::query_as::<_, NotificationRecord>(
            r#"
            SELECT id, organization_id, user_id, title, message, alert_type, is_read, created_at
            FROM in_app_notifications
            WHERE user_id = $1 AND is_read = FALSE
            ORDER BY created_at DESC
            LIMIT $2
            "#
        )
        .bind(user_id)
        .bind(limit)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        Ok(records)
    }

    pub async fn mark_read(
        pool: &PgPool,
        notification_id: Uuid,
        user_id: Uuid,
    ) -> Result<()> {
        sqlx::query(
            r#"
            UPDATE in_app_notifications
            SET is_read = TRUE
            WHERE id = $1 AND user_id = $2
            "#
        )
        .bind(notification_id)
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        Ok(())
    }
}
