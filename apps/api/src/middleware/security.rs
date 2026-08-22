use aims_auth::{CurrentUser, hash_session_token};
use aims_database::repositories::{sessions::UserSessionRepository, users::UserRepository};
use axum::{
    Json,
    extract::State,
    http::{Request, StatusCode, header},
    middleware::Next,
    response::Response,
};
use axum_extra::extract::cookie::CookieJar;

use crate::{error::ErrorResponse, state::AppState};

pub async fn require_auth(
    State(state): State<AppState>,
    jar: CookieJar,
    mut req: Request<axum::body::Body>,
    next: Next,
) -> Result<Response, (StatusCode, Json<ErrorResponse>)> {
    let token = jar
        .get(&state.config.session_cookie_name)
        .map(|c| c.value().to_string())
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    success: false,
                    code: "UNAUTHORIZED",
                    message: "Authentication required".to_string(),
                }),
            )
        })?;

    let token_hash = hash_session_token(&token);

    let session = UserSessionRepository::find_active_by_hash(&state.db, &token_hash)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    success: false,
                    code: "DATABASE_ERROR",
                    message: "Failed to query session".to_string(),
                }),
            )
        })?
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    success: false,
                    code: "UNAUTHORIZED",
                    message: "Session is invalid or expired".to_string(),
                }),
            )
        })?;

    let user = UserRepository::find_by_id(&state.db, session.user_id)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    success: false,
                    code: "DATABASE_ERROR",
                    message: "Failed to query user".to_string(),
                }),
            )
        })?
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    success: false,
                    code: "UNAUTHORIZED",
                    message: "User account not found".to_string(),
                }),
            )
        })?;

    if user.status != aims_domain::UserStatus::Active {
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(ErrorResponse {
                success: false,
                code: "UNAUTHORIZED",
                message: "Account is inactive or suspended".to_string(),
            }),
        ));
    }

    #[allow(clippy::collapsible_if)]
    if let Some(locked_until) = user.locked_until {
        if locked_until > chrono::Utc::now() {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    success: false,
                    code: "UNAUTHORIZED",
                    message: "Account is temporarily locked".to_string(),
                }),
            ));
        }
    }

    let roles = UserRepository::get_user_roles(&state.db, user.id)
        .await
        .unwrap_or_default();

    let permissions = UserRepository::get_user_permissions(&state.db, user.id)
        .await
        .unwrap_or_default();

    let section_ids = UserRepository::get_user_section_ids(&state.db, user.id)
        .await
        .unwrap_or_default();

    let current_user = CurrentUser {
        user_id: user.id,
        organization_id: user.organization_id,
        username: user.username,
        roles,
        permissions,
        section_ids,
    };

    let _ = UserSessionRepository::touch_last_seen(&state.db, session.id).await;

    req.extensions_mut().insert(current_user);

    let mut response = next.run(req).await;
    response
        .headers_mut()
        .insert(header::CACHE_CONTROL, "no-store".parse().unwrap());

    Ok(response)
}
