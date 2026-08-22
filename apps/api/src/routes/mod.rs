pub mod attendance;
pub mod attendance_rules;
pub mod auth;
pub mod designations;
pub mod employees;
pub mod health;
pub mod imports;
pub mod organizations;
pub mod sections;

use crate::{middleware::security, state::AppState};
use axum::{
    Router, middleware,
    routing::{get, post},
};

pub fn router(state: AppState) -> Router<AppState> {
    let public_routes = Router::new()
        .route("/health/live", get(health::live))
        .route("/health/ready", get(health::ready))
        .route("/auth/login", post(auth::login));

    let protected_routes = Router::new()
        .route("/auth/logout", post(auth::logout))
        .route("/auth/me", get(auth::me))
        // Organizations
        .route(
            "/organizations",
            get(organizations::list_organizations).post(organizations::create_organization),
        )
        .route("/organizations/{id}", get(organizations::get_organization))
        // Sections
        .route(
            "/sections",
            get(sections::list_sections).post(sections::create_section),
        )
        .route(
            "/sections/{id}",
            get(sections::get_section).patch(sections::update_section),
        )
        .route("/sections/{id}/activate", post(sections::activate_section))
        .route(
            "/sections/{id}/deactivate",
            post(sections::deactivate_section),
        )
        // Designations
        .route(
            "/designations",
            get(designations::list_designations).post(designations::create_designation),
        )
        .route(
            "/designations/{id}",
            get(designations::get_designation).patch(designations::update_designation),
        )
        .route(
            "/designations/{id}/activate",
            post(designations::activate_designation),
        )
        .route(
            "/designations/{id}/deactivate",
            post(designations::deactivate_designation),
        )
        // Attendance Rules
        .route(
            "/attendance-rules",
            get(attendance_rules::list_rules).post(attendance_rules::create_rule),
        )
        .route(
            "/attendance-rules/{id}",
            get(attendance_rules::get_rule).patch(attendance_rules::update_rule),
        )
        // Employees
        .route(
            "/employees",
            get(employees::list_employees).post(employees::create_employee),
        )
        .route(
            "/employees/{id}",
            get(employees::get_employee).patch(employees::update_employee),
        )
        .route(
            "/employees/{id}/activate",
            post(employees::activate_employee),
        )
        .route(
            "/employees/{id}/deactivate",
            post(employees::deactivate_employee),
        )
        .route(
            "/employees/{id}/transfer",
            post(employees::transfer_employee),
        )
        // Imports
        .route("/imports/preview", post(imports::preview_import))
        .route("/imports/commit", post(imports::commit_import))
        .route("/imports/batches", get(imports::list_batches))
        .route(
            "/imports/templates",
            get(imports::list_templates).post(imports::create_template),
        )
        // Attendance Calculation & Queries
        .nest("/attendance", attendance::routes())
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            security::require_auth,
        ));

    public_routes.merge(protected_routes)
}
