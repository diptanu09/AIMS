use axum::{extract::Json, response::IntoResponse, routing::post, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct LoginResponse {
    pub token: String,
}

pub async fn login() -> impl IntoResponse {
    Json(LoginResponse {
        token: "stub_token".into(),
    })
}

pub fn router() -> Router {
    Router::new().route("/login", post(login))
}
