use aims_attendance_engine::process_and_persist_employee_date;
use aims_auth::CurrentUser;
use aims_database::repositories::{
    attendance_daily::DailyAttendanceRepository,
    audit::AuditLogRepository,
    corrections::{CorrectionRepository, DetailedCorrectionRow},
    employees::EmployeeRepository,
};
use aims_domain::{AttendanceCorrection, AttendanceStatus, CorrectionStatus};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::AppError;

#[derive(Debug, Deserialize)]
pub struct RequestCorrectionPayload {
    pub attendance_daily_id: Uuid,
    pub corrected_first_in: Option<DateTime<Utc>>,
    pub corrected_last_out: Option<DateTime<Utc>>,
    pub corrected_status: AttendanceStatus,
    pub reason: String,
}

#[derive(Debug, Deserialize)]
pub struct RejectCorrectionPayload {
    pub reason: String,
}

pub struct CorrectionService;

impl CorrectionService {
    pub async fn request_correction(
        pool: &PgPool,
        actor: &CurrentUser,
        payload: RequestCorrectionPayload,
    ) -> Result<AttendanceCorrection, AppError> {
        let daily = DailyAttendanceRepository::find_by_id(pool, payload.attendance_daily_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Daily attendance record not found".into()))?;

        if !actor.has_permission("attendance.view.all")
            && !actor.can_access_section(daily.section_id)
        {
            return Err(AppError::Forbidden(
                "Access denied: You do not have permission for this section".into(),
            ));
        }

        let corr = CorrectionRepository::create(
            pool,
            daily.id,
            actor.user_id,
            daily.first_in,
            daily.last_out,
            daily.status,
            payload.corrected_first_in,
            payload.corrected_last_out,
            payload.corrected_status,
            &payload.reason,
        )
        .await?;

        let _ = AuditLogRepository::log(
            pool,
            Some(actor.organization_id),
            Some(actor.user_id),
            "CORRECTION_REQUESTED",
            "attendance_corrections",
            Some(corr.id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(corr)
    }

    pub async fn list_corrections(
        pool: &PgPool,
        actor: &CurrentUser,
        status: Option<CorrectionStatus>,
    ) -> Result<Vec<DetailedCorrectionRow>, AppError> {
        let items = CorrectionRepository::list_detailed(pool, actor.organization_id, status).await?;
        Ok(items)
    }

    pub async fn approve_correction(
        pool: &PgPool,
        actor: &CurrentUser,
        id: Uuid,
    ) -> Result<AttendanceCorrection, AppError> {
        let corr = CorrectionRepository::find_by_id(pool, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Correction {} not found", id)))?;

        // 1. Self-approval prevention
        if corr.requested_by == actor.user_id {
            return Err(AppError::Forbidden(
                "Self-approval prohibited: You cannot approve a correction you requested yourself"
                    .into(),
            ));
        }

        // 2. Permission check
        if !actor.has_permission("attendance.approve") && !actor.has_permission("attendance.view.all")
        {
            return Err(AppError::Forbidden(
                "Permission 'attendance.approve' required to approve corrections".into(),
            ));
        }

        let approved = CorrectionRepository::approve(pool, id, actor.user_id).await?;

        // 3. Trigger automatic daily attendance recalculation!
        let daily = DailyAttendanceRepository::find_by_id(pool, corr.attendance_daily_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Daily attendance record not found".into()))?;

        let emp = EmployeeRepository::find_by_id(pool, actor.organization_id, daily.employee_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Employee record not found".into()))?;

        let _res = process_and_persist_employee_date(
            pool,
            actor.organization_id,
            emp.id,
            emp.section_id,
            &emp.attendance_device_user_id,
            daily.attendance_date,
            emp.attendance_rule_id,
        )
        .await?;

        let _ = AuditLogRepository::log(
            pool,
            Some(actor.organization_id),
            Some(actor.user_id),
            "CORRECTION_APPROVED",
            "attendance_corrections",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(approved)
    }

    pub async fn reject_correction(
        pool: &PgPool,
        actor: &CurrentUser,
        id: Uuid,
        payload: RejectCorrectionPayload,
    ) -> Result<AttendanceCorrection, AppError> {
        let _corr = CorrectionRepository::find_by_id(pool, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Correction {} not found", id)))?;

        if !actor.has_permission("attendance.approve") && !actor.has_permission("attendance.view.all")
        {
            return Err(AppError::Forbidden(
                "Permission 'attendance.approve' required".into(),
            ));
        }

        let rejected = CorrectionRepository::reject(pool, id, actor.user_id, &payload.reason).await?;

        let _ = AuditLogRepository::log(
            pool,
            Some(actor.organization_id),
            Some(actor.user_id),
            "CORRECTION_REJECTED",
            "attendance_corrections",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(rejected)
    }
}
