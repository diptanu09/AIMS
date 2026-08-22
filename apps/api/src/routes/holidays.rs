use crate::{
    api::response::ApiResponse,
    error::AppError,
    services::holidays::{CreateHolidayPayload, HolidayService},
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
        .route("/", get(list_holidays_handler).post(create_holiday_handler))
}

pub async fn create_holiday_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<CreateHolidayPayload>,
) -> Result<impl IntoResponse, AppError> {
    let hol = HolidayService::create_holiday(&state.db, &actor, payload).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(hol))))
}

pub async fn list_holidays_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> Result<impl IntoResponse, AppError> {
    let items = HolidayService::list_holidays(&state.db, &actor).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(items))))
}
