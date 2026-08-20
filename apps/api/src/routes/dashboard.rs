use axum::{response::IntoResponse, routing::get, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct DashboardSummaryResponse {
    pub date: String,
    pub total_employees: u32,
    pub present: u32,
    pub late: u32,
    pub absent: u32,
    pub incomplete: u32,
    pub attendance_rate: f64,
}

pub async fn get_summary() -> impl IntoResponse {
    axum::Json(DashboardSummaryResponse {
        date: "2026-08-20".into(),
        total_employees: 286,
        present: 251,
        late: 19,
        absent: 16,
        incomplete: 7,
        attendance_rate: 87.76,
    })
}

use crate::state::AppState;

pub fn router() -> Router<AppState> {
    Router::new().route("/summary", get(get_summary))
}
