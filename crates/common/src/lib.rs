use thiserror::Error;

#[derive(Error, Debug)]
pub enum AimsError {
    #[error("Database error: {0}")]
    Database(String),

    #[error("Authentication error: {0}")]
    Auth(String),

    #[error("Forbidden: {0}")]
    Forbidden(String),

    #[error("Not found: {0}")]
    NotFound(String),

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
