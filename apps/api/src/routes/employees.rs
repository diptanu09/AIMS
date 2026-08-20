use axum::{extract::Json, response::IntoResponse, routing::get, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct EmployeeListResponse {
    pub total: u32,
}

pub async fn list_employees() -> impl IntoResponse {
    Json(EmployeeListResponse { total: 0 })
}

pub fn router() -> Router {
    Router::new().route("/", get(list_employees))
}
