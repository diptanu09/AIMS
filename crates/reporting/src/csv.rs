use crate::types::MonthlySectionReportData;
use aims_common::{AimsError, Result};

pub fn generate_monthly_section_csv(data: &MonthlySectionReportData) -> Result<Vec<u8>> {
    let mut wtr = csv::Writer::from_writer(Vec::new());

    wtr.write_record(["MONTHLY SECTION ATTENDANCE REPORT", ""])
        .map_err(|e| AimsError::Internal(e.to_string()))?;
    wtr.write_record(["Organization", &data.organization_name])
        .map_err(|e| AimsError::Internal(e.to_string()))?;
    wtr.write_record(["Section", &data.section_name])
        .map_err(|e| AimsError::Internal(e.to_string()))?;
    wtr.write_record(["Period", &data.month_year_label])
        .map_err(|e| AimsError::Internal(e.to_string()))?;
    wtr.write_record([
        "BO / Sr. AO",
        &if data.branch_officers.is_empty() {
            "N/A".into()
        } else {
            data.branch_officers.join(", ")
        },
    ])
    .map_err(|e| AimsError::Internal(e.to_string()))?;
    wtr.write_record([
        "AAO",
        &if data.assistant_accounts_officers.is_empty() {
            "N/A".into()
        } else {
            data.assistant_accounts_officers.join(", ")
        },
    ])
    .map_err(|e| AimsError::Internal(e.to_string()))?;
    wtr.write_record([""])
        .map_err(|e| AimsError::Internal(e.to_string()))?;

    wtr.write_record([
        "Sl No",
        "Employee Code",
        "Employee Name",
        "Designation",
        "Present Days",
        "Late Days",
        "Absent Days",
        "Half Days",
        "Incomplete Days",
        "Working Days",
        "Duty Percentage",
    ])
    .map_err(|e| AimsError::Internal(e.to_string()))?;

    for r in &data.rows {
        wtr.write_record([
            r.sl_no.to_string(),
            r.employee_code.clone(),
            r.employee_name.clone(),
            r.designation_title.clone(),
            r.present_days.to_string(),
            r.late_days.to_string(),
            r.absent_days.to_string(),
            r.half_days.to_string(),
            r.incomplete_days.to_string(),
            r.total_working_days.to_string(),
            format!("{:.2}%", r.duty_percentage),
        ])
        .map_err(|e| AimsError::Internal(e.to_string()))?;
    }

    wtr.flush().map_err(|e| AimsError::Internal(e.to_string()))?;
    let bytes = wtr
        .into_inner()
        .map_err(|e| AimsError::Internal(format!("CSV serialization failed: {}", e)))?;
    Ok(bytes)
}
