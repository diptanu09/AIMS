use aims_auth::CurrentUser;
use aims_database::repositories::{
    attendance_query::AttendanceQueryRepository, dashboard::DashboardRepository,
};
use axum::{
    Extension, Json,
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
};
use chrono::{Local, NaiveDate};
use serde::Deserialize;
use uuid::Uuid;

use crate::{
    api::response::ApiResponse,
    error::AppError,
    services::sections::{
        CreateSectionRequest, SectionQuery, SectionService, UpdateSectionRequest,
    },
    state::AppState,
};

#[derive(Debug, Deserialize)]
pub struct SectionAttendanceDateQuery {
    pub date: Option<NaiveDate>,
}

pub async fn create_section(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<CreateSectionRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("section.manage") && !actor.has_permission("attendance.view.all") {
        return Err(AppError::Forbidden(
            "Permission 'section.manage' required".to_string(),
        ));
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
        return Err(AppError::Forbidden(
            "Permission 'section.manage' required".to_string(),
        ));
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
        return Err(AppError::Forbidden(
            "Permission 'section.manage' required".to_string(),
        ));
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
        return Err(AppError::Forbidden(
            "Permission 'section.manage' required".to_string(),
        ));
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

pub async fn get_section_attendance(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Query(query): Query<SectionAttendanceDateQuery>,
) -> Result<impl IntoResponse, AppError> {
    let date = query.date.unwrap_or_else(|| Local::now().date_naive());
    let all_sections =
        DashboardRepository::get_section_summaries(&state.db, actor.organization_id, date).await?;
    let sec_summary = all_sections
        .into_iter()
        .find(|s| s.section_id == id)
        .ok_or_else(|| AppError::NotFound("Section attendance summary not found".into()))?;

    Ok((StatusCode::OK, Json(ApiResponse::ok(sec_summary))))
}

pub async fn get_section_hierarchy(
    State(state): State<AppState>,
    Extension(_actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let hierarchy = AttendanceQueryRepository::get_section_hierarchy(&state.db, id).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(hierarchy))))
}
