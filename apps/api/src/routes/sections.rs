use crate::state::AppState;
use aims_auth::Claims;
use aims_common::Result;
use aims_database::repositories::sections::SectionRepository;
use aims_domain::Section;
use axum::{
    extract::State,
    routing::post,
    Extension, Json, Router,
};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct CreateSectionRequest {
    pub organization_id: Uuid,
    pub code: String,
    pub name: String,
    pub parent_section_id: Option<Uuid>,
}

pub async fn create_section(
    State(state): State<AppState>,
    Json(payload): Json<CreateSectionRequest>,
) -> Result<Json<Section>> {
    let pool = state.db.pool();
    let section = SectionRepository::create(
        pool,
        payload.organization_id,
        &payload.code,
        &payload.name,
        payload.parent_section_id,
    )
    .await?;

    Ok(Json(section))
}

pub async fn list_sections(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<Vec<Section>>> {
    let pool = state.db.pool();
    let sections = SectionRepository::list_by_organization(pool, claims.org_id).await?;

    // Filter section scope if user lacks global view permission
    if !claims.roles.contains(&"SYSTEM_ADMIN".to_string())
        && !claims.roles.contains(&"ORG_ADMIN".to_string())
        && !claims.permissions.contains(&"attendance.view.all".to_string())
    {
        let filtered = sections
            .into_iter()
            .filter(|s| claims.section_ids.contains(&s.id))
            .collect();
        return Ok(Json(filtered));
    }

    Ok(Json(sections))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", post(create_section).get(list_sections))
}
