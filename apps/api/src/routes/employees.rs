use crate::state::AppState;
use aims_auth::Claims;
use aims_common::{AimsError, Result};
use aims_database::repositories::employees::EmployeeRepository;
use aims_domain::Employee;
use axum::{
    extract::{Path, Query, State},
    routing::{get, post},
    Extension, Json, Router,
};
use chrono::NaiveDate;
use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct CreateEmployeeRequest {
    pub organization_id: Uuid,
    pub employee_code: String,
    pub attendance_device_user_id: String,
    pub first_name: String,
    pub last_name: String,
    pub email: Option<String>,
    pub mobile: Option<String>,
    pub section_id: Uuid,
    pub designation_id: Uuid,
    pub attendance_rule_id: Uuid,
    pub joining_date: NaiveDate,
}

#[derive(Debug, Deserialize)]
pub struct EmployeeFilterQuery {
    pub section_id: Option<Uuid>,
}

pub async fn create_employee(
    State(state): State<AppState>,
    Json(payload): Json<CreateEmployeeRequest>,
) -> Result<Json<Employee>> {
    let pool = state.db.pool();
    let emp = EmployeeRepository::create(
        pool,
        payload.organization_id,
        &payload.employee_code,
        &payload.attendance_device_user_id,
        &payload.first_name,
        &payload.last_name,
        payload.email.as_deref(),
        payload.mobile.as_deref(),
        payload.section_id,
        payload.designation_id,
        payload.attendance_rule_id,
        payload.joining_date,
    )
    .await?;

    Ok(Json(emp))
}

pub async fn list_employees(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Query(filter): Query<EmployeeFilterQuery>,
) -> Result<Json<Vec<Employee>>> {
    let pool = state.db.pool();

    if let Some(sec_id) = filter.section_id {
        let emps = EmployeeRepository::list_by_section(pool, sec_id).await?;
        return Ok(Json(emps));
    }

    let employees = EmployeeRepository::list_by_organization(pool, claims.org_id).await?;

    // Filter section scope if user lacks global view permission
    if !claims.roles.contains(&"SYSTEM_ADMIN".to_string())
        && !claims.roles.contains(&"ORG_ADMIN".to_string())
        && !claims.permissions.contains(&"attendance.view.all".to_string())
    {
        let filtered = employees
            .into_iter()
            .filter(|e| claims.section_ids.contains(&e.section_id))
            .collect();
        return Ok(Json(filtered));
    }

    Ok(Json(employees))
}

pub async fn get_employee(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Employee>> {
    let pool = state.db.pool();
    let emp = EmployeeRepository::find_by_id(pool, id)
        .await?
        .ok_or_else(|| AimsError::NotFound(format!("Employee '{}' not found", id)))?;

    Ok(Json(emp))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", post(create_employee).get(list_employees))
        .route("/{id}", get(get_employee))
}
