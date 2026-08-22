use crate::{
    api::response::{ApiResponse, PaginatedResponse},
    error::AppError,
    services::exceptions::ExceptionsService,
    state::AppState,
};
use aims_auth::CurrentUser;
use aims_database::repositories::exceptions::ExceptionFilter;
use axum::{
    Extension, Json, Router,
    extract::{Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::get,
};
use chrono::NaiveDate;
use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct ExceptionsQuery {
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
    pub section_id: Option<Uuid>,
    pub employee_id: Option<Uuid>,
    pub exception_type: Option<String>,
    pub page: Option<i64>,
    pub page_size: Option<i64>,
}

pub fn routes() -> Router<AppState> {
    Router::new().route("/", get(list_exceptions_handler))
}

pub async fn list_exceptions_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<ExceptionsQuery>,
) -> Result<impl IntoResponse, AppError> {
    let page = query.page.unwrap_or(1).max(1);
    let page_size = query.page_size.unwrap_or(20).clamp(1, 100);
    let offset = (page - 1) * page_size;

    let filter = ExceptionFilter {
        date_from: query.date_from,
        date_to: query.date_to,
        section_id: query.section_id,
        employee_id: query.employee_id,
        exception_type: query.exception_type,
        limit: page_size,
        offset,
    };

    let (items, total) =
        ExceptionsService::list_exceptions(&state.db, actor.organization_id, filter).await?;
    let paginated = PaginatedResponse::new(items, page as u32, page_size as u32, total as u64);

    Ok((StatusCode::OK, Json(ApiResponse::ok(paginated))))
}
