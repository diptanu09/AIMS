use aims_common::{AimsError, Result};
use aims_domain::AttendanceRule;
use chrono::{NaiveDate, NaiveTime};
use sqlx::PgPool;
use uuid::Uuid;

pub struct AttendanceRuleRepository;

impl AttendanceRuleRepository {
    #[allow(clippy::too_many_arguments)]
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
        max_single_session_hours: i32,
        cross_midnight: bool,
        effective_from: NaiveDate,
        effective_to: Option<NaiveDate>,
    ) -> Result<AttendanceRule> {
        let rule = sqlx::query_as::<_, AttendanceRule>(
            r#"
            INSERT INTO attendance_rules (
                organization_id, name, shift_start_time, shift_end_time,
                grace_period_minutes, half_day_min_duration_minutes,
                full_day_min_duration_minutes, early_exit_threshold_minutes,
                max_single_session_hours, cross_midnight, effective_from, effective_to
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING id, organization_id, name, shift_start_time, shift_end_time,
                      grace_period_minutes, half_day_min_duration_minutes,
                      full_day_min_duration_minutes, early_exit_threshold_minutes,
                      max_single_session_hours, cross_midnight, effective_from, effective_to,
                      active, created_at, updated_at
            "#,
        )
        .bind(organization_id)
        .bind(name)
        .bind(shift_start_time)
        .bind(shift_end_time)
        .bind(grace_period_minutes)
        .bind(half_day_min_duration_minutes)
        .bind(full_day_min_duration_minutes)
        .bind(early_exit_threshold_minutes)
        .bind(max_single_session_hours)
        .bind(cross_midnight)
        .bind(effective_from)
        .bind(effective_to)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert attendance rule: {}", e)))?;

        Ok(rule)
    }

    pub async fn find_by_id(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
    ) -> Result<Option<AttendanceRule>> {
        let rule = sqlx::query_as::<_, AttendanceRule>(
            r#"
            SELECT id, organization_id, name, shift_start_time, shift_end_time,
                   grace_period_minutes, half_day_min_duration_minutes,
                   full_day_min_duration_minutes, early_exit_threshold_minutes,
                   max_single_session_hours, cross_midnight, effective_from, effective_to,
                   active, created_at, updated_at
            FROM attendance_rules
            WHERE id = $1 AND organization_id = $2
            "#,
        )
        .bind(id)
        .bind(organization_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to query attendance rule by id: {}", e))
        })?;

        Ok(rule)
    }

    pub async fn find_any_by_id(pool: &PgPool, id: Uuid) -> Result<Option<AttendanceRule>> {
        let rule = sqlx::query_as::<_, AttendanceRule>(
            r#"
            SELECT id, organization_id, name, shift_start_time, shift_end_time,
                   grace_period_minutes, half_day_min_duration_minutes,
                   full_day_min_duration_minutes, early_exit_threshold_minutes,
                   max_single_session_hours, cross_midnight, effective_from, effective_to,
                   active, created_at, updated_at
            FROM attendance_rules
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to query attendance rule by id: {}", e))
        })?;

        Ok(rule)
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn update(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
        name: Option<&str>,
        shift_start_time: Option<NaiveTime>,
        shift_end_time: Option<NaiveTime>,
        grace_period_minutes: Option<i32>,
        half_day_min_duration_minutes: Option<i32>,
        full_day_min_duration_minutes: Option<i32>,
        early_exit_threshold_minutes: Option<i32>,
        max_single_session_hours: Option<i32>,
        cross_midnight: Option<bool>,
        effective_from: Option<NaiveDate>,
        effective_to: Option<Option<NaiveDate>>,
    ) -> Result<AttendanceRule> {
        let current = Self::find_by_id(pool, organization_id, id)
            .await?
            .ok_or_else(|| AimsError::NotFound(format!("Attendance rule {} not found", id)))?;

        let new_name = name.unwrap_or(&current.name);
        let new_start = shift_start_time.unwrap_or(current.shift_start_time);
        let new_end = shift_end_time.unwrap_or(current.shift_end_time);
        let new_grace = grace_period_minutes.unwrap_or(current.grace_period_minutes);
        let new_half =
            half_day_min_duration_minutes.unwrap_or(current.half_day_min_duration_minutes);
        let new_full =
            full_day_min_duration_minutes.unwrap_or(current.full_day_min_duration_minutes);
        let new_early =
            early_exit_threshold_minutes.unwrap_or(current.early_exit_threshold_minutes);
        let new_max_session = max_single_session_hours.unwrap_or(current.max_single_session_hours);
        let new_midnight = cross_midnight.unwrap_or(current.cross_midnight);
        let new_eff_from = effective_from.unwrap_or(current.effective_from);
        let new_eff_to = match effective_to {
            Some(val) => val,
            None => current.effective_to,
        };

        let updated = sqlx::query_as::<_, AttendanceRule>(
            r#"
            UPDATE attendance_rules
            SET name = $1, shift_start_time = $2, shift_end_time = $3,
                grace_period_minutes = $4, half_day_min_duration_minutes = $5,
                full_day_min_duration_minutes = $6, early_exit_threshold_minutes = $7,
                max_single_session_hours = $8, cross_midnight = $9,
                effective_from = $10, effective_to = $11, updated_at = CURRENT_TIMESTAMP
            WHERE id = $12 AND organization_id = $13
            RETURNING id, organization_id, name, shift_start_time, shift_end_time,
                      grace_period_minutes, half_day_min_duration_minutes,
                      full_day_min_duration_minutes, early_exit_threshold_minutes,
                      max_single_session_hours, cross_midnight, effective_from, effective_to,
                      active, created_at, updated_at
            "#,
        )
        .bind(new_name)
        .bind(new_start)
        .bind(new_end)
        .bind(new_grace)
        .bind(new_half)
        .bind(new_full)
        .bind(new_early)
        .bind(new_max_session)
        .bind(new_midnight)
        .bind(new_eff_from)
        .bind(new_eff_to)
        .bind(id)
        .bind(organization_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to update attendance rule: {}", e)))?;

        Ok(updated)
    }

    pub async fn list_filtered(
        pool: &PgPool,
        organization_id: Uuid,
        search: Option<&str>,
        active: Option<bool>,
    ) -> Result<Vec<AttendanceRule>> {
        let rules = sqlx::query_as::<_, AttendanceRule>(
            r#"
            SELECT id, organization_id, name, shift_start_time, shift_end_time,
                   grace_period_minutes, half_day_min_duration_minutes,
                   full_day_min_duration_minutes, early_exit_threshold_minutes,
                   max_single_session_hours, cross_midnight, effective_from, effective_to,
                   active, created_at, updated_at
            FROM attendance_rules
            WHERE organization_id = $1
              AND ($2::text IS NULL OR name ILIKE $2)
              AND ($3::boolean IS NULL OR active = $3)
            ORDER BY name ASC, effective_from DESC
            "#,
        )
        .bind(organization_id)
        .bind(search.map(|s| format!("%{}%", s)))
        .bind(active)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list attendance rules: {}", e)))?;

        Ok(rules)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<AttendanceRule>> {
        Self::list_filtered(pool, organization_id, None, None).await
    }
}
