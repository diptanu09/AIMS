use aims_common::Result;
use aims_domain::PunchType;
use chrono::{DateTime, NaiveDateTime, Utc};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::io::Read;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParsedPunchRecord {
    pub source_row_number: i32,
    pub attendance_device_user_id: String,
    pub timestamp: DateTime<Utc>,
    pub punch_type: PunchType,
    pub device_terminal_id: Option<String>,
    pub event_fingerprint: String,
    pub raw_text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportValidationSummary {
    pub total_records: usize,
    pub valid_records: usize,
    pub duplicate_records: usize,
    pub unknown_employees: usize,
    pub invalid_records: usize,
    pub parsed: Vec<ParsedPunchRecord>,
}

pub struct CsvAttendanceImporter;

impl CsvAttendanceImporter {
    pub fn parse_csv<R: Read>(reader: R) -> Result<ImportValidationSummary> {
        let mut csv_reader = csv::ReaderBuilder::new()
            .flexible(true)
            .trim(csv::Trim::All)
            .from_reader(reader);

        let mut parsed = Vec::new();
        let mut total = 0;
        let mut valid = 0;
        let mut invalid = 0;

        for (idx, result) in csv_reader.records().enumerate() {
            total += 1;
            let row_number = (idx + 1) as i32;

            let record = match result {
                Ok(r) => r,
                Err(_) => {
                    invalid += 1;
                    continue;
                }
            };

            if record.len() < 2 {
                invalid += 1;
                continue;
            }

            let device_user_id = record.get(0).unwrap_or_default().trim().to_string();
            let raw_ts = record.get(1).unwrap_or_default().trim();

            if device_user_id.is_empty() || raw_ts.is_empty() {
                invalid += 1;
                continue;
            }

            let parsed_ts = if let Ok(dt) = DateTime::parse_from_rfc3339(raw_ts) {
                dt.with_timezone(&Utc)
            } else if let Ok(ndt) = NaiveDateTime::parse_from_str(raw_ts, "%Y-%m-%d %H:%M:%S") {
                ndt.and_utc()
            } else if let Ok(ndt) = NaiveDateTime::parse_from_str(raw_ts, "%d/%m/%Y %H:%M:%S") {
                ndt.and_utc()
            } else {
                invalid += 1;
                continue;
            };

            let punch_type_str = record.get(2).unwrap_or("UNKNOWN").trim().to_uppercase();
            let punch_type = match punch_type_str.as_str() {
                "IN" | "CHECK-IN" => PunchType::In,
                "OUT" | "CHECK-OUT" => PunchType::Out,
                _ => PunchType::Unknown,
            };

            let terminal_id = record.get(3).map(|s| s.trim().to_string());
            let raw_text = format!("{},{},{},{}", device_user_id, raw_ts, punch_type_str, terminal_id.as_deref().unwrap_or_default());

            // Compute deterministic SHA-256 fingerprint for immutability & deduplication
            let mut hasher = Sha256::new();
            hasher.update(device_user_id.as_bytes());
            hasher.update(parsed_ts.to_rfc3339().as_bytes());
            hasher.update(punch_type_str.as_bytes());
            let event_fingerprint = format!("{:x}", hasher.finalize());

            parsed.push(ParsedPunchRecord {
                source_row_number: row_number,
                attendance_device_user_id: device_user_id,
                timestamp: parsed_ts,
                punch_type,
                device_terminal_id: terminal_id,
                event_fingerprint,
                raw_text,
            });

            valid += 1;
        }

        Ok(ImportValidationSummary {
            total_records: total,
            valid_records: valid,
            duplicate_records: 0,
            unknown_employees: 0,
            invalid_records: invalid,
            parsed,
        })
    }
}
