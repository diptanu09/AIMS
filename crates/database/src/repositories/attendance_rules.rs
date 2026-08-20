use aims_common::{AimsError, Result};
use aims_domain::AttendanceRule;
use chrono::NaiveTime;
use sqlx::PgPool;
use uuid::Uuid;

pub struct AttendanceRuleRepository;

impl AttendanceRuleRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        name: &str,
        shift_start_time: NaiveTime,
        shift_end_time: NaiveTime,
        grace_period_minutes: i32,
        half_day_min_duration_minutes: i32,
        full_day_min_duration_minutes: i32,
        early_exit_threshold_minutes: i32,
    ) -> Result<AttendanceRule> {
        let rule = sqlx::query_as::<_, AttendanceRule>(
            r#"
            INSERT INTO attendance_rules (
                organization_id, name, shift_start_time, shift_end_time,
                grace_period_minutes, half_day_min_duration_minutes,
                full_day_min_duration_minutes, early_exit_threshold_minutes
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING id, organization_id, name, shift_start_time, shift_end_time,
                      grace_period_minutes, half_day_min_duration_minutes,
                      full_day_min_duration_minutes, early_exit_threshold_minutes,
                      max_single_session_hours, created_at, updated_at
            "#
        )
        .bind(organization_id)
        .bind(name)
        .bind(shift_start_time)
        .bind(shift_end_time)
        .bind(grace_period_minutes)
        .bind(half_day_min_duration_minutes)
        .bind(full_day_min_duration_minutes)
        .bind(early_exit_threshold_minutes)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert attendance rule: {}", e)))?;

        Ok(rule)
    }
}
