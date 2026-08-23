use crate::types::MonthlySectionReportData;
use aims_common::Result;

fn escape_pdf_str(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('(', "\\(")
        .replace(')', "\\)")
}

fn truncate(s: &str, max_len: usize) -> String {
    if s.chars().count() > max_len {
        s.chars().take(max_len).collect()
    } else {
        s.to_string()
    }
}

pub fn generate_monthly_section_pdf(data: &MonthlySectionReportData) -> Result<Vec<u8>> {
    let mut stream_content = String::new();

    // Begin Text Object
    stream_content.push_str("BT\n");

    // Document Header Title (Courier-Bold 14pt)
    stream_content.push_str("/F2 14 Tf\n");
    stream_content.push_str("40 750 Td\n");
    stream_content.push_str("(AIMS - MONTHLY SECTION ATTENDANCE REGISTER) Tj\n");

    // Subheader Org & Section Info (Courier 9pt)
    stream_content.push_str("/F1 9 Tf\n");
    stream_content.push_str("0 -18 Td\n");
    stream_content.push_str(&format!(
        "(Organization : {}) Tj\n",
        escape_pdf_str(&data.organization_name)
    ));
    stream_content.push_str("0 -13 Td\n");
    stream_content.push_str(&format!(
        "(Section      : {}  |  Period: {}) Tj\n",
        escape_pdf_str(&data.section_name),
        escape_pdf_str(&data.month_year_label)
    ));

    let bo_str = if data.branch_officers.is_empty() {
        "Unassigned".to_string()
    } else {
        data.branch_officers.join(", ")
    };
    let aao_str = if data.assistant_accounts_officers.is_empty() {
        "Unassigned".to_string()
    } else {
        data.assistant_accounts_officers.join(", ")
    };

    stream_content.push_str("0 -13 Td\n");
    stream_content.push_str(&format!(
        "(Branch Officer \\(Sr. AO\\): {}) Tj\n",
        escape_pdf_str(&bo_str)
    ));
    stream_content.push_str("0 -13 Td\n");
    stream_content.push_str(&format!(
        "(Assistant Accounts Officer \\(AAO\\): {}) Tj\n",
        escape_pdf_str(&aao_str)
    ));

    // Summary Line
    stream_content.push_str("0 -18 Td\n");
    stream_content.push_str(&format!(
        "(Summary: Staff: {} | Present: {} | Late: {} | Absent: {} | Avg Duty: {:.1}%) Tj\n",
        data.summary.total_staff,
        data.summary.present_days_total,
        data.summary.late_days_total,
        data.summary.absent_days_total,
        data.summary.average_duty_percentage
    ));

    // Table Divider & Header
    stream_content.push_str("0 -20 Td\n");
    stream_content.push_str("/F2 8.5 Tf\n");
    stream_content.push_str("(================================================================================) Tj\n");
    stream_content.push_str("0 -12 Td\n");
    stream_content.push_str("(SL  CODE       NAME                 DESIGNATION        PRES  LATE  ABS  WRK   DUTY %) Tj\n");
    stream_content.push_str("0 -12 Td\n");
    stream_content.push_str("(--------------------------------------------------------------------------------) Tj\n");

    // Table Data Rows
    stream_content.push_str("/F1 8.5 Tf\n");
    for r in &data.rows {
        stream_content.push_str("0 -13 Td\n");
        let line = format!(
            "{:<3} {:<10} {:<20} {:<18} {:<5} {:<5} {:<4} {:<5} {:.1}%",
            r.sl_no,
            truncate(&r.employee_code, 9),
            truncate(&r.employee_name, 18),
            truncate(&r.designation_title, 16),
            r.present_days,
            r.late_days,
            r.absent_days,
            r.total_working_days,
            r.duty_percentage
        );
        stream_content.push_str(&format!("({}) Tj\n", escape_pdf_str(&line)));
    }

    stream_content.push_str("0 -15 Td\n");
    stream_content.push_str("(================================================================================) Tj\n");

    // End Text Object
    stream_content.push_str("ET\n");

    let stream_bytes = stream_content.as_bytes();
    let stream_len = stream_bytes.len();

    // Assemble PDF objects and xref offsets
    let mut pdf = Vec::new();
    let mut offsets = Vec::new();

    // PDF Header
    pdf.extend_from_slice(b"%PDF-1.4\n%\xE2\xE3\xCF\xD3\n");

    // Object 1: Catalog
    offsets.push(pdf.len());
    pdf.extend_from_slice(b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");

    // Object 2: Pages
    offsets.push(pdf.len());
    pdf.extend_from_slice(b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n");

    // Object 3: Page Definition
    offsets.push(pdf.len());
    pdf.extend_from_slice(b"3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> /Contents 4 0 R >>\nendobj\n");

    // Object 4: Contents Stream
    offsets.push(pdf.len());
    let stream_header = format!("4 0 obj\n<< /Length {} >>\nstream\n", stream_len);
    pdf.extend_from_slice(stream_header.as_bytes());
    pdf.extend_from_slice(stream_bytes);
    pdf.extend_from_slice(b"\nendstream\nendobj\n");

    // Object 5: Font F1 (Courier)
    offsets.push(pdf.len());
    pdf.extend_from_slice(b"5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /WinAnsiEncoding >>\nendobj\n");

    // Object 6: Font F2 (Courier-Bold)
    offsets.push(pdf.len());
    pdf.extend_from_slice(b"6 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier-Bold /Encoding /WinAnsiEncoding >>\nendobj\n");

    // XRef Table
    let start_xref = pdf.len();
    pdf.extend_from_slice(format!("xref\n0 {}\n", offsets.len() + 1).as_bytes());
    pdf.extend_from_slice(b"0000000000 65535 f \n");
    for off in &offsets {
        pdf.extend_from_slice(format!("{:010} 00000 n \n", off).as_bytes());
    }

    // Trailer
    let trailer = format!(
        "trailer\n<< /Size {} /Root 1 0 R >>\nstartxref\n{}\n%%EOF\n",
        offsets.len() + 1,
        start_xref
    );
    pdf.extend_from_slice(trailer.as_bytes());

    Ok(pdf)
}
