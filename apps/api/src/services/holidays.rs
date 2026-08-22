use aims_auth::CurrentUser;
use aims_database::repositories::holidays::{Holiday, HolidayRepository};
use chrono::NaiveDate;
use serde::Deserialize;
use sqlx::PgPool;

use crate::error::AppError;

#[derive(Debug, Deserialize)]
pub struct CreateHolidayPayload {
    pub holiday_date: NaiveDate,
    pub name: String,
    pub description: Option<String>,
    pub is_optional: Option<bool>,
}

pub struct HolidayService;

impl HolidayService {
    pub async fn create_holiday(
        pool: &PgPool,
        actor: &CurrentUser,
        payload: CreateHolidayPayload,
    ) -> Result<Holiday, AppError> {
        if !actor.has_permission("rule.manage") && !actor.has_permission("attendance.view.all") {
            return Err(AppError::Forbidden(
                "Permission 'rule.manage' required to manage holiday calendar".into(),
            ));
        }

        let hol = HolidayRepository::create(
            pool,
            actor.organization_id,
            payload.holiday_date,
            &payload.name,
            payload.description.as_deref(),
            payload.is_optional.unwrap_or(false),
        )
        .await?;

        Ok(hol)
    }

    pub async fn list_holidays(
        pool: &PgPool,
        actor: &CurrentUser,
    ) -> Result<Vec<Holiday>, AppError> {
        let items = HolidayRepository::list_by_organization(pool, actor.organization_id).await?;
        Ok(items)
    }
}
