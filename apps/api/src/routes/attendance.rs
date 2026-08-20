use crate::state::AppState;
use aims_attendance_engine::run_calculation_for_date_range;
use aims_auth::Claims;
use aims_common::{AimsError, Result};
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    attendance_sessions::{AttendanceSessionRecord, AttendanceSessionRepository},
};
use aims_domain::AttendanceDaily;
use axum::{
    extract::{Path, Query, State},
    routing::{get, post},
    Extension, Json, Router,
};
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct ProcessAttendanceRequest {
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub employee_id: Option<Uuid>,
}

#[derive(Debug, Serialize)]
pub struct ProcessAttendanceResponse {
    pub processed_days: i32,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
}

#[derive(Debug, Deserialize)]
pub struct DailyAttendanceQuery {
    pub start_date: Option<NaiveDate>,
    pub end_date: Option<NaiveDate>,
}

#[derive(Debug, Serialize)]
pub struct DailyDetailResponse {
    pub daily: AttendanceDaily,
    pub sessions: Vec<AttendanceSessionRecord>,
}

pub async fn process_attendance(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(payload): Json<ProcessAttendanceRequest>,
) -> Result<Json<ProcessAttendanceResponse>> {
    let pool = state.db.pool();
    let processed_days = run_calculation_for_date_range(
        pool,
        claims.org_id,
        payload.start_date,
        payload.end_date,
        payload.employee_id,
    )
    .await?;

    Ok(Json(ProcessAttendanceResponse {
        processed_days,
        start_date: payload.start_date,
        end_date: payload.end_date,
    }))
}

pub async fn list_daily_attendance(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Query(query): Query<DailyAttendanceQuery>,
) -> Result<Json<Vec<AttendanceDaily>>> {
    let pool = state.db.pool();
    let today = chrono::Utc::now().date_naive();
    let start_date = query.start_date.unwrap_or(today);
    let end_date = query.end_date.unwrap_or(today);

    let records = DailyAttendanceRepository::list_by_organization_and_date_range(
        pool,
        claims.org_id,
        start_date,
        end_date,
    )
    .await?;

    // Filter section scope if user lacks global view permission
    if !claims.roles.contains(&"SYSTEM_ADMIN".to_string())
        && !claims.roles.contains(&"ORG_ADMIN".to_string())
        && !claims.permissions.contains(&"attendance.view.all".to_string())
    {
        let filtered = records
            .into_iter()
            .filter(|r| claims.section_ids.contains(&r.section_id))
            .collect();
        return Ok(Json(filtered));
    }

    Ok(Json(records))
}

pub async fn get_daily_detail(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<DailyDetailResponse>> {
    let pool = state.db.pool();
    let daily = DailyAttendanceRepository::find_by_id(pool, id)
        .await?
        .ok_or_else(|| AimsError::NotFound(format!("Daily attendance record '{}' not found", id)))?;

    let sessions = AttendanceSessionRepository::list_by_daily(pool, daily.id).await?;

    Ok(Json(DailyDetailResponse { daily, sessions }))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/process", post(process_attendance))
        .route("/daily", get(list_daily_attendance))
        .route("/daily/{id}", get(get_daily_detail))
}
