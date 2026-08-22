use anyhow::{Context, Result};
use std::env;

#[derive(Clone, Debug)]
pub struct Config {
    pub app_name: String,
    pub app_env: String,
    pub app_timezone: String,
    pub database_url: String,
    pub api_host: String,
    pub api_port: u16,
    #[allow(dead_code)]
    pub web_origin: String,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        dotenvy::dotenv().ok();

        let api_port = env::var("API_PORT")
            .unwrap_or_else(|_| "8080".to_string())
            .parse::<u16>()
            .context("API_PORT must be a valid u16")?;

        Ok(Self {
            app_name: env::var("APP_NAME").unwrap_or_else(|_| "AIMS".to_string()),
            app_env: env::var("APP_ENV").unwrap_or_else(|_| "development".to_string()),
            app_timezone: env::var("APP_TIMEZONE").unwrap_or_else(|_| "Asia/Kolkata".to_string()),
            database_url: env::var("DATABASE_URL").context("DATABASE_URL is required")?,
            api_host: env::var("API_HOST").unwrap_or_else(|_| "127.0.0.1".to_string()),
            api_port,
            web_origin: env::var("WEB_ORIGIN")
                .unwrap_or_else(|_| "http://localhost:3000".to_string()),
        })
    }

    pub fn bind_address(&self) -> String {
        format!("{}:{}", self.api_host, self.api_port)
    }
}
