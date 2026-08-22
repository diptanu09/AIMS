use crate::types::MonthlySectionReportData;
use aims_common::Result;

pub fn generate_monthly_section_pdf(data: &MonthlySectionReportData) -> Result<Vec<u8>> {
    let mut doc = String::new();
    doc.push_str("%PDF-1.4\n");
    doc.push_str("% AIMS Monthly Section Attendance Report PDF Document\n");
    doc.push_str(&format!("% Organization: {}\n", data.organization_name));
    doc.push_str(&format!("% Section: {}\n", data.section_name));
    doc.push_str(&format!("% Period: {}\n", data.month_year_label));
    doc.push_str(&format!(
        "% BO / Sr. AO: {}\n",
        if data.branch_officers.is_empty() {
            "N/A".into()
        } else {
            data.branch_officers.join(", ")
        }
    ));
    doc.push_str(&format!(
        "% AAO: {}\n",
        if data.assistant_accounts_officers.is_empty() {
            "N/A".into()
        } else {
            data.assistant_accounts_officers.join(", ")
        }
    ));
    doc.push_str("% Sl | Code | Name | Designation | Present | Late | Absent | Duty %\n");

    for r in &data.rows {
        doc.push_str(&format!(
            "% {} | {} | {} | {} | {} | {} | {} | {:.2}%\n",
            r.sl_no,
            r.employee_code,
            r.employee_name,
            r.designation_title,
            r.present_days,
            r.late_days,
            r.absent_days,
            r.duty_percentage
        ));
    }
    doc.push_str("%%EOF\n");

    Ok(doc.into_bytes())
}
