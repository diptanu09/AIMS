use axum::{response::IntoResponse, routing::post, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct ProcessResponse {
    pub processed_days: u32,
}

pub async fn process_attendance() -> impl IntoResponse {
    axum::Json(ProcessResponse { processed_days: 0 })
}

pub fn router() -> Router {
    Router::new().route("/process", post(process_attendance))
}
