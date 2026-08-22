use crate::{
    api::response::ApiResponse,
    error::AppError,
    services::corrections::{
        CorrectionService, RejectCorrectionPayload, RequestCorrectionPayload,
    },
    state::AppState,
};
use aims_auth::CurrentUser;
use aims_domain::CorrectionStatus;
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Extension, Json, Router,
};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct CorrectionsQuery {
    pub status: Option<CorrectionStatus>,
}

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/request", post(request_correction_handler))
        .route("/", get(list_corrections_handler))
        .route("/{id}/approve", post(approve_correction_handler))
        .route("/{id}/reject", post(reject_correction_handler))
}

pub async fn request_correction_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<RequestCorrectionPayload>,
) -> Result<impl IntoResponse, AppError> {
    let corr = CorrectionService::request_correction(&state.db, &actor, payload).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(corr))))
}

pub async fn list_corrections_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Query(query): Query<CorrectionsQuery>,
) -> Result<impl IntoResponse, AppError> {
    let items = CorrectionService::list_corrections(&state.db, &actor, query.status).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(items))))
}

pub async fn approve_correction_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let approved = CorrectionService::approve_correction(&state.db, &actor, id).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(approved))))
}

pub async fn reject_correction_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<RejectCorrectionPayload>,
) -> Result<impl IntoResponse, AppError> {
    let rejected = CorrectionService::reject_correction(&state.db, &actor, id, payload).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(rejected))))
}
