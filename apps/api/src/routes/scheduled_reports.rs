use aims_auth::CurrentUser;
use aims_database::repositories::scheduled_reports::ScheduledReportRepository;
use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::get,
    Extension, Json, Router,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::{error::ErrorResponse, state::AppState};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/", get(list_scheduled_reports).post(create_scheduled_report))
}

#[derive(Debug, Deserialize)]
pub struct CreateScheduledReportPayload {
    pub name: String,
    pub cron_expression: String,
    pub report_type: String,
    pub section_id: Option<Uuid>,
    pub recipients: Vec<String>,
}

async fn list_scheduled_reports(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> std::result::Result<impl IntoResponse, (StatusCode, Json<ErrorResponse>)> {
    let records = ScheduledReportRepository::list_by_organization(&state.db, actor.organization_id)
        .await
        .map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    success: false,
                    code: "DATABASE_ERROR",
                    message: e.to_string(),
                }),
            )
        })?;

    Ok(Json(records))
}

async fn create_scheduled_report(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<CreateScheduledReportPayload>,
) -> std::result::Result<impl IntoResponse, (StatusCode, Json<ErrorResponse>)> {
    let recipients_json = serde_json::to_value(&payload.recipients).unwrap_or_default();
    let record = ScheduledReportRepository::create(
        &state.db,
        actor.organization_id,
        &payload.name,
        &payload.cron_expression,
        &payload.report_type,
        payload.section_id,
        recipients_json,
        Some(actor.user_id),
    )
    .await
    .map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                success: false,
                code: "DATABASE_ERROR",
                message: e.to_string(),
            }),
        )
    })?;

    Ok((StatusCode::CREATED, Json(record)))
}
