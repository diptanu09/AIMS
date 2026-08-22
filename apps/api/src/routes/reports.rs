use crate::{
    api::response::ApiResponse, error::AppError, services::reporting::ReportingService,
    state::AppState,
};
use aims_auth::CurrentUser;
use aims_database::repositories::reports::MonthlySectionReportRepository;
use aims_reporting::{
    GenerateReportRequest, generate_monthly_section_csv, generate_monthly_section_pdf,
};
use axum::{
    Extension, Json, Router,
    extract::{Path, State},
    http::{HeaderMap, StatusCode, header},
    response::IntoResponse,
    routing::{get, post},
};
use uuid::Uuid;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/generate", post(generate_report_handler))
        .route("/definitions", get(list_definitions_handler))
        .route("/runs", get(list_runs_handler))
        .route("/runs/{id}", get(get_run_handler))
        .route("/runs/{id}/download", get(download_report_handler))
}

pub async fn generate_report_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Json(payload): Json<GenerateReportRequest>,
) -> Result<impl IntoResponse, AppError> {
    let run = ReportingService::generate_report(&state.db, &actor, payload).await?;
    Ok((StatusCode::ACCEPTED, Json(ApiResponse::ok(run))))
}

pub async fn list_definitions_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> Result<impl IntoResponse, AppError> {
    let defs = ReportingService::list_report_definitions(&state.db, &actor).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(defs))))
}

pub async fn list_runs_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
) -> Result<impl IntoResponse, AppError> {
    let runs = ReportingService::list_report_runs(&state.db, &actor).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(runs))))
}

pub async fn get_run_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let run = ReportingService::get_report_run(&state.db, &actor, id).await?;
    Ok((StatusCode::OK, Json(ApiResponse::ok(run))))
}

pub async fn download_report_handler(
    State(state): State<AppState>,
    Extension(actor): Extension<CurrentUser>,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let run = ReportingService::get_report_run(&state.db, &actor, id).await?;

    let req: GenerateReportRequest = serde_json::from_value(run.parameters)
        .map_err(|e| AppError::Validation(format!("Failed to parse report params: {}", e)))?;

    let section_id = req
        .section_id
        .ok_or_else(|| AppError::Validation("section_id missing".into()))?;

    let data = MonthlySectionReportRepository::build_monthly_section_data(
        &state.db,
        actor.organization_id,
        section_id,
        req.date_from,
        req.date_to,
    )
    .await?;

    let (content_type, filename, payload_bytes) = match req.format {
        aims_domain::ReportFormat::Csv => (
            "text/csv",
            format!("report_{}.csv", run.id),
            generate_monthly_section_csv(&data)?,
        ),
        aims_domain::ReportFormat::Pdf => (
            "application/pdf",
            format!("report_{}.pdf", run.id),
            generate_monthly_section_pdf(&data)?,
        ),
        aims_domain::ReportFormat::Xlsx => (
            "text/csv",
            format!("report_{}.csv", run.id),
            generate_monthly_section_csv(&data)?,
        ),
    };

    let mut headers = HeaderMap::new();
    headers.insert(header::CONTENT_TYPE, content_type.parse().unwrap());
    headers.insert(
        header::CONTENT_DISPOSITION,
        format!("attachment; filename=\"{}\"", filename)
            .parse()
            .unwrap(),
    );

    Ok((headers, payload_bytes))
}
