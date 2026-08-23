#![allow(clippy::too_many_arguments)]

pub mod repositories;

use aims_common::{AimsError, Result};
use sqlx::{
    PgPool,
    postgres::{PgConnectOptions, PgPoolOptions},
};
use std::{str::FromStr, time::Duration};

pub fn parse_connect_options(database_url: &str) -> Result<PgConnectOptions> {
    let clean_url = database_url.split('?').next().unwrap_or(database_url);
    let options = PgConnectOptions::from_str(clean_url)
        .map_err(|e| AimsError::Database(format!("Invalid DATABASE_URL: {}", e)))?
        .options([("search_path", "\"AIMS\",public")]);
    Ok(options)
}

#[derive(Clone)]
pub struct DbPool {
    pub inner: PgPool,
}

impl DbPool {
    pub async fn connect(database_url: &str) -> Result<Self> {
        let connect_options = parse_connect_options(database_url)?;
        let pool = PgPoolOptions::new()
            .max_connections(20)
            .acquire_timeout(Duration::from_secs(5))
            .connect_with(connect_options)
            .await
            .map_err(|e| AimsError::Database(format!("Failed to connect to PostgreSQL: {}", e)))?;

        Ok(Self { inner: pool })
    }

    pub fn pool(&self) -> &PgPool {
        &self.inner
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::repositories::{organizations::OrganizationRepository, sections::SectionRepository};

    #[tokio::test]
    async fn test_repository_crud_flow() {
        let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
            "postgres://postgres:root@123@localhost:5432/AIMS?search_path=AIMS".into()
        });

        let pool_res = DbPool::connect(&db_url).await;
        if let Ok(db_pool) = pool_res {
            let pool = db_pool.pool();
            let test_code = format!("ORG_{}", &uuid::Uuid::now_v7().simple().to_string()[..20]);

            let org = OrganizationRepository::create(pool, &test_code, "Test Corp", "Asia/Kolkata")
                .await
                .expect("Should create org");

            assert_eq!(org.code, test_code);

            let sec = SectionRepository::create(pool, org.id, "SEC_OPS", "Operations", None)
                .await
                .expect("Should create section");

            assert_eq!(sec.code, "SEC_OPS");
            assert_eq!(sec.organization_id, org.id);

            let fetched = OrganizationRepository::find_by_id(pool, org.id)
                .await
                .expect("Should query org")
                .expect("Org should exist");

            assert_eq!(fetched.id, org.id);
        }
    }
}
