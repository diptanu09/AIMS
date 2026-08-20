use crate::state::AppState;
use aims_auth::Claims;
use aims_common::{AimsError, Result};
use aims_database::repositories::{
    employees::EmployeeRepository,
    import_batches::{ImportBatchRecord, ImportBatchRepository},
    raw_events::RawEventRepository,
};
use aims_domain::ImportBatchStatus;
use aims_import_engine::{compute_file_hash, parse_csv_punches};
use axum::{
    extract::{Multipart, Path, State},
    routing::{get, post},
    Extension, Json, Router,
};
use serde::Serialize;
use uuid::Uuid;

#[derive(Debug, Serialize)]
pub struct ImportSummaryResponse {
    pub batch_id: Uuid,
    pub file_name: String,
    pub file_hash: String,
    pub total_records: i32,
    pub valid_records: i32,
    pub duplicate_records: i32,
    pub unknown_employees: i32,
    pub invalid_records: i32,
    pub status: ImportBatchStatus,
}

pub async fn upload_attendance_file(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    mut multipart: Multipart,
) -> Result<Json<ImportSummaryResponse>> {
    let pool = state.db.pool();
    let mut file_bytes = Vec::new();
    let mut file_name = "attendance_upload.csv".to_string();

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AimsError::Import(format!("Multipart upload error: {}", e)))?
    {
        if let Some(name) = field.file_name() {
            file_name = name.to_string();
        }
        let data = field
            .bytes()
            .await
            .map_err(|e| AimsError::Import(format!("Failed to read file bytes: {}", e)))?;
        file_bytes.extend_from_slice(&data);
    }

    if file_bytes.is_empty() {
        return Err(AimsError::Import("Uploaded file is empty".into()));
    }

    let file_hash = compute_file_hash(&file_bytes);
    let batch = ImportBatchRepository::create(
        pool,
        claims.org_id,
        &file_name,
        &file_hash,
        claims.sub,
    )
    .await?;

    let parsed_punches = match parse_csv_punches(claims.org_id, &file_bytes) {
        Ok(punches) => punches,
        Err(e) => {
            let _ = ImportBatchRepository::update_stats(
                pool,
                batch.id,
                0,
                0,
                0,
                0,
                1,
                ImportBatchStatus::Failed,
            )
            .await;
            return Err(e);
        }
    };

    let total_records = parsed_punches.len() as i32;
    let mut valid_records = 0;
    let mut duplicate_records = 0;
    let mut unknown_employees = 0;
    let mut invalid_records = 0;

    for p in &parsed_punches {
        let emp_opt = EmployeeRepository::find_by_device_user_id(
            pool,
            claims.org_id,
            &p.attendance_device_user_id,
        )
        .await?;

        let emp_id = emp_opt.map(|e| e.id);
        if emp_id.is_none() {
            unknown_employees += 1;
        }

        let inserted = RawEventRepository::create_ignore_duplicate(
            pool,
            claims.org_id,
            batch.id,
            p.source_row_number,
            &p.attendance_device_user_id,
            emp_id,
            p.punch_timestamp,
            p.punch_type.clone(),
            p.device_terminal_id.as_deref(),
            &p.event_fingerprint,
            Some(&p.raw_text),
        )
        .await?;

        if inserted {
            valid_records += 1;
        } else {
            duplicate_records += 1;
        }
    }

    let batch_status = if invalid_records > 0 || unknown_employees > 0 {
        ImportBatchStatus::Partial
    } else {
        ImportBatchStatus::Completed
    };

    ImportBatchRepository::update_stats(
        pool,
        batch.id,
        total_records,
        valid_records,
        duplicate_records,
        unknown_employees,
        invalid_records,
        batch_status.clone(),
    )
    .await?;

    Ok(Json(ImportSummaryResponse {
        batch_id: batch.id,
        file_name,
        file_hash,
        total_records,
        valid_records,
        duplicate_records,
        unknown_employees,
        invalid_records,
        status: batch_status,
    }))
}

pub async fn list_batches(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<Vec<ImportBatchRecord>>> {
    let pool = state.db.pool();
    let batches = ImportBatchRepository::list_by_organization(pool, claims.org_id).await?;
    Ok(Json(batches))
}

pub async fn get_batch(
    State(state): State<AppState>,
    Path(batch_id): Path<Uuid>,
) -> Result<Json<ImportBatchRecord>> {
    let pool = state.db.pool();
    let batch = ImportBatchRepository::find_by_id(pool, batch_id)
        .await?
        .ok_or_else(|| AimsError::NotFound(format!("Import batch '{}' not found", batch_id)))?;

    Ok(Json(batch))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/upload", post(upload_attendance_file))
        .route("/batches", get(list_batches))
        .route("/batches/{batch_id}", get(get_batch))
}
