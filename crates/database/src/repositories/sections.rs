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
            RETURNING id, organization_id, code, name, parent_section_id, created_at, updated_at
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

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<Section>> {
        let sections = sqlx::query_as::<_, Section>(
            r#"
            SELECT id, organization_id, code, name, parent_section_id, created_at, updated_at
            FROM sections
            WHERE organization_id = $1
            ORDER BY code ASC
            "#,
        )
        .bind(organization_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list sections: {}", e)))?;

        Ok(sections)
    }
}
