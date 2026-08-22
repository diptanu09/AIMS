use aims_common::{AimsError, Result};
use aims_domain::Designation;
use sqlx::PgPool;
use uuid::Uuid;

pub struct DesignationRepository;

impl DesignationRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        code: &str,
        title: &str,
        level: i32,
    ) -> Result<Designation> {
        let des = sqlx::query_as::<_, Designation>(
            r#"
            INSERT INTO designations (organization_id, code, title, level)
            VALUES ($1, $2, $3, $4)
            RETURNING id, organization_id, code, title, level, active, created_at, updated_at
            "#,
        )
        .bind(organization_id)
        .bind(code)
        .bind(title)
        .bind(level)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert designation: {}", e)))?;

        Ok(des)
    }

    pub async fn find_by_id(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
    ) -> Result<Option<Designation>> {
        let des = sqlx::query_as::<_, Designation>(
            r#"
            SELECT id, organization_id, code, title, level, active, created_at, updated_at
            FROM designations
            WHERE id = $1 AND organization_id = $2
            "#,
        )
        .bind(id)
        .bind(organization_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to find designation by id: {}", e)))?;

        Ok(des)
    }

    pub async fn find_by_code(
        pool: &PgPool,
        organization_id: Uuid,
        code: &str,
    ) -> Result<Option<Designation>> {
        let des = sqlx::query_as::<_, Designation>(
            r#"
            SELECT id, organization_id, code, title, level, active, created_at, updated_at
            FROM designations
            WHERE organization_id = $1 AND code = $2
            "#,
        )
        .bind(organization_id)
        .bind(code)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to find designation by code: {}", e)))?;

        Ok(des)
    }

    pub async fn update(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
        title: Option<&str>,
        level: Option<i32>,
    ) -> Result<Designation> {
        let current = Self::find_by_id(pool, organization_id, id)
            .await?
            .ok_or_else(|| AimsError::NotFound(format!("Designation {} not found", id)))?;

        let new_title = title.unwrap_or(&current.title);
        let new_level = level.unwrap_or(current.level);

        let updated = sqlx::query_as::<_, Designation>(
            r#"
            UPDATE designations
            SET title = $1, level = $2, updated_at = CURRENT_TIMESTAMP
            WHERE id = $3 AND organization_id = $4
            RETURNING id, organization_id, code, title, level, active, created_at, updated_at
            "#,
        )
        .bind(new_title)
        .bind(new_level)
        .bind(id)
        .bind(organization_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to update designation: {}", e)))?;

        Ok(updated)
    }

    pub async fn set_active(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
        active: bool,
    ) -> Result<Designation> {
        let updated = sqlx::query_as::<_, Designation>(
            r#"
            UPDATE designations
            SET active = $1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $2 AND organization_id = $3
            RETURNING id, organization_id, code, title, level, active, created_at, updated_at
            "#,
        )
        .bind(active)
        .bind(id)
        .bind(organization_id)
        .fetch_one(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to set designation active state: {}", e))
        })?;

        Ok(updated)
    }

    pub async fn list_filtered(
        pool: &PgPool,
        organization_id: Uuid,
        search: Option<&str>,
        active: Option<bool>,
    ) -> Result<Vec<Designation>> {
        let designations = sqlx::query_as::<_, Designation>(
            r#"
            SELECT id, organization_id, code, title, level, active, created_at, updated_at
            FROM designations
            WHERE organization_id = $1
              AND ($2::text IS NULL OR code ILIKE $2 OR title ILIKE $2)
              AND ($3::boolean IS NULL OR active = $3)
            ORDER BY level DESC, title ASC
            "#,
        )
        .bind(organization_id)
        .bind(search.map(|s| format!("%{}%", s)))
        .bind(active)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list designations: {}", e)))?;

        Ok(designations)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<Designation>> {
        Self::list_filtered(pool, organization_id, None, None).await
    }
}
