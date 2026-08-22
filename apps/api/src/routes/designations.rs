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
    services::designations::{
        CreateDesignationRequest, DesignationQuery, DesignationService, UpdateDesignationRequest,
    },
    state::AppState,
};

pub async fn create_designation(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<CreateDesignationRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.create") && !actor.has_permission("user.manage") {
        return Err(AppError::Forbidden("Permission 'employee.create' required".to_string()));
    }

    let des = DesignationService::create_designation(&state, &actor, payload).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(des))))
}

pub async fn update_designation(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateDesignationRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.update") && !actor.has_permission("user.manage") {
        return Err(AppError::Forbidden("Permission 'employee.update' required".to_string()));
    }

    let des = DesignationService::update_designation(&state, &actor, id, payload).await?;
    Ok(Json(ApiResponse::ok(des)))
}

pub async fn activate_designation(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.update") && !actor.has_permission("user.manage") {
        return Err(AppError::Forbidden("Permission 'employee.update' required".to_string()));
    }

    let des = DesignationService::set_designation_active(&state, &actor, id, true).await?;
    Ok(Json(ApiResponse::ok(des)))
}

pub async fn deactivate_designation(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.update") && !actor.has_permission("user.manage") {
        return Err(AppError::Forbidden("Permission 'employee.update' required".to_string()));
    }

    let des = DesignationService::set_designation_active(&state, &actor, id, false).await?;
    Ok(Json(ApiResponse::ok(des)))
}

pub async fn get_designation(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let des = DesignationService::get_designation(&state, &actor, id).await?;
    Ok(Json(ApiResponse::ok(des)))
}

pub async fn list_designations(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<DesignationQuery>,
) -> Result<impl IntoResponse, AppError> {
    let dess = DesignationService::list_designations(&state, &actor, query).await?;
    Ok(Json(ApiResponse::ok(dess)))
}
