use aims_domain::{ReportFormat, ReportType};
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerateReportRequest {
    pub report_type: ReportType,
    pub format: ReportFormat,
    pub date_from: NaiveDate,
    pub date_to: NaiveDate,
    pub section_id: Option<Uuid>,
    pub employee_id: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonthlySectionSummary {
    pub total_staff: i64,
    pub present_days_total: i64,
    pub late_days_total: i64,
    pub absent_days_total: i64,
    pub average_duty_percentage: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonthlySectionRow {
    pub sl_no: usize,
    pub employee_code: String,
    pub employee_name: String,
    pub designation_title: String,
    pub present_days: i64,
    pub late_days: i64,
    pub absent_days: i64,
    pub half_days: i64,
    pub incomplete_days: i64,
    pub total_working_days: i64,
    pub duty_percentage: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonthlySectionReportData {
    pub organization_name: String,
    pub section_name: String,
    pub month_year_label: String,
    pub branch_officers: Vec<String>,
    pub assistant_accounts_officers: Vec<String>,
    pub summary: MonthlySectionSummary,
    pub rows: Vec<MonthlySectionRow>,
}
