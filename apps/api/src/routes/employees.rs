use aims_auth::CurrentUser;
use aims_database::repositories::attendance_query::{
    AttendanceQueryRepository, DailyAttendanceFilter,
};
use aims_domain::{AttendanceStatus, EmployeeStatus};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Extension, Json,
};
use chrono::NaiveDate;
use serde::Deserialize;
use uuid::Uuid;

use crate::{
    api::response::{ApiResponse, PaginatedResponse},
    error::AppError,
    services::employees::{
        CreateEmployeeRequest, EmployeeQuery, EmployeeService, EmployeeStatusTransitionRequest,
        TransferEmployeeRequest, UpdateEmployeeRequest,
    },
    state::AppState,
};

#[derive(Debug, Deserialize)]
pub struct EmployeeAttendanceQuery {
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
    pub status: Option<AttendanceStatus>,
    pub page: Option<i64>,
    pub page_size: Option<i64>,
}

pub async fn create_employee(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<CreateEmployeeRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.manage") {
        return Err(AppError::Forbidden(
            "Permission 'employee.manage' required".to_string(),
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
    if !actor.has_permission("employee.manage") {
        return Err(AppError::Forbidden(
            "Permission 'employee.manage' required".to_string(),
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
    if !actor.has_permission("employee.manage") {
        return Err(AppError::Forbidden(
            "Permission 'employee.manage' required".to_string(),
        ));
    }

    let req = EmployeeStatusTransitionRequest {
        status: EmployeeStatus::Active,
        reason: None,
        leaving_date: None,
    };

    let emp = EmployeeService::change_employee_status(&state, &actor, id, req).await?;
    Ok(Json(ApiResponse::ok(emp)))
}

pub async fn deactivate_employee(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.manage") {
        return Err(AppError::Forbidden(
            "Permission 'employee.manage' required".to_string(),
        ));
    }

    let req = EmployeeStatusTransitionRequest {
        status: EmployeeStatus::Suspended,
        reason: None,
        leaving_date: None,
    };

    let emp = EmployeeService::change_employee_status(&state, &actor, id, req).await?;
    Ok(Json(ApiResponse::ok(emp)))
}

pub async fn transfer_employee(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<TransferEmployeeRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("employee.manage") {
        return Err(AppError::Forbidden(
            "Permission 'employee.manage' required".to_string(),
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

pub async fn get_employee_attendance(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Query(query): Query<EmployeeAttendanceQuery>,
) -> Result<impl IntoResponse, AppError> {
    let page = query.page.unwrap_or(1).max(1);
    let page_size = query.page_size.unwrap_or(20).clamp(1, 100);
    let offset = (page - 1) * page_size;

    let filter = DailyAttendanceFilter {
        date: None,
        start_date: query.date_from,
        end_date: query.date_to,
        section_id: None,
        employee_id: Some(id),
        designation_id: None,
        status: query.status,
        search: None,
        limit: page_size,
        offset,
    };

    let (items, total) = AttendanceQueryRepository::list_detailed_daily(
        &state.db,
        actor.organization_id,
        filter,
    )
    .await?;

    let paginated = PaginatedResponse::new(items, page as u32, page_size as u32, total as u64);
    Ok((StatusCode::OK, Json(ApiResponse::ok(paginated))))
}

pub async fn get_employee_attendance_summary(
    State(state): State<AppState>,
    Extension(_actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Query(query): Query<EmployeeAttendanceQuery>,
) -> Result<impl IntoResponse, AppError> {
    let stats = AttendanceQueryRepository::get_employee_stats(
        &state.db,
        id,
        query.date_from,
        query.date_to,
    )
    .await?;

    Ok((StatusCode::OK, Json(ApiResponse::ok(stats))))
}
