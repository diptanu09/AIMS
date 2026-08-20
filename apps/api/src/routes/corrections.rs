use axum::{response::IntoResponse, routing::get, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct CorrectionsResponse {
    pub total: u32,
}

pub async fn list_corrections() -> impl IntoResponse {
    axum::Json(CorrectionsResponse { total: 0 })
}

pub fn router() -> Router {
    Router::new().route("/", get(list_corrections))
}
