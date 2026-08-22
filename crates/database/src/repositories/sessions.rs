use aims_common::{AimsError, Result};
use chrono::{DateTime, Utc};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow)]
pub struct UserSessionRecord {
    pub id: Uuid,
    pub user_id: Uuid,
    pub token_hash: String,
    pub created_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub last_seen_at: DateTime<Utc>,
    pub revoked_at: Option<DateTime<Utc>>,
    pub client_ip: Option<String>,
    pub user_agent: Option<String>,
}

pub struct UserSessionRepository;

impl UserSessionRepository {
    pub async fn create(
        pool: &PgPool,
        user_id: Uuid,
        token_hash: &str,
        expires_at: DateTime<Utc>,
        client_ip: Option<&str>,
        user_agent: Option<&str>,
    ) -> Result<UserSessionRecord> {
        let session = sqlx::query_as::<_, UserSessionRecord>(
            r#"
            INSERT INTO user_sessions (user_id, token_hash, expires_at, client_ip, user_agent)
            VALUES ($1, $2, $3, $4::inet, $5)
            RETURNING id, user_id, token_hash, created_at, expires_at, last_seen_at, revoked_at,
                      client_ip::text, user_agent
            "#,
        )
        .bind(user_id)
        .bind(token_hash)
        .bind(expires_at)
        .bind(client_ip)
        .bind(user_agent)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to create user session: {}", e)))?;

        Ok(session)
    }

    pub async fn find_active_by_hash(
        pool: &PgPool,
        token_hash: &str,
    ) -> Result<Option<UserSessionRecord>> {
        let session = sqlx::query_as::<_, UserSessionRecord>(
            r#"
            SELECT id, user_id, token_hash, created_at, expires_at, last_seen_at, revoked_at,
                   client_ip::text, user_agent
            FROM user_sessions
            WHERE token_hash = $1
              AND revoked_at IS NULL
              AND expires_at > CURRENT_TIMESTAMP
            "#,
        )
        .bind(token_hash)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query user session: {}", e)))?;

        Ok(session)
    }

    pub async fn revoke(pool: &PgPool, token_hash: &str) -> Result<()> {
        sqlx::query(
            r#"
            UPDATE user_sessions
            SET revoked_at = CURRENT_TIMESTAMP
            WHERE token_hash = $1 AND revoked_at IS NULL
            "#,
        )
        .bind(token_hash)
        .execute(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to revoke user session: {}", e)))?;

        Ok(())
    }

    pub async fn touch_last_seen(pool: &PgPool, session_id: Uuid) -> Result<()> {
        sqlx::query(
            r#"
            UPDATE user_sessions
            SET last_seen_at = CURRENT_TIMESTAMP
            WHERE id = $1
            "#,
        )
        .bind(session_id)
        .execute(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to update session last_seen_at: {}", e))
        })?;

        Ok(())
    }
}
