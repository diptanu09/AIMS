use aims_common::{AimsError, Result};
use aims_domain::Section;
use sqlx::PgPool;
use uuid::Uuid;

pub struct SectionRepository;

impl SectionRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        code: &str,
        name: &str,
        parent_section_id: Option<Uuid>,
    ) -> Result<Section> {
        let sec = sqlx::query_as::<_, Section>(
            r#"
            INSERT INTO sections (organization_id, code, name, parent_section_id)
            VALUES ($1, $2, $3, $4)
            RETURNING id, organization_id, code, name, parent_section_id, active, created_at, updated_at
            "#,
        )
        .bind(organization_id)
        .bind(code)
        .bind(name)
        .bind(parent_section_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert section: {}", e)))?;

        Ok(sec)
    }

    pub async fn find_by_id(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
    ) -> Result<Option<Section>> {
        let sec = sqlx::query_as::<_, Section>(
            r#"
            SELECT id, organization_id, code, name, parent_section_id, active, created_at, updated_at
            FROM sections
            WHERE id = $1 AND organization_id = $2
            "#,
        )
        .bind(id)
        .bind(organization_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to find section by id: {}", e)))?;

        Ok(sec)
    }

    pub async fn find_by_code(
        pool: &PgPool,
        organization_id: Uuid,
        code: &str,
    ) -> Result<Option<Section>> {
        let sec = sqlx::query_as::<_, Section>(
            r#"
            SELECT id, organization_id, code, name, parent_section_id, active, created_at, updated_at
            FROM sections
            WHERE organization_id = $1 AND code = $2
            "#,
        )
        .bind(organization_id)
        .bind(code)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to find section by code: {}", e)))?;

        Ok(sec)
    }

    pub async fn update(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
        name: Option<&str>,
        parent_section_id: Option<Option<Uuid>>,
    ) -> Result<Section> {
        let current = Self::find_by_id(pool, organization_id, id)
            .await?
            .ok_or_else(|| AimsError::NotFound(format!("Section {} not found", id)))?;

        let new_name = name.unwrap_or(&current.name);
        let new_parent = match parent_section_id {
            Some(val) => val,
            None => current.parent_section_id,
        };

        let updated = sqlx::query_as::<_, Section>(
            r#"
            UPDATE sections
            SET name = $1, parent_section_id = $2, updated_at = CURRENT_TIMESTAMP
            WHERE id = $3 AND organization_id = $4
            RETURNING id, organization_id, code, name, parent_section_id, active, created_at, updated_at
            "#,
        )
        .bind(new_name)
        .bind(new_parent)
        .bind(id)
        .bind(organization_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to update section: {}", e)))?;

        Ok(updated)
    }

    pub async fn set_active(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
        active: bool,
    ) -> Result<Section> {
        let updated = sqlx::query_as::<_, Section>(
            r#"
            UPDATE sections
            SET active = $1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $2 AND organization_id = $3
            RETURNING id, organization_id, code, name, parent_section_id, active, created_at, updated_at
            "#,
        )
        .bind(active)
        .bind(id)
        .bind(organization_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to set section active state: {}", e)))?;

        Ok(updated)
    }

    pub async fn check_circular_reference(
        pool: &PgPool,
        section_id: Uuid,
        new_parent_id: Uuid,
    ) -> Result<bool> {
        if section_id == new_parent_id {
            return Ok(true);
        }

        let is_circular = sqlx::query_scalar::<_, bool>(
            r#"
            WITH RECURSIVE section_path AS (
                SELECT id, parent_section_id
                FROM sections
                WHERE id = $1

                UNION ALL

                SELECT s.id, s.parent_section_id
                FROM sections s
                INNER JOIN section_path sp ON sp.parent_section_id = s.id
            )
            SELECT EXISTS(
                SELECT 1 FROM section_path WHERE id = $2
            )
            "#,
        )
        .bind(new_parent_id)
        .bind(section_id)
        .fetch_one(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to check circular section hierarchy: {}", e))
        })?;

        Ok(is_circular)
    }

    pub async fn list_filtered(
        pool: &PgPool,
        organization_id: Uuid,
        search: Option<&str>,
        active: Option<bool>,
        parent_id: Option<Option<Uuid>>,
    ) -> Result<Vec<Section>> {
        let mut query = String::from(
            r#"
            SELECT id, organization_id, code, name, parent_section_id, active, created_at, updated_at
            FROM sections
            WHERE organization_id = $1
            "#,
        );

        if search.is_some() {
            query.push_str(" AND (code ILIKE $2 OR name ILIKE $2)");
        }

        let sections = sqlx::query_as::<_, Section>(
            r#"
            SELECT id, organization_id, code, name, parent_section_id, active, created_at, updated_at
            FROM sections
            WHERE organization_id = $1
              AND ($2::text IS NULL OR code ILIKE $2 OR name ILIKE $2)
              AND ($3::boolean IS NULL OR active = $3)
              AND (
                CASE
                    WHEN $4::boolean = TRUE THEN parent_section_id IS NULL
                    WHEN $5::uuid IS NOT NULL THEN parent_section_id = $5
                    ELSE TRUE
                END
              )
            ORDER BY code ASC
            "#,
        )
        .bind(organization_id)
        .bind(search.map(|s| format!("%{}%", s)))
        .bind(active)
        .bind(parent_id.map(|p| p.is_none()))
        .bind(parent_id.flatten())
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list sections: {}", e)))?;

        Ok(sections)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<Section>> {
        Self::list_filtered(pool, organization_id, None, None, None).await
    }
}
