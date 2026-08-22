use crate::{
    api::response::{ApiResponse, PaginatedResponse},
    error::AppError,
    services::attendance::{AttendanceService, ProcessAttendanceRequest},
    state::AppState,
};
use aims_auth::CurrentUser;
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    attendance_query::{AttendanceQueryRepository, DailyAttendanceFilter},
    attendance_sessions::{AttendanceSessionRecord, AttendanceSessionRepository},
    processing_jobs::ProcessingJobRepository,
};
use aims_domain::{AttendanceDaily, AttendanceStatus};
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
pub struct DetailedDailyQuery {
    pub date: Option<NaiveDate>,
    pub start_date: Option<NaiveDate>,
    pub end_date: Option<NaiveDate>,
    pub section_id: Option<Uuid>,
    pub employee_id: Option<Uuid>,
    pub designation_id: Option<Uuid>,
    pub status: Option<AttendanceStatus>,
    pub search: Option<String>,
    pub page: Option<i64>,
    pub page_size: Option<i64>,
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
    Query(query): Query<DetailedDailyQuery>,
) -> Result<impl IntoResponse, AppError> {
    let page = query.page.unwrap_or(1).max(1);
    let page_size = query.page_size.unwrap_or(20).clamp(1, 100);
    let offset = (page - 1) * page_size;

    let filter = DailyAttendanceFilter {
        date: query.date,
        start_date: query.start_date,
        end_date: query.end_date,
        section_id: query.section_id,
        employee_id: query.employee_id,
        designation_id: query.designation_id,
        status: query.status,
        search: query.search,
        limit: page_size,
        offset,
    };

    let (items, total) =
        AttendanceQueryRepository::list_detailed_daily(&state.db, actor.organization_id, filter)
            .await?;

    let paginated = PaginatedResponse::new(items, page as u32, page_size as u32, total as u64);
    Ok((StatusCode::OK, Json(ApiResponse::ok(paginated))))
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
