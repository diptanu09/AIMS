use aims_common::{AimsError, Result};
use aims_domain::AttendanceStatus;
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DetailedAttendanceDailyRow {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub employee_id: Uuid,
    pub employee_code: String,
    pub employee_name: String,
    pub designation_id: Uuid,
    pub designation_name: String,
    pub section_id: Uuid,
    pub section_name: String,
    pub attendance_date: NaiveDate,
    pub first_in: Option<DateTime<Utc>>,
    pub last_out: Option<DateTime<Utc>>,
    pub total_duty_minutes: i32,
    pub late_minutes: i32,
    pub late_minutes_beyond_grace: i32,
    pub early_exit_minutes: i32,
    pub status: AttendanceStatus,
}

#[derive(Debug, Deserialize)]
pub struct DailyAttendanceFilter {
    pub date: Option<NaiveDate>,
    pub start_date: Option<NaiveDate>,
    pub end_date: Option<NaiveDate>,
    pub section_id: Option<Uuid>,
    pub employee_id: Option<Uuid>,
    pub designation_id: Option<Uuid>,
    pub status: Option<AttendanceStatus>,
    pub search: Option<String>,
    pub limit: i64,
    pub offset: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmployeeAttendanceStats {
    pub employee_id: Uuid,
    pub total_days: i64,
    pub present_days: i64,
    pub late_days: i64,
    pub absent_days: i64,
    pub half_days: i64,
    pub incomplete_days: i64,
    pub early_exit_days: i64,
    pub attendance_rate: f64,
    pub average_duty_minutes: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SectionHierarchyResponse {
    pub section_id: Uuid,
    pub section_code: String,
    pub section_name: String,
    pub parent_section_id: Option<Uuid>,
    pub branch_officers: Vec<String>,
    pub assistant_accounts_officers: Vec<String>,
    pub total_employees: i64,
}

pub struct AttendanceQueryRepository;

impl AttendanceQueryRepository {
    pub async fn list_detailed_daily(
        pool: &PgPool,
        organization_id: Uuid,
        filter: DailyAttendanceFilter,
    ) -> Result<(Vec<DetailedAttendanceDailyRow>, i64)> {
        let search_pattern = filter.search.as_ref().map(|s| format!("%{}%", s));

        let rows = sqlx::query!(
            r#"
            SELECT
                ad.id,
                ad.organization_id,
                ad.employee_id,
                e.employee_code,
                CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) AS employee_name,
                e.designation_id,
                d.title AS designation_name,
                ad.section_id,
                s.name AS section_name,
                ad.attendance_date,
                ad.first_in,
                ad.last_out,
                ad.total_duty_minutes,
                ad.minutes_after_shift_start AS late_minutes,
                ad.late_after_grace_minutes,
                ad.early_exit_minutes,
                ad.status AS "status: AttendanceStatus",
                COUNT(*) OVER() AS total_count
            FROM attendance_daily ad
            JOIN employees e ON ad.employee_id = e.id
            JOIN designations d ON e.designation_id = d.id
            JOIN sections s ON ad.section_id = s.id
            WHERE ad.organization_id = $1
              AND ($2::date IS NULL OR ad.attendance_date = $2)
              AND ($3::date IS NULL OR ad.attendance_date >= $3)
              AND ($4::date IS NULL OR ad.attendance_date <= $4)
              AND ($5::uuid IS NULL OR ad.section_id = $5)
              AND ($6::uuid IS NULL OR ad.employee_id = $6)
              AND ($7::uuid IS NULL OR e.designation_id = $7)
              AND ($8::attendance_status IS NULL OR ad.status = $8)
              AND ($9::text IS NULL OR (
                    e.first_name ILIKE $9 OR
                    e.last_name ILIKE $9 OR
                    e.employee_code ILIKE $9 OR
                    e.attendance_device_user_id ILIKE $9
                  ))
            ORDER BY ad.attendance_date DESC, e.first_name ASC
            LIMIT $10 OFFSET $11
            "#,
            organization_id,
            filter.date,
            filter.start_date,
            filter.end_date,
            filter.section_id,
            filter.employee_id,
            filter.designation_id,
            filter.status as Option<AttendanceStatus>,
            search_pattern,
            filter.limit,
            filter.offset
        )
        .fetch_all(pool)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to query detailed daily attendance: {}", e))
        })?;

        let total = rows
            .first()
            .map(|r| r.total_count.unwrap_or(0))
            .unwrap_or(0);

