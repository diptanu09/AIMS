pub mod matrix_parser;
pub mod parser;
pub mod preview;
pub mod template;
pub mod validation;

pub use parser::{
    ParsedRawPunch, compute_event_fingerprint, compute_file_hash, parse_csv_bytes,
    parse_date_time_to_utc, parse_punch_type,
};
pub use preview::ImportPreviewResponse;
pub use template::{ColumnMapping, FileLayout, ImportTemplate, InterpretationMode};
pub use validation::{
    ImportRowError, ImportValidationSummary, ImportWarning, validate_parsed_punches,
};

#[cfg(test)]
mod tests {
    use super::*;
    use aims_domain::PunchType;
    use uuid::Uuid;

    #[test]
    fn test_csv_parser_and_event_fingerprint() {
        let org_id = Uuid::now_v7();
        let sample_csv = b"Attendance ID,Date,Time,Punch Type,Device ID\n1001,2026-08-20,09:00:00,IN,BIO-01\n1001,2026-08-20,17:30:00,OUT,BIO-01\n";
        let template = ImportTemplate::canonical_default();

        let punches = parse_csv_bytes(org_id, sample_csv, &template).expect("Should parse CSV");
        assert_eq!(punches.len(), 2);

        let p1 = &punches[0];
        assert_eq!(p1.attendance_device_user_id, "1001");
        assert_eq!(p1.punch_type, PunchType::In);
        assert_eq!(p1.source_row_number, 2);

        let p2 = &punches[1];
        assert_eq!(p2.attendance_device_user_id, "1001");
        assert_eq!(p2.punch_type, PunchType::Out);
        assert_eq!(p2.source_row_number, 3);

        assert_ne!(p1.event_fingerprint, p2.event_fingerprint);
    }

    #[test]
    fn test_parse_real_cag_sample_csv() {
        let sample_bytes = include_bytes!("../../../sample.csv");
        let org_id = Uuid::now_v7();
        let template = ImportTemplate::nic_aadhaar_default();

        let punches = parse_csv_bytes(org_id, sample_bytes, &template)
            .expect("Should parse real CAG NIC Aadhaar sample CSV");

        // sample.csv contains 414 lines, ~138 employees with punches across August 2026
        assert!(punches.len() > 100);

        // Verify first employee ("404232" - Ajoy Dutta)
        let emp1_punches: Vec<&ParsedRawPunch> = punches
            .iter()
            .filter(|p| p.attendance_device_user_id == "404232")
            .collect();

        assert!(!emp1_punches.is_empty());
        let in_punches: Vec<&&ParsedRawPunch> = emp1_punches
            .iter()
            .filter(|p| p.punch_type == PunchType::In)
            .collect();
        let out_punches: Vec<&&ParsedRawPunch> = emp1_punches
            .iter()
            .filter(|p| p.punch_type == PunchType::Out)
            .collect();
        assert!(!in_punches.is_empty());
        assert!(!out_punches.is_empty());

        // Verify leading zero preservation for employee "045677"
        let emp_leading_zero: Vec<&ParsedRawPunch> = punches
            .iter()
            .filter(|p| p.attendance_device_user_id == "045677")
            .collect();
        assert!(!emp_leading_zero.is_empty());
    }

    #[test]
    fn test_template_match_confidence() {
        let template = ImportTemplate::canonical_default();
        let headers = vec![
            "Attendance ID".to_string(),
            "Date".to_string(),
            "Time".to_string(),
            "Punch Type".to_string(),
            "Device ID".to_string(),
        ];

        let score = template.match_confidence(&headers);
        assert_eq!(score, 100);
    }
}
