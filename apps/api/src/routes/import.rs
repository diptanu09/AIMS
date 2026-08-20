use axum::{extract::Path, response::IntoResponse, routing::get, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct ImportBatchResponse {
    pub batch_id: String,
    pub status: &'static str,
}

pub async fn get_batch(Path(batch_id): Path<String>) -> impl IntoResponse {
    axum::Json(ImportBatchResponse {
        batch_id,
        status: "COMPLETED",
    })
}

pub fn router() -> Router {
    Router::new().route("/{batch_id}", get(get_batch))
}