        let items = rows
            .into_iter()
            .map(|r| DetailedAttendanceDailyRow {
                id: r.id,
                organization_id: r.organization_id,
                employee_id: r.employee_id,
                employee_code: r.employee_code,
                employee_name: r.employee_name.unwrap_or_default().trim().to_string(),
                designation_id: r.designation_id,
                designation_name: r.designation_name,
                section_id: r.section_id,
                section_name: r.section_name,
                attendance_date: r.attendance_date,
                first_in: r.first_in,
                last_out: r.last_out,
                total_duty_minutes: r.total_duty_minutes,
                late_minutes: r.late_minutes,
                late_minutes_beyond_grace: r.late_after_grace_minutes,
                early_exit_minutes: r.early_exit_minutes,
                status: r.status,
            })
            .collect();

        Ok((items, total))
    }

    pub async fn get_employee_stats(
        pool: &PgPool,
        employee_id: Uuid,
        start_date: Option<NaiveDate>,
        end_date: Option<NaiveDate>,
    ) -> Result<EmployeeAttendanceStats> {
        let row = sqlx::query!(
            r#"
            SELECT
                COUNT(id) AS total_days,
                COUNT(id) FILTER (WHERE status = 'PRESENT') AS present_days,
                COUNT(id) FILTER (WHERE status IN ('LATE', 'LATE_AND_EARLY_EXIT')) AS late_days,
                COUNT(id) FILTER (WHERE status = 'ABSENT') AS absent_days,
                COUNT(id) FILTER (WHERE status = 'HALF_DAY') AS half_days,
                COUNT(id) FILTER (WHERE status = 'INCOMPLETE') AS incomplete_days,
                COUNT(id) FILTER (WHERE status IN ('EARLY_EXIT', 'LATE_AND_EARLY_EXIT')) AS early_exit_days,
                COALESCE(AVG(total_duty_minutes) FILTER (WHERE status NOT IN ('ABSENT', 'INCOMPLETE')), 0)::BIGINT AS average_duty_minutes
            FROM attendance_daily
            WHERE employee_id = $1
              AND ($2::date IS NULL OR attendance_date >= $2)
              AND ($3::date IS NULL OR attendance_date <= $3)
            "#,
            employee_id,
            start_date,
            end_date
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query employee attendance stats: {}", e)))?;

        let total = row.total_days.unwrap_or(0);
        let pres = row.present_days.unwrap_or(0);
        let late_cnt = row.late_days.unwrap_or(0);
        let early_cnt = row.early_exit_days.unwrap_or(0);

        let rate = if total > 0 {
            ((pres + late_cnt + early_cnt) as f64 / total as f64) * 100.0
        } else {
            0.0
        };

        Ok(EmployeeAttendanceStats {
            employee_id,
            total_days: total,
            present_days: pres,
            late_days: late_cnt,
            absent_days: row.absent_days.unwrap_or(0),
            half_days: row.half_days.unwrap_or(0),
            incomplete_days: row.incomplete_days.unwrap_or(0),
            early_exit_days: early_cnt,
            attendance_rate: (rate * 100.0).round() / 100.0,
            average_duty_minutes: row.average_duty_minutes.unwrap_or(0),
        })
    }

    pub async fn get_section_hierarchy(
        pool: &PgPool,
        section_id: Uuid,
    ) -> Result<SectionHierarchyResponse> {
        let sec = sqlx::query!(
            r#"
            SELECT id, code, name, parent_section_id
            FROM sections
            WHERE id = $1
            "#,
            section_id
        )
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query section: {}", e)))?
        .ok_or_else(|| AimsError::NotFound("Section not found".into()))?;

        let officers = sqlx::query!(
            r#"
            SELECT
                CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) AS name,
                d.title AS designation_title
            FROM employees e
            JOIN designations d ON e.designation_id = d.id
            WHERE e.section_id = $1 AND e.status = 'ACTIVE'
            "#,
            section_id
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query section officers: {}", e)))?;

        let total_employees = officers.len() as i64;
        let mut bo_list = Vec::new();
        let mut aao_list = Vec::new();

        for o in officers {
            let title_lower = o.designation_title.to_lowercase();
            let name = o.name.unwrap_or_default().trim().to_string();
            if title_lower.contains("senior accounts officer")
                || title_lower.contains("sao")
                || title_lower.contains("bo")
            {
                bo_list.push(name);
            } else if title_lower.contains("assistant accounts officer")
                || title_lower.contains("aao")
            {
                aao_list.push(name);
            }
        }

        Ok(SectionHierarchyResponse {
            section_id: sec.id,
            section_code: sec.code,
            section_name: sec.name,
            parent_section_id: sec.parent_section_id,
            branch_officers: bo_list,
            assistant_accounts_officers: aao_list,
            total_employees,
        })
    }
}
