use crate::{api::response::ApiResponse, error::AppError, state::AppState};
use aims_auth::CurrentUser;
use aims_database::repositories::audit::AuditLogRepository;
use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::get,
    Extension, Json, Router,
};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct AuditQuery {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

pub fn routes() -> Router<AppState> {
    Router::new().route("/", get(list_audit_logs_handler))
}

pub async fn list_audit_logs_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<AuditQuery>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("audit.view") && !actor.has_permission("attendance.view.all") {
        return Err(AppError::Forbidden(
            "Permission 'audit.view' required".into(),
        ));
    }

    let limit = query.limit.unwrap_or(50).clamp(1, 200);
    let offset = query.offset.unwrap_or(0).max(0);

    let logs = AuditLogRepository::list_recent(&state.db, actor.organization_id, limit, offset).await?;

    Ok((StatusCode::OK, Json(ApiResponse::ok(logs))))
}
