use aims_common::{AimsError, Result};
use aims_domain::UserStatus;
use chrono::{DateTime, Utc};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow)]
pub struct UserRecord {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub employee_id: Option<Uuid>,
    pub username: String,
    pub email: String,
    pub password_hash: String,
    pub status: UserStatus,
    pub last_login_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

pub struct UserRepository;

impl UserRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        username: &str,
        email: &str,
        password_hash: &str,
    ) -> Result<UserRecord> {
        let user = sqlx::query_as::<_, UserRecord>(
            r#"
            INSERT INTO users (organization_id, username, email, password_hash)
            VALUES ($1, $2, $3, $4)
            RETURNING id, organization_id, employee_id, username, email, password_hash,
                      status, last_login_at, created_at, updated_at
            "#
        )
        .bind(organization_id)
        .bind(username)
        .bind(email)
        .bind(password_hash)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert user: {}", e)))?;

        Ok(user)
    }

    pub async fn find_by_username(pool: &PgPool, username: &str) -> Result<Option<UserRecord>> {
        let user = sqlx::query_as::<_, UserRecord>(
            r#"
            SELECT id, organization_id, employee_id, username, email, password_hash,
                   status, last_login_at, created_at, updated_at
            FROM users
            WHERE username = $1
            "#
        )
        .bind(username)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query user: {}", e)))?;

        Ok(user)
    }
}
