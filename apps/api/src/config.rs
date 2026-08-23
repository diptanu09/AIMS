use anyhow::{Context, Result};
use std::env;

#[allow(dead_code)]
#[derive(Clone, Debug)]
pub struct Config {
    pub app_name: String,
    pub app_env: String,
    pub app_timezone: String,
    pub database_url: String,
    pub api_host: String,
    pub api_port: u16,
    pub web_origin: String,
    pub session_ttl_hours: i64,
    pub session_cookie_name: String,
    pub session_cookie_secure: bool,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        dotenvy::dotenv().ok();

        let api_port = env::var("API_PORT")
            .unwrap_or_else(|_| "8080".to_string())
            .parse::<u16>()
            .context("API_PORT must be a valid u16")?;

        let session_ttl_hours = env::var("SESSION_TTL_HOURS")
            .unwrap_or_else(|_| "8".to_string())
            .parse::<i64>()
            .unwrap_or(8);

        let session_cookie_name =
            env::var("SESSION_COOKIE_NAME").unwrap_or_else(|_| "aims_session".to_string());

        let session_cookie_secure = env::var("SESSION_COOKIE_SECURE")
            .unwrap_or_else(|_| "false".to_string())
            .parse::<bool>()
            .unwrap_or(false);

        Ok(Self {
            app_name: env::var("APP_NAME").unwrap_or_else(|_| "AIMS".to_string()),
            app_env: env::var("APP_ENV").unwrap_or_else(|_| "development".to_string()),
            app_timezone: env::var("APP_TIMEZONE").unwrap_or_else(|_| "Asia/Kolkata".to_string()),
            database_url: env::var("DATABASE_URL").context("DATABASE_URL is required")?,
            api_host: env::var("API_HOST").unwrap_or_else(|_| "127.0.0.1".to_string()),
            api_port,
            web_origin: env::var("WEB_ORIGIN")
                .unwrap_or_else(|_| "http://localhost:3000".to_string()),
            session_ttl_hours,
            session_cookie_name,
            session_cookie_secure,
        })
    }

    pub fn bind_address(&self) -> String {
        format!("{}:{}", self.api_host, self.api_port)
    }
}
