use axum::{response::IntoResponse, routing::get, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct ExceptionsResponse {
    pub total: u32,
}

pub async fn list_exceptions() -> impl IntoResponse {
    axum::Json(ExceptionsResponse { total: 0 })
}

use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/", get(list_exceptions))
}
