use aims_auth::Claims;
use aims_common::AimsError;
use axum::Extension;

pub struct RequirePermission;

impl RequirePermission {
    pub fn check(Extension(claims): Extension<Claims>, required_permission: &str) -> Result<(), AimsError> {
        // SYSTEM_ADMIN and ORG_ADMIN bypass all fine-grained permission checks
        if claims.roles.contains(&"SYSTEM_ADMIN".to_string())
            || claims.roles.contains(&"ORG_ADMIN".to_string())
        {
            return Ok(());
        }

        if claims.permissions.iter().any(|p| p == required_permission) {
            return Ok(());
        }

        Err(AimsError::Forbidden(format!(
            "User '{}' lacks required permission '{}'",
            claims.username, required_permission
        )))
    }

    pub fn check_section_access(
        Extension(claims): Extension<Claims>,
        target_section_id: uuid::Uuid,
    ) -> Result<(), AimsError> {
        if claims.roles.contains(&"SYSTEM_ADMIN".to_string())
            || claims.roles.contains(&"ORG_ADMIN".to_string())
            || claims.permissions.contains(&"attendance.view.all".to_string())
        {
            return Ok(());
        }

        if claims.permissions.contains(&"attendance.view.section".to_string())
            && claims.section_ids.contains(&target_section_id)
        {
            return Ok(());
        }

        Err(AimsError::Forbidden(format!(
            "User '{}' is not authorized to access section '{}'",
            claims.username, target_section_id
        )))
    }
}
