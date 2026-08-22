use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AimsError {
    #[error("Database error: {0}")]
    Database(String),

    #[error("Authentication error: {0}")]
    Auth(String),

    #[error("Unauthorized: {0}")]
    Unauthorized(String),

    #[error("Forbidden: {0}")]
    Forbidden(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Conflict: {0}")]
    Conflict(String),

    #[error("Validation error: {0}")]
    Validation(String),

    #[error("Import processing error: {0}")]
    Import(String),

    #[error("Calculation error: {0}")]
    Calculation(String),

    #[error("Internal server error: {0}")]
    Internal(String),
}

pub type Result<T> = std::result::Result<T, AimsError>;

#[derive(Serialize)]
pub struct ErrorResponse {
    pub error: String,
    pub code: &'static str,
}

impl IntoResponse for AimsError {
    fn into_response(self) -> Response {
        let (status, code) = match self {
            AimsError::Database(_) => (StatusCode::INTERNAL_SERVER_ERROR, "DATABASE_ERROR"),
            AimsError::Auth(_) => (StatusCode::UNAUTHORIZED, "AUTH_ERROR"),
            AimsError::Unauthorized(_) => (StatusCode::UNAUTHORIZED, "UNAUTHORIZED"),
            AimsError::Forbidden(_) => (StatusCode::FORBIDDEN, "FORBIDDEN"),
            AimsError::NotFound(_) => (StatusCode::NOT_FOUND, "NOT_FOUND"),
            AimsError::Conflict(_) => (StatusCode::CONFLICT, "CONFLICT"),
            AimsError::Validation(_) => (StatusCode::BAD_REQUEST, "VALIDATION_ERROR"),
            AimsError::Import(_) => (StatusCode::UNPROCESSABLE_ENTITY, "IMPORT_ERROR"),
            AimsError::Calculation(_) => (StatusCode::UNPROCESSABLE_ENTITY, "CALCULATION_ERROR"),
            AimsError::Internal(_) => (StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_ERROR"),
        };

        let body = Json(ErrorResponse {
            error: self.to_string(),
            code,
        });

        (status, body).into_response()
    }
}
