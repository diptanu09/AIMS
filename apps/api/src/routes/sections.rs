use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Extension, Json,
};
use aims_auth::CurrentUser;
use uuid::Uuid;

use crate::{
    api::response::ApiResponse,
    error::AppError,
    services::sections::{
        CreateSectionRequest, SectionQuery, SectionService, UpdateSectionRequest,
    },
    state::AppState,
};

pub async fn create_section(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<CreateSectionRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("section.manage") && !actor.has_permission("attendance.view.all") {
        return Err(AppError::Forbidden("Permission 'section.manage' required".to_string()));
    }

    let sec = SectionService::create_section(&state, &actor, payload).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(sec))))
}

pub async fn update_section(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateSectionRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("section.manage") && !actor.has_permission("attendance.view.all") {
        return Err(AppError::Forbidden("Permission 'section.manage' required".to_string()));
    }

    let sec = SectionService::update_section(&state, &actor, id, payload).await?;
    Ok(Json(ApiResponse::ok(sec)))
}

pub async fn activate_section(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("section.manage") && !actor.has_permission("attendance.view.all") {
        return Err(AppError::Forbidden("Permission 'section.manage' required".to_string()));
    }

    let sec = SectionService::set_section_active(&state, &actor, id, true).await?;
    Ok(Json(ApiResponse::ok(sec)))
}

pub async fn deactivate_section(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("section.manage") && !actor.has_permission("attendance.view.all") {
        return Err(AppError::Forbidden("Permission 'section.manage' required".to_string()));
    }

    let sec = SectionService::set_section_active(&state, &actor, id, false).await?;
    Ok(Json(ApiResponse::ok(sec)))
}

pub async fn get_section(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let sec = SectionService::get_section(&state, &actor, id).await?;
    Ok(Json(ApiResponse::ok(sec)))
}

pub async fn list_sections(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<SectionQuery>,
) -> Result<impl IntoResponse, AppError> {
    let secs = SectionService::list_sections(&state, &actor, query).await?;
    Ok(Json(ApiResponse::ok(secs)))
}
