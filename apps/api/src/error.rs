use axum::{
    Json,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use serde::Serialize;
use tracing::error;

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub success: bool,
    pub code: &'static str,
    pub message: String,
}

#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("configuration error: {0}")]
    Configuration(#[from] anyhow::Error),

    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),

    #[allow(dead_code)]
    #[error("internal server error")]
    Internal,
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code, message) = match self {
            Self::Configuration(error) => {
                error!(%error, "configuration error");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "CONFIGURATION_ERROR",
                    "Server configuration error".to_string(),
                )
            }
            Self::Database(error) => {
                error!(%error, "database error");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "DATABASE_ERROR",
                    "Database operation failed".to_string(),
                )
            }
            Self::Internal => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "INTERNAL_ERROR",
                "Internal server error".to_string(),
            ),
        };

        (
            status,
            Json(ErrorResponse {
                success: false,
                code,
                message,
            }),
        )
            .into_response()
    }
}
