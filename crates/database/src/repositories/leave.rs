use aims_common::{AimsError, Result};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DetailedLeaveRecordRow {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub employee_id: Uuid,
    pub employee_code: String,
    pub employee_name: String,
    pub leave_type: String,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub status: String,
    pub reason: Option<String>,
    pub requested_by: Uuid,
    pub approved_by: Option<Uuid>,
    pub approved_at: Option<DateTime<Utc>>,
    pub rejection_reason: Option<String>,
    pub created_at: DateTime<Utc>,
}

pub struct LeaveRepository;

impl LeaveRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        employee_id: Uuid,
        leave_type: &str,
        start_date: NaiveDate,
        end_date: NaiveDate,
        reason: Option<&str>,
        requested_by: Uuid,
    ) -> Result<Uuid> {
        let rec = sqlx::query!(
            r#"
            INSERT INTO leave_records (
                organization_id, employee_id, leave_type, start_date, end_date, reason, requested_by, status
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, 'PENDING'::leave_status)
            RETURNING id
            "#,
            organization_id,
            employee_id,
            leave_type,
            start_date,
            end_date,
            reason,
            requested_by
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to create leave record: {}", e)))?;

        Ok(rec.id)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<DetailedLeaveRecordRow>> {
        let rows = sqlx::query!(
            r#"
            SELECT
                l.id,
                l.organization_id,
                l.employee_id,
                e.employee_code,
                CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) AS employee_name,
                l.leave_type,
                l.start_date,
                l.end_date,
                l.status::text AS "status!",
                l.reason,
                l.requested_by,
                l.approved_by,
                l.approved_at,
                l.rejection_reason,
                l.created_at
            FROM leave_records l
            JOIN employees e ON l.employee_id = e.id
            WHERE l.organization_id = $1
            ORDER BY l.created_at DESC
            "#,
            organization_id
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list leave records: {}", e)))?;

        let items = rows
            .into_iter()
            .map(|r| DetailedLeaveRecordRow {
                id: r.id,
                organization_id: r.organization_id,
                employee_id: r.employee_id,
                employee_code: r.employee_code,
                employee_name: r.employee_name.unwrap_or_default().trim().to_string(),
                leave_type: r.leave_type,
                start_date: r.start_date,
                end_date: r.end_date,
                status: r.status,
                reason: r.reason,
                requested_by: r.requested_by,
                approved_by: r.approved_by,
                approved_at: r.approved_at,
                rejection_reason: r.rejection_reason,
                created_at: r.created_at,
            })
            .collect();

        Ok(items)
    }
}
