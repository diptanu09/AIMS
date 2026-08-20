use crate::state::AppState;
use aims_common::{AimsError, Result};
use aims_database::repositories::organizations::OrganizationRepository;
use aims_domain::Organization;
use axum::{
    extract::{Path, State},
    routing::{get, post},
    Json, Router,
};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct CreateOrganizationRequest {
    pub code: String,
    pub name: String,
    pub timezone: Option<String>,
}

pub async fn create_organization(
    State(state): State<AppState>,
    Json(payload): Json<CreateOrganizationRequest>,
) -> Result<Json<Organization>> {
    let pool = state.db.pool();
    let tz = payload.timezone.as_deref().unwrap_or("Asia/Kolkata");

    let org = OrganizationRepository::create(pool, &payload.code, &payload.name, tz).await?;
    Ok(Json(org))
}

pub async fn list_organizations(
    State(state): State<AppState>,
) -> Result<Json<Vec<Organization>>> {
    let pool = state.db.pool();
    let orgs = OrganizationRepository::list_all(pool).await?;
    Ok(Json(orgs))
}

pub async fn get_organization(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Organization>> {
    let pool = state.db.pool();
    let org = OrganizationRepository::find_by_id(pool, id)
        .await?
        .ok_or_else(|| AimsError::NotFound(format!("Organization '{}' not found", id)))?;

    Ok(Json(org))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", post(create_organization).get(list_organizations))
        .route("/{id}", get(get_organization))
}
