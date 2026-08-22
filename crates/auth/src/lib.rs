pub mod current_user;
pub mod password;
pub mod permissions;
pub mod session;

pub use current_user::CurrentUser;
pub use password::{hash_password, verify_password};
pub use permissions::{can_access_section, can_approve_correction, has_permission};
pub use session::{generate_session_token, hash_session_token};

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    #[test]
    fn test_password_hashing_and_verification() {
        let password = "SecretPassword123!";
        let hash = hash_password(password).unwrap();
        assert!(verify_password(password, &hash).unwrap());
        assert!(!verify_password("WrongPassword", &hash).unwrap());
    }

    #[test]
    fn test_session_token_hashing() {
        let token = generate_session_token();
        assert_eq!(token.len(), 64);

        let hash1 = hash_session_token(&token);
        let hash2 = hash_session_token(&token);
        assert_eq!(hash1.len(), 64);
        assert_eq!(hash1, hash2);
    }

    #[test]
    fn test_section_access_and_separation_of_duties() {
        let sec1 = Uuid::now_v7();
        let sec2 = Uuid::now_v7();
        let user_id = Uuid::now_v7();

        let bo_user = CurrentUser {
            user_id,
            organization_id: Uuid::now_v7(),
            username: "bo_user".into(),
            roles: vec!["BO".into()],
            permissions: vec!["attendance.view.section".into()],
            section_ids: vec![sec1],
        };

        assert!(can_access_section(&bo_user, sec1));
        assert!(!can_access_section(&bo_user, sec2));

        // Separation of duties check
        assert!(!can_approve_correction(&bo_user, user_id));
        assert!(can_approve_correction(&bo_user, Uuid::now_v7()));
    }
}
