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
            "#,
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
            "#,
        )
        .bind(username)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query user: {}", e)))?;

        Ok(user)
    }

    pub async fn get_user_roles(pool: &PgPool, user_id: Uuid) -> Result<Vec<String>> {
        let roles = sqlx::query_scalar::<_, String>(
            r#"
            SELECT r.name
            FROM roles r
            INNER JOIN user_roles ur ON ur.role_id = r.id
            WHERE ur.user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query user roles: {}", e)))?;

        Ok(roles)
    }

    pub async fn get_user_permissions(pool: &PgPool, user_id: Uuid) -> Result<Vec<String>> {
        let permissions = sqlx::query_scalar::<_, String>(
            r#"
            SELECT DISTINCT p.code
            FROM permissions p
            INNER JOIN role_permissions rp ON rp.permission_id = p.id
            INNER JOIN user_roles ur ON ur.role_id = rp.role_id
            WHERE ur.user_id = $1
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query user permissions: {}", e)))?;

        Ok(permissions)
    }

    pub async fn get_user_section_ids(pool: &PgPool, user_id: Uuid) -> Result<Vec<Uuid>> {
        let sections = sqlx::query_scalar::<_, Uuid>(
            r#"
            SELECT usa.section_id
            FROM user_section_assignments usa
            WHERE usa.user_id = $1
              AND usa.effective_from <= CURRENT_DATE
              AND (usa.effective_to IS NULL OR usa.effective_to >= CURRENT_DATE)
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to query user section assignments: {}", e))
        })?;

        Ok(sections)
    }

    pub async fn update_last_login(pool: &PgPool, user_id: Uuid) -> Result<()> {
        sqlx::query(
            r#"
            UPDATE users
            SET last_login_at = CURRENT_TIMESTAMP
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to update last login: {}", e)))?;

        Ok(())
    }
}
