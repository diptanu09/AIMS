use aims_auth::CurrentUser;
use aims_database::repositories::{
    attendance_rules::AttendanceRuleRepository,
    designations::DesignationRepository,
    employees::EmployeeRepository,
    import_batches::{ImportBatchRecord, ImportBatchRepository},
    import_templates::{ImportTemplateRecord, ImportTemplateRepository},
    raw_events::RawEventRepository,
    sections::SectionRepository,
};
use aims_domain::ImportBatchStatus;
use aims_import_engine::{
    ImportPreviewResponse, ImportTemplate, ImportValidationSummary, compute_file_hash,
    parse_csv_bytes, validate_parsed_punches,
};
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use uuid::Uuid;

use crate::{error::AppError, state::AppState};

#[derive(Debug, Deserialize)]
pub struct CreateImportTemplateRequest {
    pub name: String,
    pub description: Option<String>,
    pub file_type: Option<String>,
    pub delimiter: Option<String>,
    pub header_row_index: Option<i32>,
    pub column_mapping: serde_json::Value,
    pub date_format: Option<String>,
    pub time_format: Option<String>,
    pub interpretation_mode: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ImportCommitResponse {
    pub batch: ImportBatchRecord,
    pub summary: ImportPreviewResponse,
}

pub struct ImportService;

impl ImportService {
    pub async fn preview(
        state: &AppState,
        actor: &CurrentUser,
        file_name: &str,
        file_bytes: &[u8],
        template_id: Option<Uuid>,
    ) -> Result<ImportPreviewResponse, AppError> {
        let summary =
            Self::run_import_pipeline(state, actor, file_name, file_bytes, template_id).await?;
        let template = Self::resolve_template(state, actor, template_id).await?;
        Ok(ImportPreviewResponse::from_summary(&summary, &template))
    }

