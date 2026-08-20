use axum::{response::IntoResponse, routing::get, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct ReportResponse {
    pub report_id: String,
}

pub async fn generate_report() -> impl IntoResponse {
    axum::Json(ReportResponse {
        report_id: "rep_1001".into(),
    })
}

pub fn router() -> Router {
    Router::new().route("/generate", get(generate_report))
}
