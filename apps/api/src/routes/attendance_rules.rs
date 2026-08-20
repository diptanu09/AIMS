use crate::state::AppState;
use aims_auth::Claims;
use aims_common::Result;
use aims_database::repositories::attendance_rules::AttendanceRuleRepository;
use aims_domain::AttendanceRule;
use axum::{
    extract::State,
    routing::post,
    Extension, Json, Router,
};
use chrono::NaiveTime;
use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct CreateAttendanceRuleRequest {
    pub organization_id: Uuid,
    pub name: String,
    pub shift_start_time: NaiveTime,
    pub shift_end_time: NaiveTime,
    pub grace_period_minutes: Option<i32>,
    pub half_day_min_duration_minutes: Option<i32>,
    pub full_day_min_duration_minutes: Option<i32>,
    pub early_exit_threshold_minutes: Option<i32>,
}

pub async fn create_rule(
    State(state): State<AppState>,
    Json(payload): Json<CreateAttendanceRuleRequest>,
) -> Result<Json<AttendanceRule>> {
    let pool = state.db.pool();
    let rule = AttendanceRuleRepository::create(
        pool,
        payload.organization_id,
        &payload.name,
        payload.shift_start_time,
        payload.shift_end_time,
        payload.grace_period_minutes.unwrap_or(15),
        payload.half_day_min_duration_minutes.unwrap_or(240),
        payload.full_day_min_duration_minutes.unwrap_or(420),
        payload.early_exit_threshold_minutes.unwrap_or(15),
    )
    .await?;

    Ok(Json(rule))
}

pub async fn list_rules(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<Vec<AttendanceRule>>> {
    let pool = state.db.pool();
    let rules = AttendanceRuleRepository::list_by_organization(pool, claims.org_id).await?;

    Ok(Json(rules))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", post(create_rule).get(list_rules))
}
