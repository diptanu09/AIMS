use aims_auth::CurrentUser;
use aims_database::repositories::{
    audit::AuditLogRepository, organizations::OrganizationRepository,
};
use aims_domain::Organization;
use serde::Deserialize;
use uuid::Uuid;
use validator::Validate;

use crate::{error::AppError, state::AppState};

#[derive(Debug, Deserialize, Validate)]
pub struct CreateOrganizationRequest {
    #[validate(length(min = 2, max = 32))]
    pub code: String,
    #[validate(length(min = 1, max = 128))]
    pub name: String,
    #[validate(length(min = 1, max = 64))]
    pub timezone: String,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize, Validate)]
pub struct UpdateOrganizationRequest {
    #[validate(length(min = 1, max = 128))]
    pub name: Option<String>,
    #[validate(length(min = 1, max = 64))]
    pub timezone: Option<String>,
}

pub struct OrganizationService;

impl OrganizationService {
    pub async fn create_organization(
        state: &AppState,
        actor: &CurrentUser,
        req: CreateOrganizationRequest,
    ) -> Result<Organization, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        let uppercase_code = req.code.to_uppercase();

        let _tz: chrono_tz::Tz = req.timezone.parse().map_err(|_| {
            AppError::Validation(format!("Invalid IANA timezone string: {}", req.timezone))
        })?;

        if OrganizationRepository::find_by_code(&state.db, &uppercase_code)
            .await?
            .is_some()
        {
            return Err(AppError::Conflict(format!(
                "Organization code '{}' already exists",
                uppercase_code
            )));
        }

        let org =
            OrganizationRepository::create(&state.db, &uppercase_code, &req.name, &req.timezone)
                .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(org.id),
            Some(actor.user_id),
            "ORGANIZATION_CREATED",
            "organizations",
            Some(org.id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(org)
    }

    pub async fn get_organization(state: &AppState, id: Uuid) -> Result<Organization, AppError> {
        OrganizationRepository::find_by_id(&state.db, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Organization {} not found", id)))
    }

    pub async fn list_organizations(state: &AppState) -> Result<Vec<Organization>, AppError> {
        let orgs = OrganizationRepository::list_all(&state.db).await?;
        Ok(orgs)
    }
}
