mod middleware;
mod routes;
mod state;

use axum::{routing::get, Json, Router};
use serde::Serialize;
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
    system: &'static str,
    version: &'static str,
}

async fn health_check() -> impl axum::response::IntoResponse {
    Json(HealthResponse {
        status: "ok",
        system: "AIMS — Attendance Intelligence & Management System (v1.1 Baseline)",
        version: "1.1.0",
    })
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info,aims_api=debug".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let api_routes = Router::new()
        .nest("/auth", routes::auth::router())
        .nest("/employees", routes::employees::router())
        .nest("/sections", routes::sections::router())
        .nest("/import", routes::import::router())
        .nest("/attendance", routes::attendance::router())
        .nest("/exceptions", routes::exceptions::router())
        .nest("/corrections", routes::corrections::router())
        .nest("/reports", routes::reports::router())
        .nest("/dashboard", routes::dashboard::router());

    let app = Router::new()
        .route("/health", get(health_check))
        .nest("/api/v1", api_routes)
        .layer(cors);

    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
    tracing::info!("AIMS Axum 0.8.9 API Server (v1.1) listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
