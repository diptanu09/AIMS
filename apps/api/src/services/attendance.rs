use aims_attendance_engine::process_and_persist_employee_date;
use aims_common::{AimsError, Result};
use aims_database::repositories::{
    employees::EmployeeRepository,
    processing_jobs::{AttendanceProcessingJobRecord, ProcessingJobRepository},
};
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct ProcessAttendanceRequest {
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub employee_id: Option<Uuid>,
    pub section_id: Option<Uuid>,
}

#[derive(Debug, Serialize)]
pub struct ProcessAttendanceResponse {
    pub job: AttendanceProcessingJobRecord,
    pub total_employee_days: i32,
    pub processed_days: i32,
    pub failed_days: i32,
}

pub struct AttendanceService;

impl AttendanceService {
    pub async fn process_attendance(
        pool: &PgPool,
        organization_id: Uuid,
        user_id: Uuid,
        req: ProcessAttendanceRequest,
    ) -> Result<ProcessAttendanceResponse> {
        if req.start_date > req.end_date {
            return Err(AimsError::Validation(
                "start_date cannot be after end_date".into(),
            ));
        }

        // Load employees in target organization / scope
        let employees = if let Some(emp_id) = req.employee_id {
            if let Some(emp) = EmployeeRepository::find_by_id(pool, organization_id, emp_id).await?
            {
                vec![emp]
            } else {
                vec![]
            }
        } else {
            EmployeeRepository::list_by_organization(pool, organization_id).await?
        };

        let date_count = (req.end_date - req.start_date).num_days() as i32 + 1;
        let total_employee_days = (employees.len() as i32) * date_count;

        let job = ProcessingJobRepository::create(
            pool,
            organization_id,
            user_id,
            req.start_date,
            req.end_date,
            req.employee_id,
            req.section_id,
            total_employee_days,
        )
        .await?;

        ProcessingJobRepository::update_progress(pool, job.id, "RUNNING", 0, 0, None).await?;

        let mut processed = 0i32;
        let mut failed = 0i32;

        let mut curr_date = req.start_date;
        while curr_date <= req.end_date {
            for emp in &employees {
                let res = process_and_persist_employee_date(
                    pool,
                    organization_id,
                    emp.id,
                    emp.section_id,
                    &emp.attendance_device_user_id,
                    curr_date,
                    emp.attendance_rule_id,
                )
                .await;

                match res {
                    Ok(_) => processed += 1,
                    Err(_) => failed += 1,
                }
            }
            curr_date += chrono::Duration::days(1);
        }

        let final_status = if failed > 0 { "FAILED" } else { "COMPLETED" };
        ProcessingJobRepository::update_progress(
            pool,
            job.id,
            final_status,
            processed,
            failed,
            None,
        )
        .await?;

        let updated_job = ProcessingJobRepository::find_by_id(pool, job.id)
            .await?
            .ok_or_else(|| AimsError::NotFound("Job not found".into()))?;

        Ok(ProcessAttendanceResponse {
            job: updated_job,
            total_employee_days,
            processed_days: processed,
            failed_days: failed,
        })
    }
}
