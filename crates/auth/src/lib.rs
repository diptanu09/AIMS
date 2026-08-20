use aims_common::{AimsError, Result};
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: String,          // user_id
    pub org_id: String,       // organization_id
    pub username: String,
    pub roles: Vec<String>,
    pub permissions: Vec<String>,
    pub exp: usize,
}

pub struct AuthTokenHandler;

impl AuthTokenHandler {
    pub fn hash_password(password: &str) -> Result<String> {
        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
        argon2
            .hash_password(password.as_bytes(), &salt)
            .map(|h| h.to_string())
            .map_err(|e| AimsError::Auth(format!("Password hashing failed: {}", e)))
    }

    pub fn verify_password(password: &str, password_hash: &str) -> Result<bool> {
        let parsed_hash = PasswordHash::new(password_hash)
            .map_err(|e| AimsError::Auth(format!("Invalid password hash format: {}", e)))?;
        Ok(Argon2::default().verify_password(password.as_bytes(), &parsed_hash).is_ok())
    }

    pub fn create_token(claims: &Claims, secret: &str) -> Result<String> {
        encode(
            &Header::default(),
            claims,
            &EncodingKey::from_secret(secret.as_bytes()),
        )
        .map_err(|e| AimsError::Auth(format!("JWT generation failed: {}", e)))
    }

    pub fn verify_token(token: &str, secret: &str) -> Result<Claims> {
        let decoded = decode::<Claims>(
            token,
            &DecodingKey::from_secret(secret.as_bytes()),
            &Validation::default(),
        )
        .map_err(|e| AimsError::Auth(format!("JWT validation failed: {}", e)))?;

        Ok(decoded.claims)
    }
}
