use crate::{
    api::response::ApiResponse,
    error::AppError,
    services::attendance::{AttendanceService, ProcessAttendanceRequest},
    state::AppState,
};
use aims_auth::CurrentUser;
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    attendance_sessions::{AttendanceSessionRecord, AttendanceSessionRepository},
    processing_jobs::ProcessingJobRepository,
};
use aims_domain::AttendanceDaily;
use axum::{
    Extension, Json, Router,
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
};
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct DailyQuery {
    pub date: Option<NaiveDate>,
    pub start_date: Option<NaiveDate>,
    pub end_date: Option<NaiveDate>,
    pub employee_id: Option<Uuid>,
}

#[derive(Debug, Serialize)]
pub struct DailyDetailResponse {
    pub daily: AttendanceDaily,
    pub sessions: Vec<AttendanceSessionRecord>,
}

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/process", post(process_attendance_handler))
        .route("/recalculate", post(process_attendance_handler))
        .route("/daily", get(list_daily_attendance_handler))
        .route("/daily/{id}", get(get_daily_detail_handler))
        .route("/jobs", get(list_processing_jobs_handler))
}

pub async fn process_attendance_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<ProcessAttendanceRequest>,
) -> Result<impl IntoResponse, AppError> {
    let res = AttendanceService::process_attendance(
        &state.db,
        actor.organization_id,
        actor.user_id,
        payload,
    )
    .await?;

    Ok((StatusCode::OK, Json(ApiResponse::ok(res))))
}

pub async fn list_daily_attendance_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<DailyQuery>,
) -> Result<impl IntoResponse, AppError> {
    if let Some(date) = query.date {
        let records = DailyAttendanceRepository::list_by_organization_and_date_range(
            &state.db,
            actor.organization_id,
            date,
            date,
        )
        .await?;
        Ok((StatusCode::OK, Json(ApiResponse::ok(records))))
    } else if let (Some(start), Some(end)) = (query.start_date, query.end_date) {
        let records = if let Some(emp_id) = query.employee_id {
            let mut items = Vec::new();
            if let Some(daily) =
                DailyAttendanceRepository::find_by_employee_and_date(&state.db, emp_id, start)
                    .await?
            {
                items.push(daily);
            }
            items
        } else {
            DailyAttendanceRepository::list_by_organization_and_date_range(
                &state.db,
                actor.organization_id,
                start,
                end,
            )
            .await?
        };
        Ok((StatusCode::OK, Json(ApiResponse::ok(records))))
    } else {
        Err(AppError::Validation(
            "Either 'date' or ('start_date' and 'end_date') must be provided".into(),
        ))
    }
}

pub async fn get_daily_detail_handler(
    State(state): State<AppState>,
    Extension(_actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let daily = DailyAttendanceRepository::find_by_id(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("Daily attendance record not found".into()))?;

    let sessions = AttendanceSessionRepository::list_by_daily(&state.db, id).await?;

    Ok((
        StatusCode::OK,
        Json(ApiResponse::ok(DailyDetailResponse { daily, sessions })),
    ))
}

pub async fn list_processing_jobs_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> Result<impl IntoResponse, AppError> {
    let jobs =
        ProcessingJobRepository::list_by_organization(&state.db, actor.organization_id).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(jobs))))
}
