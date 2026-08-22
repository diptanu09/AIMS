use aims_common::{AimsError, Result};
use aims_domain::{ReportDefinition, ReportRun, ReportRunStatus};
use aims_reporting::{MonthlySectionReportData, MonthlySectionRow, MonthlySectionSummary};
use chrono::{DateTime, NaiveDate, Utc};
use sqlx::PgPool;
use uuid::Uuid;

pub struct ReportDefinitionRepository;

impl ReportDefinitionRepository {
    pub async fn find_by_code(
        pool: &PgPool,
        organization_id: Uuid,
        code: &str,
    ) -> Result<Option<ReportDefinition>> {
        let rec = sqlx::query_as!(
            ReportDefinition,
            r#"
            SELECT id, organization_id, code, name, description, category, active, created_at, updated_at
            FROM report_definitions
            WHERE organization_id = $1 AND code = $2
            "#,
            organization_id,
            code
        )
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query report definition: {}", e)))?;

        Ok(rec)
    }

    pub async fn ensure_default_definitions(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<ReportDefinition> {
        if let Some(def) = Self::find_by_code(pool, organization_id, "MONTHLY_SECTION").await? {
            return Ok(def);
        }

        let def = sqlx::query_as!(
            ReportDefinition,
            r#"
            INSERT INTO report_definitions (organization_id, code, name, description, category)
            VALUES ($1, 'MONTHLY_SECTION', 'Monthly Section Attendance Report', 'Detailed monthly breakdown by section with BO/AAO hierarchy', 'ATTENDANCE')
            RETURNING id, organization_id, code, name, description, category, active, created_at, updated_at
            "#,
            organization_id
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to create default report definition: {}", e)))?;

        Ok(def)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<ReportDefinition>> {
        let recs = sqlx::query_as!(
            ReportDefinition,
            r#"
            SELECT id, organization_id, code, name, description, category, active, created_at, updated_at
            FROM report_definitions
            WHERE organization_id = $1 AND active = true
            ORDER BY name ASC
            "#,
            organization_id
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list report definitions: {}", e)))?;

        Ok(recs)
    }
}

pub struct ReportRunRepository;

impl ReportRunRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        report_definition_id: Uuid,
        generated_by: Uuid,
        parameters: serde_json::Value,
        output_format: &str,
    ) -> Result<ReportRun> {
        let rec = sqlx::query_as!(
            ReportRun,
            r#"
            INSERT INTO report_runs (
                organization_id, report_definition_id, generated_by, parameters, output_format, status
            )
            VALUES ($1, $2, $3, $4, $5, 'QUEUED')
            RETURNING id, organization_id, report_definition_id, generated_by, parameters, output_format,
                      status AS "status: ReportRunStatus", file_path, error_message, started_at, completed_at, created_at
            "#,
            organization_id,
            report_definition_id,
            generated_by,
            parameters,
            output_format
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to create report run: {}", e)))?;

        Ok(rec)
    }

    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<ReportRun>> {
        let rec = sqlx::query_as!(
            ReportRun,
            r#"
            SELECT id, organization_id, report_definition_id, generated_by, parameters, output_format,
                   status AS "status: ReportRunStatus", file_path, error_message, started_at, completed_at, created_at
            FROM report_runs
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to find report run: {}", e)))?;

        Ok(rec)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<ReportRun>> {
        let recs = sqlx::query_as!(
            ReportRun,
            r#"
            SELECT id, organization_id, report_definition_id, generated_by, parameters, output_format,
                   status AS "status: ReportRunStatus", file_path, error_message, started_at, completed_at, created_at
            FROM report_runs
            WHERE organization_id = $1
            ORDER BY created_at DESC
            LIMIT 50
            "#,
            organization_id
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list report runs: {}", e)))?;

        Ok(recs)
    }

    pub async fn update_status(
        pool: &PgPool,
        id: Uuid,
        status: ReportRunStatus,
        file_path: Option<&str>,
        error_message: Option<&str>,
    ) -> Result<ReportRun> {
        let now: DateTime<Utc> = Utc::now();
        let (started_at, completed_at) = match status {
            ReportRunStatus::Processing => (Some(now), None),
            ReportRunStatus::Completed | ReportRunStatus::Failed => (None, Some(now)),
            ReportRunStatus::Queued => (None, None),
        };

        let rec = sqlx::query_as!(
            ReportRun,
            r#"
            UPDATE report_runs
            SET status = $2,
                file_path = COALESCE($3, file_path),
                error_message = COALESCE($4, error_message),
                started_at = COALESCE($5, started_at),
                completed_at = COALESCE($6, completed_at)
            WHERE id = $1
            RETURNING id, organization_id, report_definition_id, generated_by, parameters, output_format,
                      status AS "status: ReportRunStatus", file_path, error_message, started_at, completed_at, created_at
            "#,
            id,
            status as ReportRunStatus,
            file_path,
            error_message,
            started_at,
            completed_at
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to update report run status: {}", e)))?;

        Ok(rec)
    }
}

pub struct MonthlySectionReportRepository;

impl MonthlySectionReportRepository {
    pub async fn build_monthly_section_data(
        pool: &PgPool,
        organization_id: Uuid,
        section_id: Uuid,
        date_from: NaiveDate,
        date_to: NaiveDate,
    ) -> Result<MonthlySectionReportData> {
        let org = sqlx::query!(
            "SELECT name FROM organizations WHERE id = $1",
            organization_id
        )
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?
        .ok_or_else(|| AimsError::NotFound("Organization not found".into()))?;

        let sec = sqlx::query!("SELECT name FROM sections WHERE id = $1", section_id)
            .fetch_optional(pool)
            .await
            .map_err(|e| AimsError::Database(e.to_string()))?
            .ok_or_else(|| AimsError::NotFound("Section not found".into()))?;

        let officers = sqlx::query!(
            r#"
            SELECT
                CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) AS name,
                d.title AS designation_title
            FROM employees e
            JOIN designations d ON e.designation_id = d.id
            WHERE e.section_id = $1 AND e.status = 'ACTIVE'
            "#,
            section_id
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(e.to_string()))?;

        let mut bo_list = Vec::new();
        let mut aao_list = Vec::new();

        for o in officers {
            let title_lower = o.designation_title.to_lowercase();
            let name = o.name.unwrap_or_default().trim().to_string();
            if title_lower.contains("senior accounts officer")
                || title_lower.contains("sao")
                || title_lower.contains("bo")
            {
                bo_list.push(name);
            } else if title_lower.contains("assistant accounts officer")
                || title_lower.contains("aao")
            {
                aao_list.push(name);
            }
        }

        let emp_stats = sqlx::query!(
            r#"
            SELECT
                e.employee_code,
                CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) AS employee_name,
                d.title AS designation_title,
                COUNT(ad.id) AS total_working_days,
                COUNT(ad.id) FILTER (WHERE ad.status = 'PRESENT') AS present_days,
                COUNT(ad.id) FILTER (WHERE ad.status IN ('LATE', 'LATE_AND_EARLY_EXIT')) AS late_days,
                COUNT(ad.id) FILTER (WHERE ad.status = 'ABSENT') AS absent_days,
                COUNT(ad.id) FILTER (WHERE ad.status = 'HALF_DAY') AS half_days,
                COUNT(ad.id) FILTER (WHERE ad.status = 'INCOMPLETE') AS incomplete_days
            FROM employees e
            JOIN designations d ON e.designation_id = d.id
            LEFT JOIN attendance_daily ad
                   ON e.id = ad.employee_id
                  AND ad.attendance_date BETWEEN $2 AND $3
            WHERE e.organization_id = $1
              AND e.section_id = $4
              AND e.status = 'ACTIVE'
            GROUP BY e.id, e.employee_code, e.first_name, e.last_name, d.title
            ORDER BY e.first_name ASC
            "#,
            organization_id,
            date_from,
            date_to,
            section_id
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query monthly section stats: {}", e)))?;

        let mut rows = Vec::new();
        let mut total_staff = 0i64;
        let mut total_present = 0i64;
        let mut total_late = 0i64;
        let mut total_absent = 0i64;
        let mut total_duty_pct_sum = 0.0f64;

        for (idx, r) in emp_stats.into_iter().enumerate() {
            total_staff += 1;
            let p_days = r.present_days.unwrap_or(0);
            let l_days = r.late_days.unwrap_or(0);
            let a_days = r.absent_days.unwrap_or(0);
            let h_days = r.half_days.unwrap_or(0);
            let i_days = r.incomplete_days.unwrap_or(0);
            let w_days = r.total_working_days.unwrap_or(0);

            total_present += p_days;
            total_late += l_days;
            total_absent += a_days;

            let duty_pct = if w_days > 0 {
                ((p_days + l_days) as f64 / w_days as f64) * 100.0
            } else {
                0.0
            };
            let duty_pct_rounded = (duty_pct * 100.0).round() / 100.0;
            total_duty_pct_sum += duty_pct_rounded;

            rows.push(MonthlySectionRow {
                sl_no: idx + 1,
                employee_code: r.employee_code,
                employee_name: r.employee_name.unwrap_or_default().trim().to_string(),
                designation_title: r.designation_title,
                present_days: p_days,
                late_days: l_days,
                absent_days: a_days,
                half_days: h_days,
                incomplete_days: i_days,
                total_working_days: w_days,
                duty_percentage: duty_pct_rounded,
            });
        }

        let avg_duty_pct = if total_staff > 0 {
            (total_duty_pct_sum / total_staff as f64 * 100.0).round() / 100.0
        } else {
            0.0
        };

        let month_label = format!(
            "{} to {}",
            date_from.format("%b %d, %Y"),
            date_to.format("%b %d, %Y")
        );

        Ok(MonthlySectionReportData {
            organization_name: org.name,
            section_name: sec.name,
            month_year_label: month_label,
            branch_officers: bo_list,
            assistant_accounts_officers: aao_list,
            summary: MonthlySectionSummary {
                total_staff,
                present_days_total: total_present,
                late_days_total: total_late,
                absent_days_total: total_absent,
                average_duty_percentage: avg_duty_pct,
            },
            rows,
        })
    }
}
