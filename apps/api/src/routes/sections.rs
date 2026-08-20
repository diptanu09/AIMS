use axum::{extract::Json, response::IntoResponse, routing::get, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct SectionListResponse {
    pub total: u32,
}

pub async fn list_sections() -> impl IntoResponse {
    Json(SectionListResponse { total: 0 })
}

use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/", get(list_sections))
}
