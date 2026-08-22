use aims_common::{AimsError, Result};
use chrono::{DateTime, Utc};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, Clone, FromRow, serde::Serialize)]
pub struct AttendanceSessionRecord {
    pub id: Uuid,
    pub attendance_daily_id: Uuid,
    pub in_timestamp: DateTime<Utc>,
    pub out_timestamp: Option<DateTime<Utc>>,
    pub duration_minutes: i32,
    pub session_order: i32,
    pub is_inferred: bool,
}

pub struct AttendanceSessionRepository;

impl AttendanceSessionRepository {
    pub async fn replace_sessions_for_daily(
        pool: &PgPool,
        daily_id: Uuid,
        sessions: &[AttendanceSessionRecord],
    ) -> Result<()> {
        let mut tx = pool
            .begin()
            .await
            .map_err(|e| AimsError::Database(format!("Failed to begin transaction: {}", e)))?;

        sqlx::query("DELETE FROM attendance_sessions WHERE attendance_daily_id = $1")
            .bind(daily_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                AimsError::Database(format!("Failed to clear existing sessions: {}", e))
            })?;

        for s in sessions {
            sqlx::query(
                r#"
                INSERT INTO attendance_sessions (
                    id, attendance_daily_id, in_timestamp, out_timestamp,
                    duration_minutes, session_order, is_inferred
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                "#,
            )
            .bind(s.id)
            .bind(daily_id)
            .bind(s.in_timestamp)
            .bind(s.out_timestamp)
            .bind(s.duration_minutes)
            .bind(s.session_order)
            .bind(s.is_inferred)
            .execute(&mut *tx)
            .await
            .map_err(|e| AimsError::Database(format!("Failed to insert session: {}", e)))?;
        }

        tx.commit()
            .await
            .map_err(|e| AimsError::Database(format!("Failed to commit sessions: {}", e)))?;

        Ok(())
    }

    pub async fn list_by_daily(
        pool: &PgPool,
        daily_id: Uuid,
    ) -> Result<Vec<AttendanceSessionRecord>> {
        let sessions = sqlx::query_as::<_, AttendanceSessionRecord>(
            r#"
            SELECT id, attendance_daily_id, in_timestamp, out_timestamp,
                   duration_minutes, session_order, is_inferred
            FROM attendance_sessions
            WHERE attendance_daily_id = $1
            ORDER BY session_order ASC
            "#,
        )
        .bind(daily_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list sessions: {}", e)))?;

        Ok(sessions)
    }
}
