use aims_auth::CurrentUser;
use aims_reporting::reconciliation::{
    calculate_reconciliation_summary, DiscrepancyCategory, ReconciliationDiscrepancy,
};
use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::get,
    Extension, Json, Router,
};
use chrono::NaiveDate;
use uuid::Uuid;

use crate::{api::response::ApiResponse, error::ErrorResponse, state::AppState};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/summary", get(get_summary))
        .route("/discrepancies", get(get_discrepancies))
}

async fn get_summary(
    State(_state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> std::result::Result<impl IntoResponse, (StatusCode, Json<ErrorResponse>)> {
    let mock_discrepancies = get_mock_discrepancies(actor.organization_id);
    let summary = calculate_reconciliation_summary("August 2026".to_string(), 12845, &mock_discrepancies);
    Ok(Json(ApiResponse::ok(summary)))
}

async fn get_discrepancies(
    State(_state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> std::result::Result<impl IntoResponse, (StatusCode, Json<ErrorResponse>)> {
    let mock_discrepancies = get_mock_discrepancies(actor.organization_id);
    Ok(Json(ApiResponse::ok(mock_discrepancies)))
}

fn get_mock_discrepancies(org_id: Uuid) -> Vec<ReconciliationDiscrepancy> {
    vec![
        ReconciliationDiscrepancy {
            id: Uuid::now_v7(),
            employee_id: org_id,
            employee_code: "EMP-0456".into(),
            employee_name: "Rajesh Kumar".into(),
            attendance_date: NaiveDate::from_ymd_opt(2026, 8, 12).unwrap(),
            official_status: "PRESENT".into(),
            aims_status: "LATE".into(),
            official_duty_minutes: 480,
            aims_duty_minutes: 465,
            category: DiscrepancyCategory::PunchPairingDifference.as_str().into(),
            resolution_notes: Some("Legacy system ignored 15m late arrival grace threshold".into()),
        },
        ReconciliationDiscrepancy {
            id: Uuid::now_v7(),
            employee_id: org_id,
            employee_code: "EMP-0782".into(),
            employee_name: "Anil Sharma".into(),
            attendance_date: NaiveDate::from_ymd_opt(2026, 8, 15).unwrap(),
            official_status: "ABSENT".into(),
            aims_status: "HOLIDAY".into(),
            official_duty_minutes: 0,
            aims_duty_minutes: 0,
            category: DiscrepancyCategory::HolidayDifference.as_str().into(),
            resolution_notes: Some("Gazetted Independence Day holiday omitted in legacy calendar".into()),
        },
        ReconciliationDiscrepancy {
            id: Uuid::now_v7(),
            employee_id: org_id,
            employee_code: "EMP-1024".into(),
            employee_name: "Sunita Verma".into(),
            attendance_date: NaiveDate::from_ymd_opt(2026, 8, 20).unwrap(),
            official_status: "PRESENT".into(),
            aims_status: "CASUAL_LEAVE".into(),
            official_duty_minutes: 480,
            aims_duty_minutes: 0,
            category: DiscrepancyCategory::LeaveDifference.as_str().into(),
            resolution_notes: Some("Approved Casual Leave recorded in AIMS leave module".into()),
        },
    ]
}
