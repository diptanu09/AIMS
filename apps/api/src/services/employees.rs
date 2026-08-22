use aims_auth::CurrentUser;
use aims_database::repositories::{
    attendance_rules::AttendanceRuleRepository,
    audit::AuditLogRepository,
    designations::DesignationRepository,
    employees::{EmployeeFilter, EmployeeRepository},
    sections::SectionRepository,
};
use aims_domain::{Employee, EmployeeStatus};
use chrono::NaiveDate;
use serde::Deserialize;
use uuid::Uuid;
use validator::Validate;

use crate::{api::response::PaginatedResponse, error::AppError, state::AppState};

#[derive(Debug, Deserialize, Validate)]
pub struct CreateEmployeeRequest {
    #[validate(length(min = 1, max = 64))]
    pub employee_code: String,
    #[validate(length(min = 1, max = 64))]
    pub attendance_device_user_id: String,
    #[validate(length(min = 1, max = 64))]
    pub first_name: String,
    pub middle_name: Option<String>,
    pub last_name: Option<String>,
    #[validate(email)]
    pub email: Option<String>,
    pub mobile: Option<String>,
    pub section_id: Uuid,
    pub designation_id: Uuid,
    pub attendance_rule_id: Uuid,
    pub joining_date: NaiveDate,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateEmployeeRequest {
    #[validate(length(min = 1, max = 64))]
    pub first_name: Option<String>,
    pub middle_name: Option<Option<String>>,
    pub last_name: Option<Option<String>>,
    #[validate(email)]
    pub email: Option<Option<String>>,
    pub mobile: Option<Option<String>>,
    pub designation_id: Option<Uuid>,
    pub attendance_rule_id: Option<Uuid>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct TransferEmployeeRequest {
    pub new_section_id: Uuid,
    pub effective_date: NaiveDate,
    pub reason: Option<String>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct EmployeeStatusTransitionRequest {
    pub status: EmployeeStatus,
    pub leaving_date: Option<NaiveDate>,
    pub reason: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct EmployeeQuery {
    pub page: Option<u32>,
    pub page_size: Option<u32>,
    pub search: Option<String>,
    pub section_id: Option<Uuid>,
    pub designation_id: Option<Uuid>,
    pub status: Option<EmployeeStatus>,
    pub attendance_rule_id: Option<Uuid>,
    pub joining_date_from: Option<NaiveDate>,
    pub joining_date_to: Option<NaiveDate>,
}

pub struct EmployeeService;

impl EmployeeService {
    pub async fn create_employee(
        state: &AppState,
        actor: &CurrentUser,
        req: CreateEmployeeRequest,
    ) -> Result<Employee, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        // Section authorization check
        if !actor.has_permission("attendance.view.all") && !actor.can_access_section(req.section_id)
        {
            return Err(AppError::Forbidden(
                "Access denied: You are not authorized to create employees in this section"
                    .to_string(),
            ));
        }

        // Validate section exists in org
        if SectionRepository::find_by_id(&state.db, actor.organization_id, req.section_id)
            .await?
            .is_none()
        {
            return Err(AppError::Validation(format!(
                "Section {} not found",
                req.section_id
            )));
        }

        // Validate designation exists in org
        if DesignationRepository::find_by_id(&state.db, actor.organization_id, req.designation_id)
            .await?
            .is_none()
        {
            return Err(AppError::Validation(format!(
                "Designation {} not found",
                req.designation_id
            )));
        }

        // Validate attendance rule exists in org
        if AttendanceRuleRepository::find_by_id(
            &state.db,
            actor.organization_id,
            req.attendance_rule_id,
        )
        .await?
        .is_none()
        {
            return Err(AppError::Validation(format!(
                "Attendance rule {} not found",
                req.attendance_rule_id
            )));
        }

        // Validate employee code uniqueness
        if EmployeeRepository::find_by_code(&state.db, actor.organization_id, &req.employee_code)
            .await?
            .is_some()
        {
            return Err(AppError::Conflict(format!(
                "Employee code '{}' already exists",
                req.employee_code
            )));
        }

        // Validate attendance device user id uniqueness
        if EmployeeRepository::find_by_device_user_id(
            &state.db,
            actor.organization_id,
            &req.attendance_device_user_id,
        )
        .await?
        .is_some()
        {
            return Err(AppError::Conflict(format!(
                "Attendance device user ID '{}' is already assigned to an employee",
                req.attendance_device_user_id
            )));
        }

        let emp = EmployeeRepository::create(
            &state.db,
            actor.organization_id,
            &req.employee_code,
            &req.attendance_device_user_id,
            &req.first_name,
            req.middle_name.as_deref(),
            req.last_name.as_deref(),
            req.email.as_deref(),
            req.mobile.as_deref(),
            req.section_id,
            req.designation_id,
            req.attendance_rule_id,
            req.joining_date,
            EmployeeStatus::Active,
            Some(actor.user_id),
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "EMPLOYEE_CREATED",
            "employees",
            Some(emp.id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(emp)
    }

    pub async fn get_employee(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
    ) -> Result<Employee, AppError> {
        let emp = EmployeeRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Employee {} not found", id)))?;

        if !actor.has_permission("attendance.view.all") && !actor.can_access_section(emp.section_id)
        {
            return Err(AppError::Forbidden(
                "Access denied: You do not have authorization to view this employee".to_string(),
            ));
        }

        Ok(emp)
    }

    pub async fn update_employee(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
        req: UpdateEmployeeRequest,
    ) -> Result<Employee, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        let current = EmployeeRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Employee {} not found", id)))?;

        if !actor.has_permission("attendance.view.all")
            && !actor.can_access_section(current.section_id)
        {
            return Err(AppError::Forbidden(
                "Access denied: You are not authorized to update employees in this section"
                    .to_string(),
            ));
        }

        #[allow(clippy::collapsible_if)]
        if let Some(des_id) = req.designation_id {
            if DesignationRepository::find_by_id(&state.db, actor.organization_id, des_id)
                .await?
                .is_none()
            {
                return Err(AppError::Validation(format!(
                    "Designation {} not found",
                    des_id
                )));
            }
        }

        #[allow(clippy::collapsible_if)]
        if let Some(rule_id) = req.attendance_rule_id {
            if AttendanceRuleRepository::find_by_id(&state.db, actor.organization_id, rule_id)
                .await?
                .is_none()
            {
                return Err(AppError::Validation(format!(
                    "Attendance rule {} not found",
                    rule_id
                )));
            }
        }

        let updated = EmployeeRepository::update(
            &state.db,
            actor.organization_id,
            id,
            req.first_name.as_deref(),
            req.middle_name.as_ref().map(|o| o.as_deref()),
            req.last_name.as_ref().map(|o| o.as_deref()),
            req.email.as_ref().map(|o| o.as_deref()),
            req.mobile.as_ref().map(|o| o.as_deref()),
            req.designation_id,
            req.attendance_rule_id,
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "EMPLOYEE_UPDATED",
            "employees",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(updated)
    }

    pub async fn transfer_employee(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
        req: TransferEmployeeRequest,
    ) -> Result<Employee, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        let current = EmployeeRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Employee {} not found", id)))?;

        if !actor.has_permission("attendance.view.all")
            && !actor.can_access_section(current.section_id)
        {
            return Err(AppError::Forbidden(
                "Access denied: You are not authorized to transfer employees out of this section"
                    .to_string(),
            ));
        }

        if !actor.has_permission("attendance.view.all")
            && !actor.can_access_section(req.new_section_id)
        {
            return Err(AppError::Forbidden(
                "Access denied: You are not authorized to transfer employees into target section"
                    .to_string(),
            ));
        }

        if SectionRepository::find_by_id(&state.db, actor.organization_id, req.new_section_id)
            .await?
            .is_none()
        {
            return Err(AppError::Validation(format!(
                "Target section {} not found",
                req.new_section_id
            )));
        }

        let updated = EmployeeRepository::transfer_section(
            &state.db,
            actor.organization_id,
            id,
            req.new_section_id,
            req.effective_date,
            req.reason.as_deref(),
            Some(actor.user_id),
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "EMPLOYEE_SECTION_TRANSFERRED",
            "employees",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(updated)
    }

    pub async fn change_employee_status(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
        req: EmployeeStatusTransitionRequest,
    ) -> Result<Employee, AppError> {
        let current = EmployeeRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Employee {} not found", id)))?;

        if !actor.has_permission("attendance.view.all")
            && !actor.can_access_section(current.section_id)
        {
            return Err(AppError::Forbidden(
                "Access denied: You are not authorized for this section".to_string(),
            ));
        }

        let updated = EmployeeRepository::update_status(
            &state.db,
            actor.organization_id,
            id,
            req.status,
            req.leaving_date,
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "EMPLOYEE_STATUS_CHANGED",
            "employees",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(updated)
    }

    pub async fn list_employees(
        state: &AppState,
        actor: &CurrentUser,
        query: EmployeeQuery,
    ) -> Result<PaginatedResponse<Employee>, AppError> {
        let page = query.page.unwrap_or(1);
        let page_size = query.page_size.unwrap_or(25);

        let allowed_section_ids = if actor.has_permission("attendance.view.all") {
            None
        } else {
        #[allow(clippy::collapsible_if)]
        if let Some(target_sec) = query.section_id {
                if !actor.can_access_section(target_sec) {
                    return Err(AppError::Forbidden(
                        "Access denied: You do not have access to this section".to_string(),
                    ));
                }
            }
            Some(actor.section_ids.clone())
        };

        let filter = EmployeeFilter {
            search: query.search.as_deref(),
            section_id: query.section_id,
            designation_id: query.designation_id,
            status: query.status,
            attendance_rule_id: query.attendance_rule_id,
            joining_date_from: query.joining_date_from,
            joining_date_to: query.joining_date_to,
            allowed_section_ids,
        };

        let (items, total) = EmployeeRepository::list_paginated(
            &state.db,
            actor.organization_id,
            filter,
            page,
            page_size,
        )
        .await?;

        Ok(PaginatedResponse::new(items, page, page_size, total))
    }
}
