use aims_auth::CurrentUser;
use aims_database::repositories::leave::{DetailedLeaveRecordRow, LeaveRepository};
use chrono::NaiveDate;
use serde::Deserialize;
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::AppError;

#[derive(Debug, Deserialize)]
pub struct SubmitLeavePayload {
    pub employee_id: Uuid,
    pub leave_type: String,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub reason: Option<String>,
}

pub struct LeaveService;

impl LeaveService {
    pub async fn submit_leave(
        pool: &PgPool,
        actor: &CurrentUser,
        payload: SubmitLeavePayload,
    ) -> Result<Uuid, AppError> {
        let leave_id = LeaveRepository::create(
            pool,
            actor.organization_id,
            payload.employee_id,
            &payload.leave_type,
            payload.start_date,
            payload.end_date,
            payload.reason.as_deref(),
            actor.user_id,
        )
        .await?;

        Ok(leave_id)
    }

    pub async fn list_leave(
        pool: &PgPool,
        actor: &CurrentUser,
    ) -> Result<Vec<DetailedLeaveRecordRow>, AppError> {
        let items = LeaveRepository::list_by_organization(pool, actor.organization_id).await?;
        Ok(items)
    }
}
