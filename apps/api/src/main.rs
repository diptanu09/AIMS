use axum::Router;
use sqlx::postgres::PgPoolOptions;
use std::sync::Arc;
use tower_http::{
    compression::CompressionLayer, cors::CorsLayer, timeout::TimeoutLayer, trace::TraceLayer,
};
use tracing::info;

mod api;
mod config;
mod error;
mod middleware;
mod routes;
mod state;

use config::Config;
use state::AppState;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info,aims_api=debug".to_string()),
        )
        .with_target(true)
        .with_thread_ids(true)
        .compact()
        .init();

    let config = Config::from_env()?;

    info!(
        app = %config.app_name,
        environment = %config.app_env,
        timezone = %config.app_timezone,
        "starting AIMS API"
    );

    let db = PgPoolOptions::new()
        .max_connections(10)
        .min_connections(2)
        .acquire_timeout(std::time::Duration::from_secs(5))
        .connect(&config.database_url)
        .await?;

    sqlx::query("SELECT 1").execute(&db).await?;

    info!("database connection verified");

    let state = AppState {
        config: Arc::new(config.clone()),
        db,
    };

    let app = Router::new()
        .nest("/api/v1", routes::router())
        .with_state(state)
        .layer(TraceLayer::new_for_http())
        .layer(CompressionLayer::new())
        .layer(TimeoutLayer::with_status_code(
            axum::http::StatusCode::REQUEST_TIMEOUT,
            std::time::Duration::from_secs(30),
        ))
        .layer(CorsLayer::permissive());

    let listener = tokio::net::TcpListener::bind(config.bind_address()).await?;

    info!(
        address = %listener.local_addr()?,
        "AIMS API listening"
    );

    axum::serve(listener, app).await?;

    Ok(())
}
