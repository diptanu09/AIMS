use axum::{
    Extension,
    extract::State,
    http::{HeaderMap, StatusCode, header},
    response::{IntoResponse, Json},
};
use axum_extra::extract::cookie::{Cookie, CookieJar, SameSite};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use aims_auth::{CurrentUser, generate_session_token, hash_session_token, verify_password};
use aims_database::repositories::{
    audit::AuditLogRepository, sessions::UserSessionRepository, users::UserRepository,
};

use crate::{api::response::ApiResponse, error::ErrorResponse, state::AppState};

#[derive(Debug, Deserialize)]
pub struct LoginPayload {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct UserSummary {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub username: String,
    pub full_name: String,
    pub roles: Vec<String>,
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub user: UserSummary,
}

#[derive(Debug, Serialize)]
pub struct MeResponse {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub username: String,
    pub roles: Vec<String>,
    pub permissions: Vec<String>,
    pub section_ids: Vec<Uuid>,
}

pub async fn login(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(payload): Json<LoginPayload>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorResponse>)> {
    let client_ip = headers
        .get("x-forwarded-for")
        .and_then(|v| v.to_str().ok())
        .or_else(|| headers.get("x-real-ip").and_then(|v| v.to_str().ok()));

    let user_agent = headers
        .get(header::USER_AGENT)
        .and_then(|v| v.to_str().ok());

    let user_opt = UserRepository::find_by_username(&state.db, &payload.username)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    success: false,
                    code: "DATABASE_ERROR",
                    message: "Database error during login".to_string(),
                }),
            )
        })?;

    let user = match user_opt {
        Some(u) => u,
        None => {
            // Generic security error message to prevent username enumeration
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    success: false,
                    code: "INVALID_CREDENTIALS",
                    message: "Invalid username or password".to_string(),
                }),
            ));
        }
    };

    // Check account status
    if user.status != aims_domain::UserStatus::Active {
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(ErrorResponse {
                success: false,
                code: "ACCOUNT_INACTIVE",
                message: "Account is inactive or suspended".to_string(),
            }),
        ));
    }

    // Check lock state
    #[allow(clippy::collapsible_if)]
    if let Some(locked_until) = user.locked_until {
        if locked_until > chrono::Utc::now() {
            let _ = AuditLogRepository::log(
                &state.db,
                Some(user.organization_id),
                Some(user.id),
                "AUTH_LOGIN_BLOCKED_LOCKED",
                "users",
                Some(user.id),
                None,
                None,
                client_ip,
                user_agent,
            )
            .await;

            return Err((
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    success: false,
                    code: "ACCOUNT_LOCKED",
                    message: "Account is temporarily locked. Please try again later.".to_string(),
                }),
            ));
        }
    }

    // Verify Argon2id password
    let is_valid = verify_password(&payload.password, &user.password_hash).unwrap_or(false);

    if !is_valid {
        let _ = UserRepository::record_failed_login(&state.db, user.id).await;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(user.organization_id),
            Some(user.id),
            "AUTH_LOGIN_FAILED",
            "users",
            Some(user.id),
            None,
            None,
            client_ip,
            user_agent,
        )
        .await;

        return Err((
            StatusCode::UNAUTHORIZED,
            Json(ErrorResponse {
                success: false,
                code: "INVALID_CREDENTIALS",
                message: "Invalid username or password".to_string(),
            }),
        ));
    }

    // Successful login: reset failed counter
    let _ = UserRepository::reset_failed_login_and_update_last_login(&state.db, user.id).await;

    // Generate random opaque session token & hash
    let session_token = generate_session_token();
    let token_hash = hash_session_token(&session_token);

    let expires_at = chrono::Utc::now() + chrono::Duration::hours(state.config.session_ttl_hours);

    let _session = UserSessionRepository::create(
        &state.db,
        user.id,
        &token_hash,
        expires_at,
        client_ip,
        user_agent,
    )
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                success: false,
                code: "SESSION_CREATION_FAILED",
                message: "Failed to create session".to_string(),
            }),
        )
    })?;

    // Fetch user roles
    let roles = UserRepository::get_user_roles(&state.db, user.id)
        .await
        .unwrap_or_default();

    // Log successful audit event
    let _ = AuditLogRepository::log(
        &state.db,
        Some(user.organization_id),
        Some(user.id),
        "AUTH_LOGIN_SUCCESS",
        "users",
        Some(user.id),
        None,
        None,
        client_ip,
        user_agent,
    )
    .await;

    // Build HttpOnly cookie
    let cookie = Cookie::build((state.config.session_cookie_name.clone(), session_token))
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .max_age(time::Duration::seconds(
            state.config.session_ttl_hours * 3600,
        ))
        .secure(state.config.session_cookie_secure)
        .build();

    let jar = CookieJar::new().add(cookie);

    let response_data = ApiResponse::ok(LoginResponse {
        user: UserSummary {
            id: user.id,
            organization_id: user.organization_id,
            username: user.username,
            full_name: user.full_name,
            roles,
        },
    });

    Ok((jar, Json(response_data)))
}

pub async fn logout(
    State(state): State<AppState>,
    jar: CookieJar,
    Extension(current_user): Extension<CurrentUser>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorResponse>)> {
    if let Some(cookie) = jar.get(&state.config.session_cookie_name) {
        let token_hash = hash_session_token(cookie.value());
        let _ = UserSessionRepository::revoke(&state.db, &token_hash).await;
    }

    let client_ip = headers
        .get("x-forwarded-for")
        .and_then(|v| v.to_str().ok())
        .or_else(|| headers.get("x-real-ip").and_then(|v| v.to_str().ok()));

    let user_agent = headers
        .get(header::USER_AGENT)
        .and_then(|v| v.to_str().ok());

    let _ = AuditLogRepository::log(
        &state.db,
        Some(current_user.organization_id),
        Some(current_user.user_id),
        "AUTH_LOGOUT",
        "users",
        Some(current_user.user_id),
        None,
        None,
        client_ip,
        user_agent,
    )
    .await;

    // Clear session cookie
    let removal_cookie = Cookie::build((state.config.session_cookie_name.clone(), ""))
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .max_age(time::Duration::seconds(0))
        .secure(state.config.session_cookie_secure)
        .build();

    let updated_jar = jar.add(removal_cookie);

    Ok((
        updated_jar,
        Json(ApiResponse::ok("Logged out successfully")),
    ))
}

pub async fn me(Extension(current_user): Extension<CurrentUser>) -> Json<ApiResponse<MeResponse>> {
    Json(ApiResponse::ok(MeResponse {
        id: current_user.user_id,
        organization_id: current_user.organization_id,
        username: current_user.username,
        roles: current_user.roles,
        permissions: current_user.permissions,
        section_ids: current_user.section_ids,
    }))
}
