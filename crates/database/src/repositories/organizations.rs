use aims_common::{AimsError, Result};
use aims_domain::Organization;
use sqlx::PgPool;
use uuid::Uuid;

pub struct OrganizationRepository;

impl OrganizationRepository {
    pub async fn create(
        pool: &PgPool,
        code: &str,
        name: &str,
        timezone: &str,
    ) -> Result<Organization> {
        let org = sqlx::query_as::<_, Organization>(
            r#"
            INSERT INTO organizations (code, name, timezone)
            VALUES ($1, $2, $3)
            RETURNING id, code, name, timezone, created_at, updated_at
            "#,
        )
        .bind(code)
        .bind(name)
        .bind(timezone)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert organization: {}", e)))?;

        Ok(org)
    }

    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<Organization>> {
        let org = sqlx::query_as::<_, Organization>(
            r#"
            SELECT id, code, name, timezone, created_at, updated_at
            FROM organizations
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to find organization by id: {}", e)))?;

        Ok(org)
    }

    pub async fn find_by_code(pool: &PgPool, code: &str) -> Result<Option<Organization>> {
        let org = sqlx::query_as::<_, Organization>(
            r#"
            SELECT id, code, name, timezone, created_at, updated_at
            FROM organizations
            WHERE code = $1
            "#,
        )
        .bind(code)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to find organization by code: {}", e)))?;

        Ok(org)
    }

    pub async fn list_all(pool: &PgPool) -> Result<Vec<Organization>> {
        let orgs = sqlx::query_as::<_, Organization>(
            r#"
            SELECT id, code, name, timezone, created_at, updated_at
            FROM organizations
            ORDER BY name ASC
            "#,
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list organizations: {}", e)))?;

        Ok(orgs)
    }
}
