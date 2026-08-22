use crate::{
    api::response::ApiResponse,
    error::AppError,
    services::leave::{LeaveService, SubmitLeavePayload},
    state::AppState,
};
use aims_auth::CurrentUser;
use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::get,
    Extension, Json, Router,
};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/", get(list_leave_handler).post(submit_leave_handler))
}

pub async fn submit_leave_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<SubmitLeavePayload>,
) -> Result<impl IntoResponse, AppError> {
    let leave_id = LeaveService::submit_leave(&state.db, &actor, payload).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(leave_id))))
}

pub async fn list_leave_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> Result<impl IntoResponse, AppError> {
    let items = LeaveService::list_leave(&state.db, &actor).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(items))))
}
