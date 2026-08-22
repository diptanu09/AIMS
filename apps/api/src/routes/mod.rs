pub mod health;

use crate::state::AppState;
use axum::{Router, routing::get};

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/health/live", get(health::live))
        .route("/health/ready", get(health::ready))
}
