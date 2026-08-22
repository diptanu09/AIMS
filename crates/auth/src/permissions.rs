use crate::current_user::CurrentUser;
use uuid::Uuid;

pub fn has_permission(user: &CurrentUser, permission: &str) -> bool {
    // SUPER_ADMIN and ADMIN bypass specific permission checks
    if user
        .roles
        .iter()
        .any(|r| r == "SUPER_ADMIN" || r == "ADMIN")
    {
        return true;
    }
    user.permissions.iter().any(|p| p == permission)
}

pub fn can_access_section(user: &CurrentUser, section_id: Uuid) -> bool {
    // If user has attendance.view.all or SUPER_ADMIN / ADMIN / ATTENDANCE_ADMIN role, section access is unrestricted
    if user
        .roles
        .iter()
        .any(|r| r == "SUPER_ADMIN" || r == "ADMIN" || r == "ATTENDANCE_ADMIN")
        || has_permission(user, "attendance.view.all")
    {
        return true;
    }
    user.section_ids.contains(&section_id)
}

pub fn can_approve_correction(user: &CurrentUser, requester_user_id: Uuid) -> bool {
    // Separation of duties enforcement: requester cannot be approver
    user.user_id != requester_user_id
}
