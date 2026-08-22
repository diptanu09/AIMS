use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Extension, Json,
};
use aims_auth::CurrentUser;
use uuid::Uuid;

use crate::{
    api::response::ApiResponse,
    error::AppError,
    services::organizations::{CreateOrganizationRequest, OrganizationService},
    state::AppState,
};

pub async fn create_organization(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<CreateOrganizationRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !actor.has_permission("organization.manage") && !actor.roles.contains(&"SUPER_ADMIN".to_string()) {
        return Err(AppError::Forbidden("Only Super Administrators can create organizations".to_string()));
    }

    let org = OrganizationService::create_organization(&state, &actor, payload).await?;
    Ok((StatusCode::CREATED, Json(ApiResponse::ok(org))))
}

pub async fn get_organization(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let org = OrganizationService::get_organization(&state, id).await?;
    Ok(Json(ApiResponse::ok(org)))
}

pub async fn list_organizations(
    State(state): State<AppState>,
) -> Result<impl IntoResponse, AppError> {
    let orgs = OrganizationService::list_organizations(&state).await?;
    Ok(Json(ApiResponse::ok(orgs)))
}
