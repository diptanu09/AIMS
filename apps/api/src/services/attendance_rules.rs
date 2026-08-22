use aims_auth::CurrentUser;
use aims_database::repositories::{
    attendance_rules::AttendanceRuleRepository, audit::AuditLogRepository,
};
use aims_domain::AttendanceRule;
use chrono::{NaiveDate, NaiveTime};
use serde::Deserialize;
use uuid::Uuid;
use validator::Validate;

use crate::{error::AppError, state::AppState};

#[derive(Debug, Deserialize, Validate)]
pub struct CreateAttendanceRuleRequest {
    #[validate(length(min = 1, max = 64))]
    pub name: String,
    pub shift_start_time: NaiveTime,
    pub shift_end_time: NaiveTime,
    #[validate(range(min = 0, max = 1440))]
    pub grace_period_minutes: i32,
    #[validate(range(min = 0))]
    pub half_day_min_duration_minutes: i32,
    #[validate(range(min = 0))]
    pub full_day_min_duration_minutes: i32,
    #[validate(range(min = 0, max = 1440))]
    pub early_exit_threshold_minutes: i32,
    #[validate(range(min = 1, max = 48))]
    pub max_single_session_hours: i32,
    pub cross_midnight: bool,
    pub effective_from: NaiveDate,
    pub effective_to: Option<NaiveDate>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateAttendanceRuleRequest {
    #[validate(length(min = 1, max = 64))]
    pub name: Option<String>,
    pub shift_start_time: Option<NaiveTime>,
    pub shift_end_time: Option<NaiveTime>,
    #[validate(range(min = 0, max = 1440))]
    pub grace_period_minutes: Option<i32>,
    #[validate(range(min = 0))]
    pub half_day_min_duration_minutes: Option<i32>,
    #[validate(range(min = 0))]
    pub full_day_min_duration_minutes: Option<i32>,
    #[validate(range(min = 0, max = 1440))]
    pub early_exit_threshold_minutes: Option<i32>,
    #[validate(range(min = 1, max = 48))]
    pub max_single_session_hours: Option<i32>,
    pub cross_midnight: Option<bool>,
    pub effective_from: Option<NaiveDate>,
    pub effective_to: Option<Option<NaiveDate>>,
}

#[derive(Debug, Deserialize)]
pub struct AttendanceRuleQuery {
    pub search: Option<String>,
    pub active: Option<bool>,
}

pub struct AttendanceRuleService;

impl AttendanceRuleService {
    pub async fn create_rule(
        state: &AppState,
        actor: &CurrentUser,
        req: CreateAttendanceRuleRequest,
    ) -> Result<AttendanceRule, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        if req.full_day_min_duration_minutes < req.half_day_min_duration_minutes {
            return Err(AppError::Validation(
                "Full day minimum duration must be greater than or equal to half day duration"
                    .to_string(),
            ));
        }

        #[allow(clippy::collapsible_if)]
        if let Some(eff_to) = req.effective_to {
            if eff_to < req.effective_from {
                return Err(AppError::Validation(
                    "effective_to date cannot be earlier than effective_from date".to_string(),
                ));
            }
        }

        let rule = AttendanceRuleRepository::create(
            &state.db,
            actor.organization_id,
            &req.name,
            req.shift_start_time,
            req.shift_end_time,
            req.grace_period_minutes,
            req.half_day_min_duration_minutes,
            req.full_day_min_duration_minutes,
            req.early_exit_threshold_minutes,
            req.max_single_session_hours,
            req.cross_midnight,
            req.effective_from,
            req.effective_to,
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "ATTENDANCE_RULE_CREATED",
            "attendance_rules",
            Some(rule.id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(rule)
    }

    pub async fn update_rule(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
        req: UpdateAttendanceRuleRequest,
    ) -> Result<AttendanceRule, AppError> {
        req.validate()
            .map_err(|e| AppError::Validation(e.to_string()))?;

        let current = AttendanceRuleRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Attendance rule {} not found", id)))?;

        let half = req
            .half_day_min_duration_minutes
            .unwrap_or(current.half_day_min_duration_minutes);
        let full = req
            .full_day_min_duration_minutes
            .unwrap_or(current.full_day_min_duration_minutes);
        if full < half {
            return Err(AppError::Validation(
                "Full day minimum duration must be greater than or equal to half day duration"
                    .to_string(),
            ));
        }

        let updated = AttendanceRuleRepository::update(
            &state.db,
            actor.organization_id,
            id,
            req.name.as_deref(),
            req.shift_start_time,
            req.shift_end_time,
            req.grace_period_minutes,
            req.half_day_min_duration_minutes,
            req.full_day_min_duration_minutes,
            req.early_exit_threshold_minutes,
            req.max_single_session_hours,
            req.cross_midnight,
            req.effective_from,
            req.effective_to,
        )
        .await?;

        let _ = AuditLogRepository::log(
            &state.db,
            Some(actor.organization_id),
            Some(actor.user_id),
            "ATTENDANCE_RULE_UPDATED",
            "attendance_rules",
            Some(id),
            None,
            None,
            None,
            None,
        )
        .await;

        Ok(updated)
    }

    pub async fn get_rule(
        state: &AppState,
        actor: &CurrentUser,
        id: Uuid,
    ) -> Result<AttendanceRule, AppError> {
        AttendanceRuleRepository::find_by_id(&state.db, actor.organization_id, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Attendance rule {} not found", id)))
    }

    pub async fn list_rules(
        state: &AppState,
        actor: &CurrentUser,
        query: AttendanceRuleQuery,
    ) -> Result<Vec<AttendanceRule>, AppError> {
        let rules = AttendanceRuleRepository::list_filtered(
            &state.db,
            actor.organization_id,
            query.search.as_deref(),
            query.active,
        )
        .await?;

        Ok(rules)
    }
}
