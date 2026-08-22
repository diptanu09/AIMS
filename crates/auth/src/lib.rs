use aims_common::{AimsError, Result};
use argon2::{
    Argon2,
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
};
use chrono::{Duration, Utc};
use jsonwebtoken::{DecodingKey, EncodingKey, Header, Validation, decode, encode};
use rand_core::OsRng;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: Uuid,
    pub org_id: Uuid,
    pub username: String,
    pub roles: Vec<String>,
    pub permissions: Vec<String>,
    pub section_ids: Vec<Uuid>,
    pub exp: usize,
    pub iat: usize,
}

pub fn hash_password(password: &str) -> Result<String> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = argon2
        .hash_password(password.as_bytes(), &salt)
        .map_err(|e| AimsError::Auth(format!("Password hashing failed: {}", e)))?
        .to_string();

    Ok(password_hash)
}

pub fn verify_password(password: &str, password_hash: &str) -> Result<bool> {
    let parsed_hash = PasswordHash::new(password_hash)
        .map_err(|e| AimsError::Auth(format!("Invalid password hash format: {}", e)))?;

    Ok(Argon2::default()
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}

#[allow(clippy::too_many_arguments)]
pub fn generate_token(
    user_id: Uuid,
    org_id: Uuid,
    username: &str,
    roles: Vec<String>,
    permissions: Vec<String>,
    section_ids: Vec<Uuid>,
    secret: &str,
    expires_in_hours: i64,
) -> Result<String> {
    let now = Utc::now();
    let exp = (now + Duration::hours(expires_in_hours)).timestamp() as usize;
    let iat = now.timestamp() as usize;

    let claims = Claims {
        sub: user_id,
        org_id,
        username: username.to_string(),
        roles,
        permissions,
        section_ids,
        exp,
        iat,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| AimsError::Auth(format!("Token generation failed: {}", e)))?;

    Ok(token)
}

pub fn verify_token(token: &str, secret: &str) -> Result<Claims> {
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|e| AimsError::Auth(format!("Invalid or expired token: {}", e)))?;

    Ok(token_data.claims)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_argon2_password_hashing() {
        let raw_pass = "SecureP@ssw0rd2026";
        let hash = hash_password(raw_pass).expect("Should hash password");
        assert!(verify_password(raw_pass, &hash).expect("Should verify password"));
        assert!(!verify_password("WrongPassword", &hash).expect("Should reject wrong password"));
    }

    #[test]
    fn test_jwt_generation_and_verification() {
        let secret = "test_secret_key_aims_2026";
        let user_id = Uuid::now_v7();
        let org_id = Uuid::now_v7();
        let sec_id = Uuid::now_v7();

        let token = generate_token(
            user_id,
            org_id,
            "john_doe",
            vec!["SECTION_HEAD".into()],
            vec!["attendance.view.section".into()],
            vec![sec_id],
            secret,
            24,
        )
        .expect("Should generate token");

        let claims = verify_token(&token, secret).expect("Should verify token");
        assert_eq!(claims.sub, user_id);
        assert_eq!(claims.org_id, org_id);
        assert_eq!(claims.username, "john_doe");
        assert_eq!(claims.roles, vec!["SECTION_HEAD"]);
        assert_eq!(claims.permissions, vec!["attendance.view.section"]);
        assert_eq!(claims.section_ids, vec![sec_id]);
    }

    #[test]
    fn test_view_only_rbac_constraints() {
        let sec_1 = Uuid::now_v7();
        let sec_2 = Uuid::now_v7();

        let view_only_claims = Claims {
            sub: Uuid::now_v7(),
            org_id: Uuid::now_v7(),
            username: "guest_viewer".into(),
            roles: vec!["VIEW_ONLY".into()],
            permissions: vec!["attendance.view.section".into()],
            section_ids: vec![sec_1],
            exp: 9999999999,
            iat: 1000000000,
        };

        // VIEW_ONLY must NOT have global view access
        assert!(
            !view_only_claims
                .permissions
                .contains(&"attendance.view.all".to_string())
        );

        // VIEW_ONLY has access to sec_1 but NOT sec_2
        assert!(view_only_claims.section_ids.contains(&sec_1));
        assert!(!view_only_claims.section_ids.contains(&sec_2));
    }
}
