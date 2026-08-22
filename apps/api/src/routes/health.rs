use crate::{api::response::ApiResponse, error::AppError, state::AppState};
use axum::{extract::State, response::Json};
use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct HealthResponse {
    pub service: String,
    pub status: &'static str,
}

pub async fn live(State(state): State<AppState>) -> Json<ApiResponse<HealthResponse>> {
    Json(ApiResponse::ok(HealthResponse {
        service: state.config.app_name.clone(),
        status: "healthy",
    }))
}

pub async fn ready(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<HealthResponse>>, AppError> {
    sqlx::query("SELECT 1").execute(&state.db).await?;

    Ok(Json(ApiResponse::ok(HealthResponse {
        service: state.config.app_name.clone(),
        status: "ready",
    })))
}
