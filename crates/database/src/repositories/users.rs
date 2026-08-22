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
    pub full_name: String,
    pub status: UserStatus,
    pub last_login_at: Option<DateTime<Utc>>,
    pub failed_login_count: i32,
    pub locked_until: Option<DateTime<Utc>>,
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
        full_name: &str,
    ) -> Result<UserRecord> {
        let user = sqlx::query_as::<_, UserRecord>(
            r#"
            INSERT INTO users (organization_id, username, email, password_hash, full_name)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, organization_id, employee_id, username, email, password_hash, full_name,
                      status, last_login_at, failed_login_count, locked_until, created_at, updated_at
            "#,
        )
        .bind(organization_id)
        .bind(username)
        .bind(email)
        .bind(password_hash)
        .bind(full_name)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert user: {}", e)))?;

        Ok(user)
    }

    pub async fn find_by_username(pool: &PgPool, username: &str) -> Result<Option<UserRecord>> {
        let user = sqlx::query_as::<_, UserRecord>(
            r#"
            SELECT id, organization_id, employee_id, username, email, password_hash, full_name,
                   status, last_login_at, failed_login_count, locked_until, created_at, updated_at
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

    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<UserRecord>> {
        let user = sqlx::query_as::<_, UserRecord>(
            r#"
            SELECT id, organization_id, employee_id, username, email, password_hash, full_name,
                   status, last_login_at, failed_login_count, locked_until, created_at, updated_at
            FROM users
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query user by id: {}", e)))?;

        Ok(user)
    }

    pub async fn record_failed_login(pool: &PgPool, user_id: Uuid) -> Result<()> {
        sqlx::query(
            r#"
            UPDATE users
            SET failed_login_count = failed_login_count + 1,
                locked_until = CASE
                    WHEN failed_login_count + 1 >= 5 THEN CURRENT_TIMESTAMP + INTERVAL '15 minutes'
                    ELSE locked_until
                END
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to record failed login: {}", e)))?;

        Ok(())
    }

    pub async fn reset_failed_login_and_update_last_login(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<()> {
        sqlx::query(
            r#"
            UPDATE users
            SET failed_login_count = 0,
                locked_until = NULL,
                last_login_at = CURRENT_TIMESTAMP
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to reset failed login count: {}", e)))?;

        Ok(())
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

    pub async fn assign_role(pool: &PgPool, user_id: Uuid, role_id: Uuid) -> Result<()> {
        sqlx::query(
            r#"
            INSERT INTO user_roles (user_id, role_id)
            VALUES ($1, $2)
            ON CONFLICT DO NOTHING
            "#,
        )
        .bind(user_id)
        .bind(role_id)
        .execute(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to assign role to user: {}", e)))?;

        Ok(())
    }
}
