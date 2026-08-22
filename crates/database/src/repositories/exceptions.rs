use aims_common::{AimsError, Result};
use aims_domain::AttendanceStatus;
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttendanceExceptionRow {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub employee_id: Uuid,
    pub employee_code: String,
    pub employee_name: String,
    pub section_id: Uuid,
    pub section_name: String,
    pub attendance_date: NaiveDate,
    pub first_in: Option<DateTime<Utc>>,
    pub last_out: Option<DateTime<Utc>>,
    pub total_duty_minutes: i32,
    pub late_minutes: i32,
    pub early_exit_minutes: i32,
    pub status: AttendanceStatus,
    pub exception_type: String,
    pub severity: String,
}

#[derive(Debug, Deserialize)]
pub struct ExceptionFilter {
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
    pub section_id: Option<Uuid>,
    pub employee_id: Option<Uuid>,
    pub exception_type: Option<String>,
    pub limit: i64,
    pub offset: i64,
}

pub struct ExceptionsRepository;

impl ExceptionsRepository {
    pub async fn list_exceptions(
        pool: &PgPool,
        organization_id: Uuid,
        filter: ExceptionFilter,
    ) -> Result<(Vec<AttendanceExceptionRow>, i64)> {
        let rows = sqlx::query!(
            r#"
            SELECT
                ad.id,
                ad.organization_id,
                ad.employee_id,
                e.employee_code,
                CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) AS employee_name,
                ad.section_id,
                s.name AS section_name,
                ad.attendance_date,
                ad.first_in,
                ad.last_out,
                ad.total_duty_minutes,
                ad.minutes_after_shift_start AS late_minutes,
                ad.early_exit_minutes,
                ad.status AS "status: AttendanceStatus",
                CASE
                    WHEN ad.status = 'INCOMPLETE' THEN 'INCOMPLETE'
                    WHEN ad.status IN ('LATE', 'LATE_AND_EARLY_EXIT') THEN 'LATE'
                    WHEN ad.status IN ('EARLY_EXIT', 'LATE_AND_EARLY_EXIT') THEN 'EARLY_EXIT'
                    WHEN ad.status = 'ABSENT' THEN 'ABSENT'
                    WHEN ad.status = 'HALF_DAY' THEN 'HALF_DAY'
                    ELSE 'OTHER'
                END AS "exception_type!",
                CASE
                    WHEN ad.status IN ('ABSENT', 'INCOMPLETE') THEN 'HIGH'
                    WHEN ad.status IN ('LATE', 'LATE_AND_EARLY_EXIT', 'EARLY_EXIT') THEN 'MEDIUM'
                    ELSE 'LOW'
                END AS "severity!",
                COUNT(*) OVER() AS total_count
            FROM attendance_daily ad
            JOIN employees e ON ad.employee_id = e.id
            JOIN sections s ON ad.section_id = s.id
            WHERE ad.organization_id = $1
              AND ad.status IN ('LATE', 'ABSENT', 'HALF_DAY', 'EARLY_EXIT', 'LATE_AND_EARLY_EXIT', 'INCOMPLETE')
              AND ($2::date IS NULL OR ad.attendance_date >= $2)
              AND ($3::date IS NULL OR ad.attendance_date <= $3)
              AND ($4::uuid IS NULL OR ad.section_id = $4)
              AND ($5::uuid IS NULL OR ad.employee_id = $5)
              AND ($6::text IS NULL OR (
                    ($6 = 'LATE' AND ad.status IN ('LATE', 'LATE_AND_EARLY_EXIT')) OR
                    ($6 = 'EARLY_EXIT' AND ad.status IN ('EARLY_EXIT', 'LATE_AND_EARLY_EXIT')) OR
                    ($6 = 'ABSENT' AND ad.status = 'ABSENT') OR
                    ($6 = 'INCOMPLETE' AND ad.status = 'INCOMPLETE') OR
                    ($6 = 'HALF_DAY' AND ad.status = 'HALF_DAY')
                  ))
            ORDER BY ad.attendance_date DESC, e.first_name ASC
            LIMIT $7 OFFSET $8
            "#,
            organization_id,
            filter.date_from,
            filter.date_to,
            filter.section_id,
            filter.employee_id,
            filter.exception_type,
            filter.limit,
            filter.offset
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query exceptions: {}", e)))?;

        let total = rows
            .first()
            .map(|r| r.total_count.unwrap_or(0))
            .unwrap_or(0);

        let items = rows
            .into_iter()
            .map(|r| AttendanceExceptionRow {
                id: r.id,
                organization_id: r.organization_id,
                employee_id: r.employee_id,
                employee_code: r.employee_code,
                employee_name: r.employee_name.unwrap_or_default().trim().to_string(),
                section_id: r.section_id,
                section_name: r.section_name,
                attendance_date: r.attendance_date,
                first_in: r.first_in,
                last_out: r.last_out,
                total_duty_minutes: r.total_duty_minutes,
                late_minutes: r.late_minutes,
                early_exit_minutes: r.early_exit_minutes,
                status: r.status,
                exception_type: r.exception_type,
                severity: r.severity,
            })
            .collect();

        Ok((items, total))
    }
}
