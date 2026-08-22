use aims_common::Result;
use aims_import_engine::{
    matrix_parser::parse_monthly_matrix_csv,
    template::ImportTemplate,
    validation::{validate_parsed_punches, ImportValidationSummary},
};
use aims_reporting::reconciliation::{
    calculate_reconciliation_summary, DiscrepancyCategory, ReconciliationDiscrepancy,
};
use chrono::NaiveDate;
use uuid::Uuid;

#[test]
fn test_pilot_reconciliation_summary_calculation() {
    let mock_discrepancies = vec![
        ReconciliationDiscrepancy {
            id: Uuid::now_v7(),
            employee_id: Uuid::now_v7(),
            employee_code: "EMP-001".into(),
            employee_name: "Test User 1".into(),
            attendance_date: NaiveDate::from_ymd_opt(2026, 8, 10).unwrap(),
            official_status: "PRESENT".into(),
            aims_status: "LATE".into(),
            official_duty_minutes: 480,
            aims_duty_minutes: 465,
            category: DiscrepancyCategory::PunchPairingDifference.as_str().into(),
            resolution_notes: None,
        },
        ReconciliationDiscrepancy {
            id: Uuid::now_v7(),
            employee_id: Uuid::now_v7(),
            employee_code: "EMP-002".into(),
            employee_name: "Test User 2".into(),
            attendance_date: NaiveDate::from_ymd_opt(2026, 8, 15).unwrap(),
            official_status: "ABSENT".into(),
            aims_status: "HOLIDAY".into(),
            official_duty_minutes: 0,
            aims_duty_minutes: 0,
            category: DiscrepancyCategory::HolidayDifference.as_str().into(),
            resolution_notes: None,
        },
    ];

    let summary = calculate_reconciliation_summary("August 2026".into(), 1000, &mock_discrepancies);

    assert_eq!(summary.total_official_records, 1000);
    assert_eq!(summary.differences, 2);
    assert_eq!(summary.exact_matches, 998);
    assert_eq!(summary.match_rate_percentage, 99.8);
    assert_eq!(summary.category_breakdown.len(), 2);
}

#[test]
fn test_sample_csv_zero_critical_discrepancies() -> Result<()> {
    let sample_csv_bytes = std::fs::read("sample.csv")
        .expect("Failed to read sample.csv fixture");

    let org_id = Uuid::now_v7();
    let template = ImportTemplate::nic_aadhaar_default();

    let punches = parse_monthly_matrix_csv(org_id, &sample_csv_bytes, &template)?;
    assert!(!punches.is_empty(), "Punches must be extracted");

    let mut known_emps = std::collections::HashSet::new();
    for p in &punches {
        known_emps.insert(p.attendance_device_user_id.clone());
    }

    let existing_fingerprints = std::collections::HashSet::new();
    let mut summary = ImportValidationSummary::new("sample.csv".into(), "hash123".into());

    validate_parsed_punches(punches, &known_emps, &existing_fingerprints, &mut summary);

    assert_eq!(summary.invalid_records, 0, "Future timestamp errors must be 0");
    assert_eq!(summary.unknown_employees, 0, "Unknown employee mapping errors must be 0");
    assert!(summary.valid_records > 0, "Valid records must be greater than 0");

    Ok(())
}
