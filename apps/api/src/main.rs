use aims_auth::hash_password;
use aims_database::repositories::{organizations::OrganizationRepository, users::UserRepository};
use axum::{
    Router,
    http::{HeaderValue, Method, header},
};
use sqlx::postgres::PgPoolOptions;
use std::{env, sync::Arc};
use tower_http::{
    compression::CompressionLayer, cors::CorsLayer, timeout::TimeoutLayer, trace::TraceLayer,
};
use tracing::info;

mod api;
mod config;
mod error;
mod middleware;
mod routes;
mod services;
mod state;

use config::Config;
use state::AppState;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(env::var("RUST_LOG").unwrap_or_else(|_| "info,aims_api=debug".to_string()))
        .with_target(true)
        .with_thread_ids(true)
        .compact()
        .init();

    let config = Config::from_env()?;

    let args: Vec<String> = env::args().collect();

    // Check for CLI bootstrap command: cargo run -p aims-api -- admin create [username] [email] [password]
    if args.len() >= 3 && args[1] == "admin" && args[2] == "create" {
        let db = PgPoolOptions::new().connect(&config.database_url).await?;

        let username = args.get(3).cloned().unwrap_or_else(|| "admin".to_string());
        let email = args
            .get(4)
            .cloned()
            .unwrap_or_else(|| "admin@aims.internal".to_string());
        let password = args
            .get(5)
            .cloned()
            .unwrap_or_else(|| "Admin@Aims123!".to_string());

        info!(username = %username, email = %email, "bootstrapping administrative user");

        // Ensure default organization exists
        let org = match OrganizationRepository::find_by_code(&db, "DEFAULT").await? {
            Some(o) => o,
            None => {
                OrganizationRepository::create(
                    &db,
                    "DEFAULT",
                    "Default Organization",
                    "Asia/Kolkata",
                )
                .await?
            }
        };

        let password_hash = hash_password(&password)?;

        let user = match UserRepository::find_by_username(&db, &username).await? {
            Some(u) => u,
            None => {
                UserRepository::create(
                    &db,
                    org.id,
                    &username,
                    &email,
                    &password_hash,
                    "System Administrator",
                )
                .await?
            }
        };

        // Assign SUPER_ADMIN role
        let role = sqlx::query_scalar::<_, uuid::Uuid>(
            "SELECT id FROM roles WHERE organization_id = $1 AND name = 'SUPER_ADMIN'",
        )
        .bind(org.id)
        .fetch_optional(&db)
        .await?;

        if let Some(role_id) = role {
            UserRepository::assign_role(&db, user.id, role_id).await?;
        }

        info!(username = %username, "administrative user created successfully");
        return Ok(());
    }

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

    if let Err(e) = auto_bootstrap_admin(&db).await {
        tracing::warn!("Auto-bootstrap admin check notice: {:?}", e);
    }

    let state = AppState {
        config: Arc::new(config.clone()),
        db,
    };

    let cors = CorsLayer::new()
        .allow_origin(tower_http::cors::AllowOrigin::mirror_request())
        .allow_methods([
            Method::GET,
            Method::POST,
            Method::PUT,
            Method::DELETE,
            Method::OPTIONS,
        ])
        .allow_headers([
            header::AUTHORIZATION,
            header::ACCEPT,
            header::CONTENT_TYPE,
            header::COOKIE,
        ])
        .allow_credentials(true);

    let app = Router::new()
        .nest("/api/v1", routes::router(state.clone()))
        .with_state(state)
        .layer(TraceLayer::new_for_http())
        .layer(CompressionLayer::new())
        .layer(TimeoutLayer::with_status_code(
            axum::http::StatusCode::REQUEST_TIMEOUT,
            std::time::Duration::from_secs(30),
        ))
        .layer(cors);

    let listener = tokio::net::TcpListener::bind(config.bind_address()).await?;

    info!(
        address = %listener.local_addr()?,
        "AIMS API listening"
    );

    axum::serve(listener, app).await?;

    Ok(())
}

async fn auto_bootstrap_admin(db: &sqlx::PgPool) -> anyhow::Result<()> {
    let username = "admin";
    let email = "admin@aims.internal";
    let password = "Admin@Aims123!";

    let org = match OrganizationRepository::find_by_code(db, "DEFAULT").await? {
        Some(o) => o,
        None => {
            OrganizationRepository::create(
                db,
                "DEFAULT",
                "Default Organization",
                "Asia/Kolkata",
            )
            .await?
        }
    };

    let user = match UserRepository::find_by_username(db, username).await? {
        Some(u) => u,
        None => {
            let password_hash = hash_password(password)?;
            UserRepository::create(
                db,
                org.id,
                username,
                email,
                &password_hash,
                "System Administrator",
            )
            .await?
        }
    };

    let role = sqlx::query_scalar::<_, uuid::Uuid>(
        "SELECT id FROM roles WHERE organization_id = $1 AND name = 'SUPER_ADMIN'",
    )
    .bind(org.id)
    .fetch_optional(db)
    .await?;

    if let Some(role_id) = role {
        let _ = UserRepository::assign_role(db, user.id, role_id).await;
    }

    Ok(())
}
