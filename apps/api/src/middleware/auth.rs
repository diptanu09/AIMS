use crate::state::AppState;
use aims_auth::{verify_token, Claims};
use aims_common::AimsError;
use axum::{
    extract::{Request, State},
    http::header,
    middleware::Next,
    response::Response,
};

pub async fn auth_middleware(
    State(state): State<AppState>,
    mut req: Request,
    next: Next,
) -> Result<Response, AimsError> {
    let auth_header = req
        .headers()
        .get(header::AUTHORIZATION)
        .and_then(|val| val.to_str().ok())
        .ok_or_else(|| AimsError::Auth("Missing Authorization header".into()))?;

    if !auth_header.starts_with("Bearer ") {
        return Err(AimsError::Auth(
            "Invalid Authorization header format (expected Bearer <token>)".into(),
        ));
    }

    let token = &auth_header[7..];
    let claims = verify_token(token, &state.jwt_secret)?;

    req.extensions_mut().insert(claims);

    Ok(next.run(req).await)
}
