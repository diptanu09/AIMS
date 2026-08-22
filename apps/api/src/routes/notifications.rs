use aims_auth::CurrentUser;
use aims_database::repositories::notifications::NotificationRepository;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Extension, Json, Router,
};
use uuid::Uuid;

use crate::{error::ErrorResponse, state::AppState};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/", get(list_notifications))
        .route("/{id}/read", post(mark_read))
}

async fn list_notifications(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> std::result::Result<impl IntoResponse, (StatusCode, Json<ErrorResponse>)> {
    let records = NotificationRepository::list_unread_for_user(&state.db, actor.user_id, 20)
        .await
        .map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    success: false,
                    code: "DATABASE_ERROR",
                    message: e.to_string(),
                }),
            )
        })?;

    Ok(Json(records))
}

async fn mark_read(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> std::result::Result<impl IntoResponse, (StatusCode, Json<ErrorResponse>)> {
    NotificationRepository::mark_read(&state.db, id, actor.user_id)
        .await
        .map_err(|e| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    success: false,
                    code: "DATABASE_ERROR",
                    message: e.to_string(),
                }),
            )
        })?;

    Ok(StatusCode::OK)
}
