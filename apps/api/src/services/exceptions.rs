use aims_common::Result;
use aims_database::repositories::exceptions::{
    AttendanceExceptionRow, ExceptionFilter, ExceptionsRepository,
};
use sqlx::PgPool;
use uuid::Uuid;

pub struct ExceptionsService;

impl ExceptionsService {
    pub async fn list_exceptions(
        pool: &PgPool,
        organization_id: Uuid,
        filter: ExceptionFilter,
    ) -> Result<(Vec<AttendanceExceptionRow>, i64)> {
        ExceptionsRepository::list_exceptions(pool, organization_id, filter).await
    }
}
