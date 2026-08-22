pub mod auth;
pub mod health;

use crate::{middleware::security, state::AppState};
use axum::{
    Router, middleware,
    routing::{get, post},
};

pub fn router(state: AppState) -> Router<AppState> {
    let public_routes = Router::new()
        .route("/health/live", get(health::live))
        .route("/health/ready", get(health::ready))
        .route("/auth/login", post(auth::login));

    let protected_routes = Router::new()
        .route("/auth/logout", post(auth::logout))
        .route("/auth/me", get(auth::me))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            security::require_auth,
        ));

    public_routes.merge(protected_routes)
}
