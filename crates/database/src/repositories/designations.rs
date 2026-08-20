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
            RETURNING id, organization_id, code, title, level, created_at
            "#
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

    pub async fn list_by_organization(pool: &PgPool, organization_id: Uuid) -> Result<Vec<Designation>> {
        let designations = sqlx::query_as::<_, Designation>(
            r#"
            SELECT id, organization_id, code, title, level, created_at
            FROM designations
            WHERE organization_id = $1
            ORDER BY level ASC, title ASC
            "#
        )
        .bind(organization_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list designations: {}", e)))?;

        Ok(designations)
    }
}
