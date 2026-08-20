use axum::{response::IntoResponse, routing::get, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct CorrectionsResponse {
    pub total: u32,
}

pub async fn list_corrections() -> impl IntoResponse {
    axum::Json(CorrectionsResponse { total: 0 })
}

use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/", get(list_corrections))
}
