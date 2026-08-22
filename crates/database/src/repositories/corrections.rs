use aims_common::{AimsError, Result};
use aims_domain::{AttendanceCorrection, AttendanceStatus, CorrectionStatus};
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct DetailedCorrectionRow {
    pub id: Uuid,
    pub attendance_daily_id: Uuid,
    pub employee_id: Uuid,
    pub employee_code: String,
    pub employee_name: String,
    pub section_name: String,
    pub attendance_date: chrono::NaiveDate,
    pub requested_by: Uuid,
    pub requester_name: String,
    pub original_first_in: Option<DateTime<Utc>>,
    pub original_last_out: Option<DateTime<Utc>>,
    pub original_status: AttendanceStatus,
    pub corrected_first_in: Option<DateTime<Utc>>,
    pub corrected_last_out: Option<DateTime<Utc>>,
    pub corrected_status: AttendanceStatus,
    pub reason: String,
    pub status: CorrectionStatus,
    pub approved_by: Option<Uuid>,
    pub approver_name: Option<String>,
    pub approved_at: Option<DateTime<Utc>>,
    pub rejection_reason: Option<String>,
    pub created_at: DateTime<Utc>,
}

pub struct CorrectionRepository;

impl CorrectionRepository {
    pub async fn create(
        pool: &PgPool,
        attendance_daily_id: Uuid,
        requested_by: Uuid,
        original_first_in: Option<DateTime<Utc>>,
        original_last_out: Option<DateTime<Utc>>,
        original_status: AttendanceStatus,
        corrected_first_in: Option<DateTime<Utc>>,
        corrected_last_out: Option<DateTime<Utc>>,
        corrected_status: AttendanceStatus,
        reason: &str,
    ) -> Result<AttendanceCorrection> {
        let rec = sqlx::query_as!(
            AttendanceCorrection,
            r#"
            INSERT INTO attendance_corrections (
                attendance_daily_id, requested_by, original_first_in, original_last_out, original_status,
                corrected_first_in, corrected_last_out, corrected_status, reason, status
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'PENDING')
            RETURNING id, attendance_daily_id, requested_by, original_first_in, original_last_out,
                      original_status AS "original_status: AttendanceStatus", corrected_first_in, corrected_last_out,
                      corrected_status AS "corrected_status: AttendanceStatus", reason, status AS "status: CorrectionStatus",
                      approved_by, approved_at, rejection_reason, created_at
            "#,
            attendance_daily_id,
            requested_by,
            original_first_in,
            original_last_out,
            original_status as AttendanceStatus,
            corrected_first_in,
            corrected_last_out,
            corrected_status as AttendanceStatus,
            reason
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to create attendance correction: {}", e)))?;

        Ok(rec)
    }

    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<AttendanceCorrection>> {
        let rec = sqlx::query_as!(
            AttendanceCorrection,
            r#"
            SELECT id, attendance_daily_id, requested_by, original_first_in, original_last_out,
                   original_status AS "original_status: AttendanceStatus", corrected_first_in, corrected_last_out,
                   corrected_status AS "corrected_status: AttendanceStatus", reason, status AS "status: CorrectionStatus",
                   approved_by, approved_at, rejection_reason, created_at
            FROM attendance_corrections
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to find attendance correction: {}", e)))?;

        Ok(rec)
    }

    pub async fn list_detailed(
        pool: &PgPool,
        organization_id: Uuid,
        status: Option<CorrectionStatus>,
    ) -> Result<Vec<DetailedCorrectionRow>> {
        let rows = sqlx::query!(
            r#"
            SELECT
                ac.id,
                ac.attendance_daily_id,
                ad.employee_id,
                e.employee_code,
                CONCAT(e.first_name, ' ', COALESCE(e.last_name, '')) AS employee_name,
                s.name AS section_name,
                ad.attendance_date,
                ac.requested_by,
                u_req.username AS requester_name,
                ac.original_first_in,
                ac.original_last_out,
                ac.original_status AS "original_status: AttendanceStatus",
                ac.corrected_first_in,
                ac.corrected_last_out,
                ac.corrected_status AS "corrected_status: AttendanceStatus",
                ac.reason,
                ac.status AS "status: CorrectionStatus",
                ac.approved_by,
                u_app.username AS "approver_name?",
                ac.approved_at,
                ac.rejection_reason,
                ac.created_at
            FROM attendance_corrections ac
            JOIN attendance_daily ad ON ac.attendance_daily_id = ad.id
            JOIN employees e ON ad.employee_id = e.id
            JOIN sections s ON ad.section_id = s.id
            JOIN users u_req ON ac.requested_by = u_req.id
            LEFT JOIN users u_app ON ac.approved_by = u_app.id
            WHERE ad.organization_id = $1
              AND ($2::correction_status IS NULL OR ac.status = $2)
            ORDER BY ac.created_at DESC
            "#,
            organization_id,
            status as Option<CorrectionStatus>
        )
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list corrections: {}", e)))?;

        let items = rows
            .into_iter()
            .map(|r| DetailedCorrectionRow {
                id: r.id,
                attendance_daily_id: r.attendance_daily_id,
                employee_id: r.employee_id,
                employee_code: r.employee_code,
                employee_name: r.employee_name.unwrap_or_default().trim().to_string(),
                section_name: r.section_name,
                attendance_date: r.attendance_date,
                requested_by: r.requested_by,
                requester_name: r.requester_name,
                original_first_in: r.original_first_in,
                original_last_out: r.original_last_out,
                original_status: r.original_status,
                corrected_first_in: r.corrected_first_in,
                corrected_last_out: r.corrected_last_out,
                corrected_status: r.corrected_status,
                reason: r.reason,
                status: r.status,
                approved_by: r.approved_by,
                approver_name: r.approver_name,
                approved_at: r.approved_at,
                rejection_reason: r.rejection_reason,
                created_at: r.created_at,
            })
            .collect();

        Ok(items)
    }

    pub async fn approve(
        pool: &PgPool,
        id: Uuid,
        approved_by: Uuid,
    ) -> Result<AttendanceCorrection> {
        let rec = sqlx::query_as!(
            AttendanceCorrection,
            r#"
            UPDATE attendance_corrections
            SET status = 'APPROVED',
                approved_by = $2,
                approved_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING id, attendance_daily_id, requested_by, original_first_in, original_last_out,
                      original_status AS "original_status: AttendanceStatus", corrected_first_in, corrected_last_out,
                      corrected_status AS "corrected_status: AttendanceStatus", reason, status AS "status: CorrectionStatus",
                      approved_by, approved_at, rejection_reason, created_at
            "#,
            id,
            approved_by
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to approve correction: {}", e)))?;

        Ok(rec)
    }

    pub async fn reject(
        pool: &PgPool,
        id: Uuid,
        approved_by: Uuid,
        reason: &str,
    ) -> Result<AttendanceCorrection> {
        let rec = sqlx::query_as!(
            AttendanceCorrection,
            r#"
            UPDATE attendance_corrections
            SET status = 'REJECTED',
                approved_by = $2,
                approved_at = CURRENT_TIMESTAMP,
                rejection_reason = $3
            WHERE id = $1
            RETURNING id, attendance_daily_id, requested_by, original_first_in, original_last_out,
                      original_status AS "original_status: AttendanceStatus", corrected_first_in, corrected_last_out,
                      corrected_status AS "corrected_status: AttendanceStatus", reason, status AS "status: CorrectionStatus",
                      approved_by, approved_at, rejection_reason, created_at
            "#,
            id,
            approved_by,
            reason
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to reject correction: {}", e)))?;

        Ok(rec)
    }
}
