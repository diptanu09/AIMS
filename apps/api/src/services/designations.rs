use aims_auth::CurrentUser;
use aims_database::repositories::{audit::AuditLogRepository, designations::DesignationRepository};
use aims_domain::Designation;
use serde::Deserialize;
use uuid::Uuid;
use validator::Validate;

use crate::{error::AppError, state::AppState};

#[derive(Debug, Deserialize, Validate)]
pub struct CreateDesignationRequest {
    #[validate(length(min = 2, max = 32))]
    pub code: String,
    #[validate(length(min = 1, max = 128))]
    pub title: String,
    #[validate(range(min = 1))]
    pub level: i32,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateDesignationRequest {
    #[validate(length(min = 1, max = 128))]
    pub title: Option<String>,
    #[validate(range(min = 1))]
    pub level: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct DesignationQuery {
    pub search: Option<String>,
    pub active: Option<bool>,
}

pub struct DesignationService;

impl DesignationService {
    pub async fn create_designation(
        state: &AppState,
        actor: &CurrentUser,
        req: CreateDesignationRequest,
    ) -> Result<Designation, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        let uppercase_code = req.code.to_uppercase();

        if DesignationRepository::find_by_code(&state.db, actor.organization_id, &uppercase_code)
            .await?
            .is_some()
        {
            return Err(AppError::Conflict(format!(
                "Designation code '{}' already exists",
                uppercase_code
            )));
        }

        let des = DesignationRepository::create(
            &state.db,
            actor.organization_id,
            &uppercase_code,
            &req.title,
            req.level,
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "DESIGNATION_CREATED",
            "designations",
            Some(des.id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(des)
    }

    pub async fn update_designation(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
        req: UpdateDesignationRequest,
    ) -> Result<Designation, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        let _ = DesignationRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Designation {} not found", id)))?;

        let updated = DesignationRepository::update(
            &state.db,
            actor.organization_id,
            id,
            req.title.as_deref(),
            req.level,
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "DESIGNATION_UPDATED",
            "designations",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(updated)
    }

    pub async fn set_designation_active(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
        active: bool,
    ) -> Result<Designation, AppError> {
        let _ = DesignationRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Designation {} not found", id)))?;

        let updated =
            DesignationRepository::set_active(&state.db, actor.organization_id, id, active).await?;

        let action = if active {
            "DESIGNATION_ACTIVATED"
        } else {
            "DESIGNATION_DEACTIVATED"
        };
        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            action,
            "designations",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(updated)
    }

    pub async fn get_designation(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
    ) -> Result<Designation, AppError> {
        DesignationRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Designation {} not found", id)))
    }

    pub async fn list_designations(
        state: &AppState,
        actor: &CurrentUser,
        query: DesignationQuery,
    ) -> Result<Vec<Designation>, AppError> {
        let designations = DesignationRepository::list_filtered(
            &state.db,
            actor.organization_id,
            query.search.as_deref(),
            query.active,
        )
        .await?;

        Ok(designations)
    }
}
