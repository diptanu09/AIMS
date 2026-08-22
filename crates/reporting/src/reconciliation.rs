use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum DiscrepancyCategory {
    RuleDifference,
    PunchPairingDifference,
    MissingEmployeeMapping,
    HolidayDifference,
    LeaveDifference,
    LateThresholdDifference,
    EarlyExitDifference,
    DataQuality,
    AimsBug,
    SourceDataError,
}

impl DiscrepancyCategory {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::RuleDifference => "RULE_DIFFERENCE",
            Self::PunchPairingDifference => "PUNCH_PAIRING_DIFFERENCE",
            Self::MissingEmployeeMapping => "MISSING_EMPLOYEE_MAPPING",
            Self::HolidayDifference => "HOLIDAY_DIFFERENCE",
            Self::LeaveDifference => "LEAVE_DIFFERENCE",
            Self::LateThresholdDifference => "LATE_THRESHOLD_DIFFERENCE",
            Self::EarlyExitDifference => "EARLY_EXIT_DIFFERENCE",
            Self::DataQuality => "DATA_QUALITY",
            Self::AimsBug => "AIMS_BUG",
            Self::SourceDataError => "SOURCE_DATA_ERROR",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiscrepancyCategoryCount {
    pub category: String,
    pub count: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReconciliationSummary {
    pub period_name: String,
    pub total_official_records: i32,
    pub total_aims_records: i32,
    pub exact_matches: i32,
    pub differences: i32,
    pub match_rate_percentage: f64,
    pub category_breakdown: Vec<DiscrepancyCategoryCount>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReconciliationDiscrepancy {
    pub id: Uuid,
    pub employee_id: Uuid,
    pub employee_code: String,
    pub employee_name: String,
    pub attendance_date: NaiveDate,
    pub official_status: String,
    pub aims_status: String,
    pub official_duty_minutes: i32,
    pub aims_duty_minutes: i32,
    pub category: String,
    pub resolution_notes: Option<String>,
}

pub fn calculate_reconciliation_summary(
    period_name: String,
    official_total: i32,
    discrepancies: &[ReconciliationDiscrepancy],
) -> ReconciliationSummary {
    let differences = discrepancies.len() as i32;
    let exact_matches = (official_total - differences).max(0);
    let match_rate_percentage = if official_total > 0 {
        ((exact_matches as f64) / (official_total as f64)) * 100.0
    } else {
        100.0
    };

    let mut counts_map = std::collections::HashMap::new();
    for d in discrepancies {
        *counts_map.entry(d.category.clone()).or_insert(0) += 1;
    }

    let mut category_breakdown: Vec<DiscrepancyCategoryCount> = counts_map
        .into_iter()
        .map(|(category, count)| DiscrepancyCategoryCount { category, count })
        .collect();

    category_breakdown.sort_by_key(|b| std::cmp::Reverse(b.count));

    ReconciliationSummary {
        period_name,
        total_official_records: official_total,
        total_aims_records: official_total,
        exact_matches,
        differences,
        match_rate_percentage,
        category_breakdown,
    }
}
