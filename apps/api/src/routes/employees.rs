use aims_auth::CurrentUser;
use aims_domain::EmployeeStatus;
use axum::{
    Extension, Json,
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
};
use uuid::Uuid;

use crate::{
    api::response::ApiResponse,
    error::AppError,
    services::employees::{
        CreateEmployeeRequest, EmployeeQuery, EmployeeService, EmployeeStatusTransitionRequest,
        TransferEmployeeRequest, UpdateEmployeeRequest,
    },
    state::AppState,
};

pub async fn create_employee(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<CreateEmployeeRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.create") {
        return Err(AppError::Forbidden(
            "Permission 'employee.create' required".to_string(),
        ));
    }

    let emp = EmployeeService::create_employee(&state, &actor, payload).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(emp))))
}

pub async fn update_employee(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateEmployeeRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.update") {
        return Err(AppError::Forbidden(
            "Permission 'employee.update' required".to_string(),
        ));
    }

    let emp = EmployeeService::update_employee(&state, &actor, id, payload).await?;
    Ok(Json(ApiResponse::ok(emp)))
}

pub async fn activate_employee(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.update") {
        return Err(AppError::Forbidden(
            "Permission 'employee.update' required".to_string(),
        ));
    }

    let req = EmployeeStatusTransitionRequest {
        status: EmployeeStatus::Active,
        leaving_date: None,
        reason: Some("Re-activated".to_string()),
    };

    let emp = EmployeeService::change_employee_status(&state, &actor, id, req).await?;
    Ok(Json(ApiResponse::ok(emp)))
}

pub async fn deactivate_employee(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<Option<EmployeeStatusTransitionRequest>>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.update") {
        return Err(AppError::Forbidden(
            "Permission 'employee.update' required".to_string(),
        ));
    }

    let req = payload.unwrap_or(EmployeeStatusTransitionRequest {
        status: EmployeeStatus::Resigned,
        leaving_date: Some(chrono::Utc::now().date_naive()),
        reason: Some("Deactivated / Resigned".to_string()),
    });

    let emp = EmployeeService::change_employee_status(&state, &actor, id, req).await?;
    Ok(Json(ApiResponse::ok(emp)))
}

pub async fn transfer_employee(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<TransferEmployeeRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.update") {
        return Err(AppError::Forbidden(
            "Permission 'employee.update' required".to_string(),
        ));
    }

    let emp = EmployeeService::transfer_employee(&state, &actor, id, payload).await?;
    Ok(Json(ApiResponse::ok(emp)))
}

pub async fn get_employee(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.view")
        && !actor.has_permission("attendance.view.section")
        && !actor.has_permission("attendance.view.all")
    {
        return Err(AppError::Forbidden(
            "Permission 'employee.view' required".to_string(),
        ));
    }

    let emp = EmployeeService::get_employee(&state, &actor, id).await?;
    Ok(Json(ApiResponse::ok(emp)))
}

pub async fn list_employees(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<EmployeeQuery>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.view")
        && !actor.has_permission("attendance.view.section")
        && !actor.has_permission("attendance.view.all")
    {
        return Err(AppError::Forbidden(
            "Permission 'employee.view' required".to_string(),
        ));
    }

    let res = EmployeeService::list_employees(&state, &actor, query).await?;
    Ok(Json(ApiResponse::ok(res)))
}
