use aims_auth::CurrentUser;
use aims_database::repositories::reports::{
    MonthlySectionReportRepository, ReportDefinitionRepository, ReportRunRepository,
};
use aims_domain::{ReportDefinition, ReportRun, ReportRunStatus};
use aims_reporting::{
    generate_monthly_section_csv, generate_monthly_section_pdf, GenerateReportRequest,
};
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::AppError;

pub struct ReportingService;

impl ReportingService {
    pub async fn generate_report(
        pool: &PgPool,
        actor: &CurrentUser,
        req: GenerateReportRequest,
    ) -> Result<ReportRun, AppError> {
        // Enforce section scope security
        #[allow(clippy::collapsible_if)]
        if let Some(sec_id) = req.section_id {
            if !actor.has_permission("attendance.view.all")
                && !actor.has_permission("reports.generate")
                && !actor.can_access_section(sec_id)
            {
                return Err(AppError::Forbidden(
                    "Access denied: You do not have permission to generate reports for this section"
                        .to_string(),
                ));
            }
        }

        let def = ReportDefinitionRepository::ensure_default_definitions(
            pool,
            actor.organization_id,
        )
        .await?;

        let format_str = match req.format {
            aims_domain::ReportFormat::Pdf => "PDF",
            aims_domain::ReportFormat::Xlsx => "XLSX",
            aims_domain::ReportFormat::Csv => "CSV",
        };

        let params = serde_json::to_value(&req)
            .map_err(|e| AppError::Validation(format!("Invalid report parameters: {}", e)))?;

        let run = ReportRunRepository::create(
            pool,
            actor.organization_id,
            def.id,
            actor.user_id,
            params,
            format_str,
        )
        .await?;

        // Update to PROCESSING
        let run = ReportRunRepository::update_status(
            pool,
            run.id,
            ReportRunStatus::Processing,
            None,
            None,
        )
        .await?;

        let section_id = req.section_id.ok_or_else(|| {
            AppError::Validation("section_id is required for MONTHLY_SECTION report".into())
        })?;

        let data = MonthlySectionReportRepository::build_monthly_section_data(
            pool,
            actor.organization_id,
            section_id,
            req.date_from,
            req.date_to,
        )
        .await?;

        let (_bytes, extension) = match req.format {
            aims_domain::ReportFormat::Csv => {
                (generate_monthly_section_csv(&data)?, "csv")
            }
            aims_domain::ReportFormat::Pdf => {
                (generate_monthly_section_pdf(&data)?, "pdf")
            }
            aims_domain::ReportFormat::Xlsx => {
                (generate_monthly_section_csv(&data)?, "csv")
            }
        };

        let file_path = format!("reports/report_{}.{}", run.id, extension);

        let completed = ReportRunRepository::update_status(
            pool,
            run.id,
            ReportRunStatus::Completed,
            Some(&file_path),
            None,
        )
        .await?;

        Ok(completed)
    }

    pub async fn get_report_run(
        pool: &PgPool,
        _actor: &CurrentUser,
        id: Uuid,
    ) -> Result<ReportRun, AppError> {
        let run = ReportRunRepository::find_by_id(pool, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Report run {} not found", id)))?;

        Ok(run)
    }

    pub async fn list_report_definitions(
        pool: &PgPool,
        actor: &CurrentUser,
    ) -> Result<Vec<ReportDefinition>, AppError> {
        let defs = ReportDefinitionRepository::list_by_organization(pool, actor.organization_id).await?;
        Ok(defs)
    }

    pub async fn list_report_runs(
        pool: &PgPool,
        actor: &CurrentUser,
    ) -> Result<Vec<ReportRun>, AppError> {
        let runs = ReportRunRepository::list_by_organization(pool, actor.organization_id).await?;
        Ok(runs)
    }
}
