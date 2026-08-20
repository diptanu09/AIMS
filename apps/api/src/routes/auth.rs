use crate::state::AppState;
use aims_auth::{generate_token, verify_password, Claims};
use aims_common::{AimsError, Result};
use aims_database::repositories::users::UserRepository;
use axum::{
    extract::State,
    routing::{get, post},
    Extension, Json, Router,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct UserProfileResponse {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub username: String,
    pub email: String,
    pub roles: Vec<String>,
    pub permissions: Vec<String>,
    pub section_ids: Vec<Uuid>,
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub token_type: &'static str,
    pub expires_in_seconds: u64,
    pub user: UserProfileResponse,
}

pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<LoginResponse>> {
    let pool = state.db.pool();

    let user = UserRepository::find_by_username(pool, &payload.username)
        .await?
        .ok_or_else(|| AimsError::Auth("Invalid username or password".into()))?;

    if user.status != aims_domain::UserStatus::Active {
        return Err(AimsError::Auth("User account is inactive or suspended".into()));
    }

    let is_valid = verify_password(&payload.password, &user.password_hash)?;
    if !is_valid {
        return Err(AimsError::Auth("Invalid username or password".into()));
    }

    let roles = UserRepository::get_user_roles(pool, user.id).await?;
    let permissions = UserRepository::get_user_permissions(pool, user.id).await?;
    let section_ids = UserRepository::get_user_section_ids(pool, user.id).await?;

    let token = generate_token(
        user.id,
        user.organization_id,
        &user.username,
        roles.clone(),
        permissions.clone(),
        section_ids.clone(),
        &state.jwt_secret,
        24,
    )?;

    let _ = UserRepository::update_last_login(pool, user.id).await;

    Ok(Json(LoginResponse {
        token,
        token_type: "Bearer",
        expires_in_seconds: 86400,
        user: UserProfileResponse {
            id: user.id,
            organization_id: user.organization_id,
            username: user.username,
            email: user.email,
            roles,
            permissions,
            section_ids,
        },
    }))
}

pub async fn get_me(Extension(claims): Extension<Claims>) -> Json<UserProfileResponse> {
    Json(UserProfileResponse {
        id: claims.sub,
        organization_id: claims.org_id,
        username: claims.username,
        email: "".to_string(),
        roles: claims.roles,
        permissions: claims.permissions,
        section_ids: claims.section_ids,
    })
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/login", post(login))
        .route("/me", get(get_me))
}
