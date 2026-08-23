use aims_domain::PunchType;
use chrono::Utc;
use serde::{Deserialize, Serialize};

use crate::parser::ParsedRawPunch;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportRowError {
    pub row_number: i32,
    pub raw_text: String,
    pub error_type: String,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportWarning {
    pub row_number: i32,
    pub raw_text: String,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportValidationSummary {
    pub file_name: String,
    pub file_hash: String,
    pub total_records: i32,
    pub valid_records: i32,
    pub duplicate_records: i32,
    pub unknown_employees: i32,
    pub invalid_records: i32,
    pub warnings_count: i32,
    pub warnings: Vec<ImportWarning>,
    pub errors: Vec<ImportRowError>,
    #[serde(skip)]
    pub valid_punches: Vec<ParsedRawPunch>,
}

impl ImportValidationSummary {
    pub fn new(file_name: String, file_hash: String) -> Self {
        Self {
            file_name: sanitize_csv_formula(&file_name),
            file_hash,
            total_records: 0,
            valid_records: 0,
            duplicate_records: 0,
            unknown_employees: 0,
            invalid_records: 0,
            warnings_count: 0,
            warnings: Vec::new(),
            errors: Vec::new(),
            valid_punches: Vec::new(),
        }
    }
}

pub fn sanitize_csv_formula(val: &str) -> String {
    let trimmed = val.trim();
    if trimmed.starts_with('=')
        || trimmed.starts_with('+')
        || trimmed.starts_with('-')
        || trimmed.starts_with('@')
    {
        format!("'{}", trimmed)
    } else {
        trimmed.to_string()
    }
}

pub fn validate_parsed_punches(
    punches: Vec<ParsedRawPunch>,
    known_device_user_ids: &std::collections::HashSet<String>,
    existing_fingerprints: &std::collections::HashSet<String>,
    summary: &mut ImportValidationSummary,
) {
    summary.total_records = punches.len() as i32;

    let mut seen_in_file_fingerprints = std::collections::HashSet::new();
    let now = Utc::now();

    for mut p in punches {
        p.raw_text = sanitize_csv_formula(&p.raw_text);

        let is_unknown_emp = !known_device_user_ids.contains(&p.attendance_device_user_id);
        let is_dup_in_file = seen_in_file_fingerprints.contains(&p.event_fingerprint);
        let is_dup_in_db = existing_fingerprints.contains(&p.event_fingerprint);
        let is_future = p.punch_timestamp > now + chrono::Duration::minutes(5);

        if is_dup_in_file || is_dup_in_db {
            summary.duplicate_records += 1;
            summary.errors.push(ImportRowError {
                row_number: p.source_row_number,
                raw_text: p.raw_text.clone(),
                error_type: "DUPLICATE_EVENT".into(),
                message: if is_dup_in_file {
                    "Duplicate punch event within uploaded file".into()
                } else {
                    "Duplicate punch event already exists in database".into()
                },
            });
            continue;
        }

        seen_in_file_fingerprints.insert(p.event_fingerprint.clone());

        if is_unknown_emp {
            summary.unknown_employees += 1;
            summary.warnings_count += 1;
            summary.warnings.push(ImportWarning {
                row_number: p.source_row_number,
                raw_text: p.raw_text.clone(),
                message: format!(
                    "Attendance Device User ID '{}' will be auto-registered into employee master",
                    p.attendance_device_user_id
                ),
            });
        }

        if is_future {
            summary.invalid_records += 1;
            summary.errors.push(ImportRowError {
                row_number: p.source_row_number,
                raw_text: p.raw_text.clone(),
                error_type: "FUTURE_TIMESTAMP".into(),
                message: format!("Punch timestamp '{}' is in the future", p.punch_timestamp),
            });
            continue;
        }

        if p.is_inferred || p.punch_type == PunchType::Unknown {
            summary.warnings_count += 1;
            summary.warnings.push(ImportWarning {
                row_number: p.source_row_number,
                raw_text: p.raw_text.clone(),
                message: "Punch direction was inferred automatically".into(),
            });
        }

        summary.valid_records += 1;
        summary.valid_punches.push(p);
    }
}
