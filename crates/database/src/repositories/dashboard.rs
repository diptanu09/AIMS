use aims_common::{AimsError, Result};
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DashboardSummary {
    pub date: NaiveDate,
    pub total_employees: i64,
    pub present: i64,
    pub late: i64,
    pub absent: i64,
    pub half_day: i64,
    pub incomplete: i64,
    pub early_exit: i64,
    pub attendance_rate: f64,
    pub average_duty_minutes: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SectionSummary {
    pub section_id: Uuid,
    pub section_name: String,
    pub total: i64,
    pub present: i64,
    pub late: i64,
    pub absent: i64,
    pub incomplete: i64,
    pub attendance_rate: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AttendanceTrendRow {
    pub date: NaiveDate,
    pub present: i64,
    pub absent: i64,
    pub late: i64,
    pub incomplete: i64,
    pub attendance_rate: f64,
    pub average_duty_minutes: i64,
}

pub struct DashboardRepository;

impl DashboardRepository {
    pub async fn get_summary(
        pool: &PgPool,
        organization_id: Uuid,
        date: NaiveDate,
    ) -> Result<DashboardSummary> {
        let row = sqlx::query!(
            r#"
            SELECT
                COUNT(e.id) AS total_employees,
                COUNT(ad.id) FILTER (WHERE ad.status = 'PRESENT') AS present,
                COUNT(ad.id) FILTER (WHERE ad.status IN ('LATE', 'LATE_AND_EARLY_EXIT')) AS late,
                COUNT(ad.id) FILTER (WHERE ad.status = 'ABSENT') AS absent,
                COUNT(ad.id) FILTER (WHERE ad.status = 'HALF_DAY') AS half_day,
                COUNT(ad.id) FILTER (WHERE ad.status = 'INCOMPLETE') AS incomplete,
                COUNT(ad.id) FILTER (WHERE ad.status IN ('EARLY_EXIT', 'LATE_AND_EARLY_EXIT')) AS early_exit,
                COALESCE(AVG(ad.total_duty_minutes) FILTER (WHERE ad.status NOT IN ('ABSENT', 'INCOMPLETE')), 0)::BIGINT AS average_duty_minutes
            FROM employees e
            LEFT JOIN attendance_daily ad
                   ON e.id = ad.employee_id
                  AND ad.attendance_date = $2
            WHERE e.organization_id = $1
              AND e.status = 'ACTIVE'
            "#,
            organization_id,
            date
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query dashboard summary: {}", e)))?;

        let total = row.total_employees.unwrap_or(0);
        let pres = row.present.unwrap_or(0);
        let late_count = row.late.unwrap_or(0);
        let abs_count = row.absent.unwrap_or(0);
        let half_count = row.half_day.unwrap_or(0);
        let inc_count = row.incomplete.unwrap_or(0);
        let early_count = row.early_exit.unwrap_or(0);
        let avg_duty = row.average_duty_minutes.unwrap_or(0);

        let rate = if total > 0 {
            ((pres + late_count + early_count) as f64 / total as f64) * 100.0
        } else {
            0.0
        };

        Ok(DashboardSummary {
            date,
            total_employees: total,
            present: pres,
            late: late_count,
            absent: abs_count,
            half_day: half_count,
            incomplete: inc_count,
            early_exit: early_count,
            attendance_rate: (rate * 100.0).round() / 100.0,
            average_duty_minutes: avg_duty,
        })
    }

    pub async fn get_section_summaries(
        pool: &PgPool,
        organization_id: Uuid,
        date: NaiveDate,
    ) -> Result<Vec<SectionSummary>> {
        let rows = sqlx::query!(
            r#"
            SELECT
                s.id AS section_id,
                s.name AS section_name,
                COUNT(e.id) AS total,
                COUNT(ad.id) FILTER (WHERE ad.status = 'PRESENT') AS present,
                COUNT(ad.id) FILTER (WHERE ad.status IN ('LATE', 'LATE_AND_EARLY_EXIT')) AS late,
                COUNT(ad.id) FILTER (WHERE ad.status = 'ABSENT') AS absent,
                COUNT(ad.id) FILTER (WHERE ad.status = 'INCOMPLETE') AS incomplete
            FROM sections s
            JOIN employees e ON s.id = e.section_id AND e.status = 'ACTIVE'
            LEFT JOIN attendance_daily ad ON e.id = ad.employee_id AND ad.attendance_date = $2
            WHERE s.organization_id = $1 AND s.active = true
            GROUP BY s.id, s.name
            ORDER BY s.name ASC
            "#,
            organization_id,
            date
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query section summaries: {}", e)))?;

        let mut res = Vec::new();
        for r in rows {
            let total = r.total.unwrap_or(0);
            let pres = r.present.unwrap_or(0);
            let late_cnt = r.late.unwrap_or(0);

            let rate = if total > 0 {
                ((pres + late_cnt) as f64 / total as f64) * 100.0
            } else {
                0.0
            };

            res.push(SectionSummary {
                section_id: r.section_id,
                section_name: r.section_name,
                total,
                present: pres,
                late: late_cnt,
                absent: r.absent.unwrap_or(0),
                incomplete: r.incomplete.unwrap_or(0),
                attendance_rate: (rate * 100.0).round() / 100.0,
            });
        }

        Ok(res)
    }

    pub async fn get_trends(
        pool: &PgPool,
        organization_id: Uuid,
        from_date: NaiveDate,
        to_date: NaiveDate,
        section_id: Option<Uuid>,
    ) -> Result<Vec<AttendanceTrendRow>> {
        let rows = sqlx::query!(
            r#"
            SELECT
                ad.attendance_date AS "date!",
                COUNT(ad.id) FILTER (WHERE ad.status = 'PRESENT') AS present,
                COUNT(ad.id) FILTER (WHERE ad.status = 'ABSENT') AS absent,
                COUNT(ad.id) FILTER (WHERE ad.status IN ('LATE', 'LATE_AND_EARLY_EXIT')) AS late,
                COUNT(ad.id) FILTER (WHERE ad.status = 'INCOMPLETE') AS incomplete,
                COUNT(ad.id) AS total_recorded,
                COALESCE(AVG(ad.total_duty_minutes) FILTER (WHERE ad.status NOT IN ('ABSENT', 'INCOMPLETE')), 0)::BIGINT AS average_duty_minutes
            FROM attendance_daily ad
            WHERE ad.organization_id = $1
              AND ad.attendance_date BETWEEN $2 AND $3
              AND ($4::uuid IS NULL OR ad.section_id = $4)
            GROUP BY ad.attendance_date
            ORDER BY ad.attendance_date ASC
            "#,
            organization_id,
            from_date,
            to_date,
            section_id
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query attendance trends: {}", e)))?;

        let mut res = Vec::new();
        for r in rows {
            let total = r.total_recorded.unwrap_or(0);
            let pres = r.present.unwrap_or(0);
            let late_cnt = r.late.unwrap_or(0);

            let rate = if total > 0 {
                ((pres + late_cnt) as f64 / total as f64) * 100.0
            } else {
                0.0
            };

            res.push(AttendanceTrendRow {
                date: r.date,
                present: pres,
                absent: r.absent.unwrap_or(0),
                late: late_cnt,
                incomplete: r.incomplete.unwrap_or(0),
                attendance_rate: (rate * 100.0).round() / 100.0,
                average_duty_minutes: r.average_duty_minutes.unwrap_or(0),
            });
        }

        Ok(res)
    }
}
