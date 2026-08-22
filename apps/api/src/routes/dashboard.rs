use crate::{
    api::response::ApiResponse, error::AppError, services::dashboard::DashboardService,
    state::AppState,
};
use aims_auth::CurrentUser;
use axum::{
    Extension, Json, Router,
    extract::{Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::get,
};
use chrono::{Local, NaiveDate};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct DashboardDateQuery {
    pub date: Option<NaiveDate>,
}

#[derive(Debug, Deserialize)]
pub struct DashboardTrendQuery {
    pub from: Option<NaiveDate>,
    pub to: Option<NaiveDate>,
    pub section_id: Option<Uuid>,
}

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/summary", get(get_summary_handler))
        .route("/sections", get(get_sections_handler))
        .route("/trends", get(get_trends_handler))
}

pub async fn get_summary_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<DashboardDateQuery>,
) -> Result<impl IntoResponse, AppError> {
    let date = query.date.unwrap_or_else(|| Local::now().date_naive());
    let summary = DashboardService::get_summary(&state.db, actor.organization_id, date).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(summary))))
}

pub async fn get_sections_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<DashboardDateQuery>,
) -> Result<impl IntoResponse, AppError> {
    let date = query.date.unwrap_or_else(|| Local::now().date_naive());
    let sections = DashboardService::get_sections(&state.db, actor.organization_id, date).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(sections))))
}

pub async fn get_trends_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<DashboardTrendQuery>,
) -> Result<impl IntoResponse, AppError> {
    let today = Local::now().date_naive();
    let to_date = query.to.unwrap_or(today);
    let from_date = query
        .from
        .unwrap_or_else(|| to_date - chrono::Duration::days(30));

    let trends = DashboardService::get_trends(
        &state.db,
        actor.organization_id,
        from_date,
        to_date,
        query.section_id,
    )
    .await?;

    Ok((StatusCode::OK, Json(ApiResponse::ok(trends))))
}
