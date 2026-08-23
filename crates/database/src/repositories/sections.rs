use aims_common::{AimsError, Result};
use aims_domain::Section;
use serde::{Deserialize, Serialize};
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

    pub async fn get_section_officer_assignments(
        pool: &PgPool,
        organization_id: Uuid,
        section_id: Uuid,
    ) -> Result<Vec<SectionOfficerAssignmentRow>> {
        let rows = sqlx::query_as::<_, SectionOfficerAssignmentRow>(
            r#"
            SELECT
                soa.id,
                soa.section_id,
                soa.employee_id,
                e.employee_code,
                CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) AS employee_name,
                d.title AS designation_title,
                soa.role_title,
                soa.assigned_at
            FROM section_officer_assignments soa
            JOIN employees e ON soa.employee_id = e.id
            JOIN designations d ON e.designation_id = d.id
            WHERE soa.organization_id = $1
              AND soa.section_id = $2
            ORDER BY soa.role_title ASC, e.first_name ASC
            "#,
        )
        .bind(organization_id)
        .bind(section_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query section officer assignments: {}", e)))?;

        Ok(rows)
    }

    pub async fn update_section_officer_assignments(
        pool: &PgPool,
        organization_id: Uuid,
        section_id: Uuid,
        role_title: &str,
        employee_ids: &[Uuid],
    ) -> Result<()> {
        let mut tx = pool
            .begin()
            .await
            .map_err(|e| AimsError::Database(format!("Failed to begin transaction: {}", e)))?;

        sqlx::query(
            r#"
            DELETE FROM section_officer_assignments
            WHERE organization_id = $1 AND section_id = $2 AND role_title = $3
            "#,
        )
        .bind(organization_id)
        .bind(section_id)
        .bind(role_title)
        .execute(&mut *tx)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to clear existing section officers: {}", e)))?;

        for emp_id in employee_ids {
            sqlx::query(
                r#"
                INSERT INTO section_officer_assignments (organization_id, section_id, employee_id, role_title)
                VALUES ($1, $2, $3, $4)
                ON CONFLICT (section_id, employee_id, role_title) DO NOTHING
                "#,
            )
            .bind(organization_id)
            .bind(section_id)
            .bind(emp_id)
            .bind(role_title)
            .execute(&mut *tx)
            .await
            .map_err(|e| AimsError::Database(format!("Failed to insert section officer assignment: {}", e)))?;
        }

        tx.commit()
            .await
            .map_err(|e| AimsError::Database(format!("Failed to commit section officer assignment transaction: {}", e)))?;

        Ok(())
    }

    pub async fn get_candidate_officers(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<CandidateOfficerRow>> {
        let rows = sqlx::query_as::<_, CandidateOfficerRow>(
            r#"
            SELECT
                e.id,
                e.employee_code,
                CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) AS employee_name,
                d.title AS designation_title,
                CASE
                    WHEN LOWER(d.title) LIKE '%senior accounts officer%' OR LOWER(d.title) LIKE '%sao%' OR LOWER(d.title) LIKE '%branch officer%' OR LOWER(d.title) LIKE '%bo%' THEN 'BRANCH_OFFICER'
                    WHEN LOWER(d.title) LIKE '%assistant accounts officer%' OR LOWER(d.title) LIKE '%aao%' THEN 'SECTION_OFFICER'
                    ELSE 'OTHER'
                END AS category
            FROM employees e
            JOIN designations d ON e.designation_id = d.id
            WHERE e.organization_id = $1
              AND e.status = 'ACTIVE'
              AND (
                  LOWER(d.title) LIKE '%senior accounts officer%' OR LOWER(d.title) LIKE '%sao%' OR LOWER(d.title) LIKE '%branch officer%' OR LOWER(d.title) LIKE '%bo%'
                  OR LOWER(d.title) LIKE '%assistant accounts officer%' OR LOWER(d.title) LIKE '%aao%'
              )
            ORDER BY d.title ASC, e.first_name ASC
            "#,
        )
        .bind(organization_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query candidate officers: {}", e)))?;

        Ok(rows)
    }
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct SectionOfficerAssignmentRow {
    pub id: Uuid,
    pub section_id: Uuid,
    pub employee_id: Uuid,
    pub employee_code: String,
    pub employee_name: String,
    pub designation_title: String,
    pub role_title: String,
    pub assigned_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct CandidateOfficerRow {
    pub id: Uuid,
    pub employee_code: String,
    pub employee_name: String,
    pub designation_title: String,
    pub category: String,
}

