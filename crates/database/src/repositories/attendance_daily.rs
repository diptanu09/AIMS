use aims_common::{AimsError, Result};
use aims_domain::AttendanceDaily;
use chrono::NaiveDate;
use sqlx::PgPool;
use uuid::Uuid;

pub struct DailyAttendanceRepository;

impl DailyAttendanceRepository {
    pub async fn save(
        pool: &PgPool,
        daily: &AttendanceDaily,
    ) -> Result<AttendanceDaily> {
        let record = sqlx::query_as::<_, AttendanceDaily>(
            r#"
            INSERT INTO attendance_daily (
                id, organization_id, employee_id, section_id, attendance_date,
                first_in, last_out, total_duty_minutes, minutes_after_shift_start,
                late_after_grace_minutes, early_exit_minutes, status, is_corrected, processed_at
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            ON CONFLICT (employee_id, attendance_date) DO UPDATE SET
                first_in = EXCLUDED.first_in,
                last_out = EXCLUDED.last_out,
                total_duty_minutes = EXCLUDED.total_duty_minutes,
                minutes_after_shift_start = EXCLUDED.minutes_after_shift_start,
                late_after_grace_minutes = EXCLUDED.late_after_grace_minutes,
                early_exit_minutes = EXCLUDED.early_exit_minutes,
                status = EXCLUDED.status,
                is_corrected = EXCLUDED.is_corrected,
                processed_at = EXCLUDED.processed_at
            RETURNING id, organization_id, employee_id, section_id, attendance_date,
                      first_in, last_out, total_duty_minutes, minutes_after_shift_start,
                      late_after_grace_minutes, early_exit_minutes, status, is_corrected, processed_at
            "#
        )
        .bind(daily.id)
        .bind(daily.organization_id)
        .bind(daily.employee_id)
        .bind(daily.section_id)
        .bind(daily.attendance_date)
        .bind(daily.first_in)
        .bind(daily.last_out)
        .bind(daily.total_duty_minutes)
        .bind(daily.minutes_after_shift_start)
        .bind(daily.late_after_grace_minutes)
        .bind(daily.early_exit_minutes)
        .bind(&daily.status)
        .bind(daily.is_corrected)
        .bind(daily.processed_at)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to save daily attendance summary: {}", e)))?;

        Ok(record)
    }

    pub async fn find_by_employee_and_date(
        pool: &PgPool,
        employee_id: Uuid,
        attendance_date: NaiveDate,
    ) -> Result<Option<AttendanceDaily>> {
        let record = sqlx::query_as::<_, AttendanceDaily>(
            r#"
            SELECT id, organization_id, employee_id, section_id, attendance_date,
                   first_in, last_out, total_duty_minutes, minutes_after_shift_start,
                   late_after_grace_minutes, early_exit_minutes, status, is_corrected, processed_at
            FROM attendance_daily
            WHERE employee_id = $1 AND attendance_date = $2
            "#
        )
        .bind(employee_id)
        .bind(attendance_date)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query daily attendance: {}", e)))?;

        Ok(record)
    }
}
