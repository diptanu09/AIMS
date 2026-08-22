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
    services::attendance_rules::{
        AttendanceRuleQuery, AttendanceRuleService, CreateAttendanceRuleRequest,
        UpdateAttendanceRuleRequest,
    },
    state::AppState,
};

pub async fn create_rule(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<CreateAttendanceRuleRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("rule.manage") && !actor.has_permission("attendance.view.all") {
        return Err(AppError::Forbidden("Permission 'rule.manage' required".to_string()));
    }

    let rule = AttendanceRuleService::create_rule(&state, &actor, payload).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(rule))))
}

pub async fn update_rule(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateAttendanceRuleRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("rule.manage") && !actor.has_permission("attendance.view.all") {
        return Err(AppError::Forbidden("Permission 'rule.manage' required".to_string()));
    }

    let rule = AttendanceRuleService::update_rule(&state, &actor, id, payload).await?;
    Ok(Json(ApiResponse::ok(rule)))
}

pub async fn get_rule(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let rule = AttendanceRuleService::get_rule(&state, &actor, id).await?;
    Ok(Json(ApiResponse::ok(rule)))
}

pub async fn list_rules(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<AttendanceRuleQuery>,
) -> Result<impl IntoResponse, AppError> {
    let rules = AttendanceRuleService::list_rules(&state, &actor, query).await?;
    Ok(Json(ApiResponse::ok(rules)))
}