    pub async fn commit(
        state: &AppState,
        actor: &CurrentUser,
        file_name: &str,
        file_bytes: &[u8],
        template_id: Option<Uuid>,
    ) -> Result<ImportCommitResponse, AppError> {
        let template = Self::resolve_template(state, actor, template_id).await?;
        let summary =
            Self::run_import_pipeline(state, actor, file_name, file_bytes, template_id).await?;

        let (default_sec_id, default_desig_id, default_rule_id) =
            Self::ensure_defaults(&state.db, actor.organization_id).await?;

        // 1. Create batch record
        let batch = ImportBatchRepository::create(
            &state.db,
            actor.organization_id,
            file_name,
            &summary.file_hash,
            actor.user_id,
        )
        .await?;

        // 2. Fetch employee device map for employee_id resolution
        let employees =
            EmployeeRepository::list_by_organization(&state.db, actor.organization_id).await?;
        let mut emp_map: std::collections::HashMap<String, (Uuid, Uuid, Uuid)> = employees
            .into_iter()
            .map(|e| (e.attendance_device_user_id, (e.id, e.section_id, e.attendance_rule_id)))
            .collect();

        // Auto-create missing employees for unique device IDs
        let unique_device_ids: std::collections::HashSet<String> = summary
            .valid_punches
            .iter()
            .map(|p| p.attendance_device_user_id.clone())
            .collect();

        for dev_id in unique_device_ids {
            if !emp_map.contains_key(&dev_id) {
                if let Ok(new_emp) = EmployeeRepository::create(
                    &state.db,
                    actor.organization_id,
                    &dev_id,
                    &dev_id,
                    &format!("Staff {}", dev_id),
                    None,
                    None,
                    None,
                    None,
                    default_sec_id,
                    default_desig_id,
                    default_rule_id,
                    chrono::Utc::now().date_naive(),
                    aims_domain::EmployeeStatus::Active,
                    Some(actor.user_id),
                )
                .await
                {
                    emp_map.insert(
                        dev_id,
                        (new_emp.id, new_emp.section_id, new_emp.attendance_rule_id),
                    );
                }
            }
        }

        // 3. Trigger raw event insertion and Attendance Engine processing asynchronously in background
        let db_pool = state.db.clone();
        let org_id = actor.organization_id;
        let batch_id = batch.id;
        let valid_punches = summary.valid_punches.clone();

        tokio::spawn(async move {
            let mut dates_to_process: std::collections::HashSet<(Uuid, Uuid, String, chrono::NaiveDate, Uuid)> =
                std::collections::HashSet::new();

            for p in &valid_punches {
                let emp_info = emp_map.get(&p.attendance_device_user_id).copied();
                let emp_id = emp_info.map(|(id, _, _)| id);
                let _ = RawEventRepository::create_ignore_duplicate(
                    &db_pool,
                    org_id,
                    batch_id,
                    p.source_row_number,
                    &p.attendance_device_user_id,
                    emp_id,
                    p.punch_timestamp,
                    p.punch_type.clone(),
                    p.device_terminal_id.as_deref(),
                    &p.event_fingerprint,
                    Some(&p.raw_text),
                )
                .await;

                if let Some((e_id, s_id, r_id)) = emp_info {
                    let local_date = p
                        .punch_timestamp
                        .with_timezone(&chrono_tz::Asia::Kolkata)
                        .date_naive();
                    dates_to_process.insert((
                        e_id,
                        s_id,
                        p.attendance_device_user_id.clone(),
                        local_date,
                        r_id,
                    ));
                }
            }

            let total = dates_to_process.len();
            eprintln!("[BACKGROUND WORKER] Started processing {} unique employee dates", total);
            let mut success_count = 0;
            for (e_id, s_id, dev_id, p_date, r_id) in dates_to_process {
                match aims_attendance_engine::process_and_persist_employee_date(
                    &db_pool,
                    org_id,
                    e_id,
                    s_id,
                    &dev_id,
                    p_date,
                    r_id,
                )
                .await
                {
                    Ok(_) => success_count += 1,
                    Err(e) => eprintln!(
                        "[BACKGROUND WORKER ERROR] Failed processing attendance for dev_id {} on {}: {:?}",
                        dev_id,
                        p_date,
                        e
                    ),
                }
            }
            eprintln!(
                "[BACKGROUND WORKER FINISHED] Processed {} / {} employee dates",
                success_count,
                total
            );
        });

        let batch_status = if summary.valid_records == 0 && summary.total_records > 0 {
            ImportBatchStatus::Failed
        } else {
            ImportBatchStatus::Completed
        };

        // 5. Update batch summary stats
        ImportBatchRepository::update_stats(
            &state.db,
            batch.id,
            summary.total_records,
            summary.valid_records,
            summary.duplicate_records,
            summary.unknown_employees,
            summary.invalid_records,
            batch_status,
        )
        .await?;

        let updated_batch = ImportBatchRepository::find_by_id(&state.db, batch.id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Batch {} not found", batch.id)))?;

        let preview_response = ImportPreviewResponse::from_summary(&summary, &template);
        Ok(ImportCommitResponse {
            batch: updated_batch,
            summary: preview_response,
        })
    }

    async fn run_import_pipeline(
        state: &AppState,
        actor: &CurrentUser,
        file_name: &str,
        file_bytes: &[u8],
        template_id: Option<Uuid>,
    ) -> Result<ImportValidationSummary, AppError> {
        let file_hash = compute_file_hash(file_bytes);

        // Check if duplicate file batch already uploaded
        if let Some(existing_batch) =
            ImportBatchRepository::find_by_file_hash(&state.db, actor.organization_id, &file_hash)
                .await?
        {
            return Err(AppError::Conflict(format!(
                "File '{}' has already been imported in batch {}",
                file_name, existing_batch.id
            )));
        }

        let template = Self::resolve_template(state, actor, template_id).await?;
        let parsed_punches = parse_csv_bytes(actor.organization_id, file_bytes, &template)?;

        // Fetch known employee device IDs
        let employees =
            EmployeeRepository::list_by_organization(&state.db, actor.organization_id).await?;
        let known_device_user_ids: HashSet<String> = employees
            .into_iter()
            .map(|e| e.attendance_device_user_id)
            .collect();

        // Fetch existing database event fingerprints
        let existing_fingerprints =
            RawEventRepository::list_fingerprints_by_organization(&state.db, actor.organization_id)
                .await?;

        let mut summary = ImportValidationSummary::new(file_name.to_string(), file_hash);
        validate_parsed_punches(
            parsed_punches,
            &known_device_user_ids,
            &existing_fingerprints,
            &mut summary,
        );

        Ok(summary)
    }

    async fn resolve_template(
        state: &AppState,
        actor: &CurrentUser,
        template_id: Option<Uuid>,
    ) -> Result<ImportTemplate, AppError> {
        if let Some(id) = template_id {
            let tpl_rec =
                ImportTemplateRepository::find_by_id(&state.db, actor.organization_id, id)
                    .await?
                    .ok_or_else(|| {
                        AppError::NotFound(format!("Import template {} not found", id))
                    })?;

            let mapping: aims_import_engine::ColumnMapping =
                serde_json::from_value(tpl_rec.column_mapping).map_err(|e| {
                    AppError::Validation(format!("Invalid template column mapping: {}", e))
                })?;

            let mode = serde_json::from_str(&format!("\"{}\"", tpl_rec.interpretation_mode))
                .unwrap_or(aims_import_engine::InterpretationMode::ExplicitDirection);

            Ok(ImportTemplate {
                id: Some(tpl_rec.id),
                name: tpl_rec.name,
                description: tpl_rec.description,
                file_type: tpl_rec.file_type,
                delimiter: tpl_rec.delimiter,
                header_row_index: tpl_rec.header_row_index,
                column_mapping: mapping,
                date_format: tpl_rec.date_format,
                time_format: tpl_rec.time_format,
                interpretation_mode: mode,
                file_layout: aims_import_engine::FileLayout::RowPerPunch,
            })
        } else {
            Ok(ImportTemplate::canonical_default())
        }
    }

    pub async fn create_template(
        state: &AppState,
        actor: &CurrentUser,
        req: CreateImportTemplateRequest,
    ) -> Result<ImportTemplateRecord, AppError> {
        if ImportTemplateRepository::find_by_name(&state.db, actor.organization_id, &req.name)
            .await?
            .is_some()
        {
            return Err(AppError::Conflict(format!(
                "Import template with name '{}' already exists",
                req.name
            )));
        }

        let record = ImportTemplateRepository::create(
            &state.db,
            actor.organization_id,
            &req.name,
            req.description.as_deref(),
            req.file_type.as_deref().unwrap_or("CSV"),
            req.delimiter.as_deref().unwrap_or(","),
            req.header_row_index.unwrap_or(1),
            &req.column_mapping,
            req.date_format.as_deref().unwrap_or("YYYY-MM-DD"),
            req.time_format.as_deref().unwrap_or("HH:mm:ss"),
            req.interpretation_mode
                .as_deref()
                .unwrap_or("EXPLICIT_DIRECTION"),
        )
        .await?;

        Ok(record)
    }

    pub async fn list_templates(
        state: &AppState,
        actor: &CurrentUser,
    ) -> Result<Vec<ImportTemplateRecord>, AppError> {
        let list =
            ImportTemplateRepository::list_active_by_organization(&state.db, actor.organization_id)
                .await?;
        Ok(list)
    }

    pub async fn list_batches(
        state: &AppState,
        actor: &CurrentUser,
    ) -> Result<Vec<ImportBatchRecord>, AppError> {
        let list =
            ImportBatchRepository::list_by_organization(&state.db, actor.organization_id).await?;
        Ok(list)
    }

    async fn ensure_defaults(
        db: &sqlx::PgPool,
        org_id: Uuid,
    ) -> Result<(Uuid, Uuid, Uuid), AppError> {
        let sec = match SectionRepository::find_by_code(db, org_id, "GENERAL").await? {
            Some(s) => s,
            None => SectionRepository::create(db, org_id, "GENERAL", "General Section", None).await?,
        };

        let des = match DesignationRepository::list_by_organization(db, org_id).await?.into_iter().next() {
            Some(d) => d,
            None => DesignationRepository::create(db, org_id, "STAFF", "Staff Member", 1).await?,
        };

        let rule = match AttendanceRuleRepository::list_by_organization(db, org_id).await?.into_iter().next() {
            Some(r) => r,
            None => {
                AttendanceRuleRepository::create(
                    db,
                    org_id,
                    "Standard Office Shift",
                    chrono::NaiveTime::from_hms_opt(9, 30, 0).unwrap(),
                    chrono::NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
                    15,
                    240,
                    420,
                    15,
                    12,
                    false,
                    chrono::NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
                    None,
                )
                .await?
            }
        };

        Ok((sec.id, des.id, rule.id))
    }
}
