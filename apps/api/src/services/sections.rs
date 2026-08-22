use aims_auth::CurrentUser;
use aims_database::repositories::{audit::AuditLogRepository, sections::SectionRepository};
use aims_domain::Section;
use serde::Deserialize;
use uuid::Uuid;
use validator::Validate;

use crate::{error::AppError, state::AppState};

#[derive(Debug, Deserialize, Validate)]
pub struct CreateSectionRequest {
    #[validate(length(min = 2, max = 32))]
    pub code: String,
    #[validate(length(min = 1, max = 128))]
    pub name: String,
    pub parent_section_id: Option<Uuid>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateSectionRequest {
    #[validate(length(min = 1, max = 128))]
    pub name: Option<String>,
    pub parent_section_id: Option<Option<Uuid>>,
}

#[derive(Debug, Deserialize)]
pub struct SectionQuery {
    pub search: Option<String>,
    pub active: Option<bool>,
    pub parent_id: Option<String>,
}

pub struct SectionService;

impl SectionService {
    pub async fn create_section(
        state: &AppState,
        actor: &CurrentUser,
        req: CreateSectionRequest,
    ) -> Result<Section, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        let uppercase_code = req.code.to_uppercase();

        if SectionRepository::find_by_code(&state.db, actor.organization_id, &uppercase_code)
            .await?
            .is_some()
        {
            return Err(AppError::Conflict(format!(
                "Section code '{}' already exists",
                uppercase_code
            )));
        }

        if let Some(parent_id) = req.parent_section_id {
            let parent =
                SectionRepository::find_by_id(&state.db, actor.organization_id, parent_id).await?;
            if parent.is_none() {
                return Err(AppError::Validation(format!(
                    "Parent section {} not found",
                    parent_id
                )));
            }
        }

        let section = SectionRepository::create(
            &state.db,
            actor.organization_id,
            &uppercase_code,
            &req.name,
            req.parent_section_id,
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "SECTION_CREATED",
            "sections",
            Some(section.id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(section)
    }

    pub async fn update_section(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
        req: UpdateSectionRequest,
    ) -> Result<Section, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        let _existing = SectionRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Section {} not found", id)))?;

        if let Some(Some(new_parent_id)) = req.parent_section_id {
            if new_parent_id == id {
                return Err(AppError::Validation(
                    "Section cannot be its own parent".to_string(),
                ));
            }

            let parent =
                SectionRepository::find_by_id(&state.db, actor.organization_id, new_parent_id)
                    .await?;
            if parent.is_none() {
                return Err(AppError::Validation(format!(
                    "Parent section {} not found",
                    new_parent_id
                )));
            }

            let is_circular =
                SectionRepository::check_circular_reference(&state.db, id, new_parent_id).await?;
            if is_circular {
                return Err(AppError::Validation(
                    "Setting this parent creates a circular section hierarchy".to_string(),
                ));
            }
        }

        let updated = SectionRepository::update(
            &state.db,
            actor.organization_id,
            id,
            req.name.as_deref(),
            req.parent_section_id,
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "SECTION_UPDATED",
            "sections",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(updated)
    }

    pub async fn set_section_active(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
        active: bool,
    ) -> Result<Section, AppError> {
        let _ = SectionRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Section {} not found", id)))?;

        let updated =
            SectionRepository::set_active(&state.db, actor.organization_id, id, active).await?;

        let action = if active {
            "SECTION_ACTIVATED"
        } else {
            "SECTION_DEACTIVATED"
        };
        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            action,
            "sections",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(updated)
    }

    pub async fn get_section(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
    ) -> Result<Section, AppError> {
        SectionRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Section {} not found", id)))
    }

    pub async fn list_sections(
        state: &AppState,
        actor: &CurrentUser,
        query: SectionQuery,
    ) -> Result<Vec<Section>, AppError> {
        let parsed_parent_id: Option<Option<Uuid>> = match query.parent_id.as_deref() {
            Some("null") | Some("none") => Some(None),
            Some(uuid_str) => {
                Some(Some(uuid_str.parse().map_err(|_| {
                    AppError::Validation("Invalid parent_id UUID".to_string())
                })?))
            }
            None => None,
        };

        let sections = SectionRepository::list_filtered(
            &state.db,
            actor.organization_id,
            query.search.as_deref(),
            query.active,
            parsed_parent_id,
        )
        .await?;

        Ok(sections)
    }
}
