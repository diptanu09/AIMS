use aims_common::AimsError;
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
    #[error("validation error: {0}")]
    Validation(String),

    #[error("not found: {0}")]
    NotFound(String),

    #[error("conflict: {0}")]
    Conflict(String),

    #[error("forbidden: {0}")]
    Forbidden(String),

    #[error("unauthorized: {0}")]
    Unauthorized(String),

    #[error("configuration error: {0}")]
    Configuration(#[from] anyhow::Error),

    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),

    #[allow(dead_code)]
    #[error("internal server error")]
    Internal,
}

impl From<AimsError> for AppError {
    fn from(err: AimsError) -> Self {
        match err {
            AimsError::NotFound(msg) => AppError::NotFound(msg),
            AimsError::Validation(msg) => AppError::Validation(msg),
            AimsError::Conflict(msg) => AppError::Conflict(msg),
            AimsError::Unauthorized(msg) => AppError::Unauthorized(msg),
            AimsError::Auth(msg) => AppError::Unauthorized(msg),
            AimsError::Forbidden(msg) => AppError::Forbidden(msg),
            AimsError::Database(msg) => AppError::Validation(msg),
            AimsError::Import(msg) => AppError::Validation(msg),
            AimsError::Calculation(msg) => AppError::Validation(msg),
            AimsError::Internal(msg) => AppError::Validation(msg),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code, message) = match self {
            Self::Validation(msg) => (StatusCode::BAD_REQUEST, "VALIDATION_ERROR", msg),
            Self::NotFound(msg) => (StatusCode::NOT_FOUND, "NOT_FOUND", msg),
            Self::Conflict(msg) => (StatusCode::CONFLICT, "CONFLICT", msg),
            Self::Forbidden(msg) => (StatusCode::FORBIDDEN, "FORBIDDEN", msg),
            Self::Unauthorized(msg) => (StatusCode::UNAUTHORIZED, "UNAUTHORIZED", msg),
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
