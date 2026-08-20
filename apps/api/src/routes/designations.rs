use crate::state::AppState;
use aims_auth::Claims;
use aims_common::Result;
use aims_database::repositories::designations::DesignationRepository;
use aims_domain::Designation;
use axum::{
    extract::State,
    routing::post,
    Extension, Json, Router,
};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct CreateDesignationRequest {
    pub organization_id: Uuid,
    pub code: String,
    pub title: String,
    pub level: Option<i32>,
}

pub async fn create_designation(
    State(state): State<AppState>,
    Json(payload): Json<CreateDesignationRequest>,
) -> Result<Json<Designation>> {
    let pool = state.db.pool();
    let level = payload.level.unwrap_or(1);
    let des = DesignationRepository::create(
        pool,
        payload.organization_id,
        &payload.code,
        &payload.title,
        level,
    )
    .await?;

    Ok(Json(des))
}

pub async fn list_designations(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<Vec<Designation>>> {
    let pool = state.db.pool();
    let designations = DesignationRepository::list_by_organization(pool, claims.org_id).await?;

    Ok(Json(designations))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", post(create_designation).get(list_designations))
}
