use aims_common::Result;
use aims_database::repositories::dashboard::{
    AttendanceTrendRow, DashboardRepository, DashboardSummary, SectionSummary,
};
use chrono::NaiveDate;
use sqlx::PgPool;
use uuid::Uuid;

pub struct DashboardService;

impl DashboardService {
    pub async fn get_summary(
        pool: &PgPool,
        organization_id: Uuid,
        date: NaiveDate,
    ) -> Result<DashboardSummary> {
        DashboardRepository::get_summary(pool, organization_id, date).await
    }

    pub async fn get_sections(
        pool: &PgPool,
        organization_id: Uuid,
        date: NaiveDate,
    ) -> Result<Vec<SectionSummary>> {
        DashboardRepository::get_section_summaries(pool, organization_id, date).await
    }

    pub async fn get_trends(
        pool: &PgPool,
        organization_id: Uuid,
        from_date: NaiveDate,
        to_date: NaiveDate,
        section_id: Option<Uuid>,
    ) -> Result<Vec<AttendanceTrendRow>> {
        DashboardRepository::get_trends(pool, organization_id, from_date, to_date, section_id).await
    }
}
