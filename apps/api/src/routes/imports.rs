use aims_auth::CurrentUser;
use axum::{
    Extension, Json,
    extract::{Multipart, State},
    http::StatusCode,
    response::IntoResponse,
};
use uuid::Uuid;

use crate::{
    api::response::ApiResponse,
    error::AppError,
    services::imports::{CreateImportTemplateRequest, ImportService},
    state::AppState,
};

pub async fn preview_import(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    mut multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let mut file_name = None;
    let mut file_bytes = None;
    let mut template_id = None;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::Validation(format!("Invalid multipart form payload: {}", e)))?
    {
        let name = field.name().unwrap_or("").to_string();
        if name == "file" {
            file_name = field.file_name().map(|s| s.to_string());
            file_bytes =
                Some(field.bytes().await.map_err(|e| {
                    AppError::Validation(format!("Failed to read file bytes: {}", e))
                })?);
        } else if name == "template_id" {
            let text = field
                .text()
                .await
                .map_err(|e| AppError::Validation(format!("Invalid template_id field: {}", e)))?;
            if !text.trim().is_empty() {
                template_id = Uuid::parse_str(text.trim()).ok();
            }
        }
    }

    let f_name = file_name.unwrap_or_else(|| "uploaded_punches.csv".to_string());
    let f_bytes = file_bytes.ok_or_else(|| {
        AppError::Validation("Missing 'file' field in multipart data".to_string())
    })?;

    let preview = ImportService::preview(&state, &actor, &f_name, &f_bytes, template_id).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(preview))))
}

pub async fn commit_import(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    mut multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let mut file_name = None;
    let mut file_bytes = None;
    let mut template_id = None;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::Validation(format!("Invalid multipart form payload: {}", e)))?
    {
        let name = field.name().unwrap_or("").to_string();
        if name == "file" {
            file_name = field.file_name().map(|s| s.to_string());
            file_bytes =
                Some(field.bytes().await.map_err(|e| {
                    AppError::Validation(format!("Failed to read file bytes: {}", e))
                })?);
        } else if name == "template_id" {
            let text = field
                .text()
                .await
                .map_err(|e| AppError::Validation(format!("Invalid template_id field: {}", e)))?;
            if !text.trim().is_empty() {
                template_id = Uuid::parse_str(text.trim()).ok();
            }
        }
    }

    let f_name = file_name.unwrap_or_else(|| "uploaded_punches.csv".to_string());
    let f_bytes = file_bytes.ok_or_else(|| {
        AppError::Validation("Missing 'file' field in multipart data".to_string())
    })?;

    let commit_res = ImportService::commit(&state, &actor, &f_name, &f_bytes, template_id).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(commit_res))))
}

pub async fn list_batches(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> Result<impl IntoResponse, AppError> {
    let batches = ImportService::list_batches(&state, &actor).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(batches))))
}

pub async fn list_templates(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> Result<impl IntoResponse, AppError> {
    let templates = ImportService::list_templates(&state, &actor).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(templates))))
}

pub async fn create_template(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(req): Json<CreateImportTemplateRequest>,
) -> Result<impl IntoResponse, AppError> {
    let tpl = ImportService::create_template(&state, &actor, req).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(tpl))))
}
