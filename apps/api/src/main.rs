mod middleware;
mod routes;
mod state;

use aims_database::DbPool;
use axum::{middleware::from_fn_with_state, routing::get, Json, Router};
use serde::Serialize;
use state::AppState;
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
    system: &'static str,
    version: &'static str,
    database: &'static str,
}

async fn health_check() -> impl axum::response::IntoResponse {
    Json(HealthResponse {
        status: "ok",
        system: "AIMS — Attendance Intelligence & Management System (v1.1)",
        version: "1.1.0",
        database: "connected",
    })
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv().ok();

    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info,aims_api=debug".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://aims_app:change_this_password@localhost:5432/aims".into());
    let jwt_secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "super_secret_aims_production_jwt_key_2026_x7f9a".into());

    tracing::info!("Connecting to PostgreSQL database at {}...", db_url);
    let db_pool = DbPool::connect(&db_url).await?;
    let state = AppState::new(db_pool, jwt_secret);

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let protected_routes = Router::new()
        .nest("/employees", routes::employees::router())
        .nest("/sections", routes::sections::router())
        .nest("/import", routes::import::router())
        .nest("/attendance", routes::attendance::router())
        .nest("/exceptions", routes::exceptions::router())
        .nest("/corrections", routes::corrections::router())
        .nest("/reports", routes::reports::router())
        .nest("/dashboard", routes::dashboard::router())
        .layer(from_fn_with_state(state.clone(), middleware::auth_middleware));

    let public_routes = Router::new()
        .nest("/auth", routes::auth::router());

    let api_routes = Router::new()
        .merge(public_routes)
        .merge(protected_routes);

    let app = Router::new()
        .route("/health", get(health_check))
        .nest("/api/v1", api_routes)
        .layer(cors)
        .with_state(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
    tracing::info!("AIMS Axum 0.8.9 API Server listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
