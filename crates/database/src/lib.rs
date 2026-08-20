use aims_common::{AimsError, Result};
use sqlx::{postgres::PgPoolOptions, PgPool};
use std::time::Duration;

#[derive(Clone)]
pub struct DbPool {
    pub inner: PgPool,
}

impl DbPool {
    pub async fn connect(database_url: &str) -> Result<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(20)
            .acquire_timeout(Duration::from_secs(5))
            .connect(database_url)
            .await
            .map_err(|e| AimsError::Database(format!("Failed to connect to PostgreSQL: {}", e)))?;

        Ok(Self { inner: pool })
    }
}
