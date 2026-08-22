use crate::permissions;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct CurrentUser {
    pub user_id: Uuid,
    pub organization_id: Uuid,
    pub username: String,
    pub roles: Vec<String>,
    pub permissions: Vec<String>,
    pub section_ids: Vec<Uuid>,
}

impl CurrentUser {
    pub fn has_permission(&self, permission: &str) -> bool {
        permissions::has_permission(self, permission)
    }

    pub fn can_access_section(&self, section_id: Uuid) -> bool {
        permissions::can_access_section(self, section_id)
    }

    pub fn can_approve_correction(&self, requester_user_id: Uuid) -> bool {
        permissions::can_approve_correction(self, requester_user_id)
    }
}
