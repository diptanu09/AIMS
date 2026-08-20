use aims_common::{AimsError, Result};
use aims_domain::PunchType;
use chrono::{DateTime, NaiveDateTime, TimeZone, Utc};
use hex;
use serde::Deserialize;
use sha2::{Digest, Sha256};
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct ParsedRawPunch {
    pub source_row_number: i32,
    pub attendance_device_user_id: String,
    pub punch_timestamp: DateTime<Utc>,
    pub punch_type: PunchType,
    pub device_terminal_id: Option<String>,
    pub event_fingerprint: String,
    pub raw_text: String,
}

#[derive(Debug, Deserialize)]
struct CsvPunchRecord {
    #[serde(alias = "DeviceUserId", alias = "UserID", alias = "EmployeeCode", alias = "User ID", alias = "Emp Code")]
    device_user_id: String,

    #[serde(alias = "Timestamp", alias = "PunchTime", alias = "DateTime", alias = "Punch Time", alias = "Date Time")]
    timestamp: String,

    #[serde(alias = "PunchType", alias = "Type", alias = "Direction", alias = "Punch Type", alias = "Status")]
    punch_type: Option<String>,

    #[serde(alias = "TerminalId", alias = "MachineID", alias = "Terminal", alias = "Device ID")]
    terminal_id: Option<String>,
}

pub fn compute_file_hash(bytes: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(bytes);
    hex::encode(hasher.finalize())
}

pub fn compute_event_fingerprint(
    organization_id: Uuid,
    device_user_id: &str,
    punch_timestamp: &DateTime<Utc>,
    punch_type: &PunchType,
    terminal_id: Option<&str>,
) -> String {
    let mut hasher = Sha256::new();
    let payload = format!(
        "{}:{}:{}:{:?}:{}",
        organization_id,
        device_user_id.trim(),
        punch_timestamp.to_rfc3339(),
        punch_type,
        terminal_id.unwrap_or("DEFAULT")
    );
    hasher.update(payload.as_bytes());
    hex::encode(hasher.finalize())
}

pub fn parse_punch_type(raw: Option<&str>) -> PunchType {
    match raw.map(|s| s.trim().to_uppercase()).as_deref() {
        Some("IN") | Some("0") | Some("CHECKIN") | Some("ENTRY") => PunchType::In,
        Some("OUT") | Some("1") | Some("CHECKOUT") | Some("EXIT") => PunchType::Out,
        _ => PunchType::Unknown,
    }
}

pub fn parse_timestamp(raw: &str) -> Result<DateTime<Utc>> {
    let cleaned = raw.trim();

    // 1. Try RFC3339 / ISO8601
    if let Ok(dt) = DateTime::parse_from_rfc3339(cleaned) {
        return Ok(dt.with_timezone(&Utc));
    }

    // 2. Try common formats "YYYY-MM-DD HH:MM:SS"
    if let Ok(ndt) = NaiveDateTime::parse_from_str(cleaned, "%Y-%m-%d %H:%M:%S") {
        return Ok(Utc.from_utc_datetime(&ndt));
    }

    // 3. Try "DD/MM/YYYY HH:MM:SS"
    if let Ok(ndt) = NaiveDateTime::parse_from_str(cleaned, "%d/%m/%Y %H:%M:%S") {
        return Ok(Utc.from_utc_datetime(&ndt));
    }

    // 4. Try "YYYY/MM/DD HH:MM:SS"
    if let Ok(ndt) = NaiveDateTime::parse_from_str(cleaned, "%Y/%m/%d %H:%M:%S") {
        return Ok(Utc.from_utc_datetime(&ndt));
    }

    Err(AimsError::Import(format!(
        "Failed to parse timestamp '{}'. Expected formats: YYYY-MM-DD HH:MM:SS, DD/MM/YYYY HH:MM:SS, or ISO8601",
        raw
    )))
}

pub fn parse_csv_punches(organization_id: Uuid, csv_bytes: &[u8]) -> Result<Vec<ParsedRawPunch>> {
    let mut reader = csv::ReaderBuilder::new()
        .trim(csv::Trim::All)
        .flexible(true)
        .from_reader(csv_bytes);

    let mut results = Vec::new();
    let mut row_num = 1;

    for result in reader.deserialize::<CsvPunchRecord>() {
        row_num += 1;
        match result {
            Ok(rec) => {
                let timestamp = parse_timestamp(&rec.timestamp)?;
                let punch_type = parse_punch_type(rec.punch_type.as_deref());
                let terminal_id = rec.terminal_id.as_deref();
                let fingerprint = compute_event_fingerprint(
                    organization_id,
                    &rec.device_user_id,
                    &timestamp,
                    &punch_type,
                    terminal_id,
                );

                let raw_text = format!(
                    "{},{},{},{}",
                    rec.device_user_id,
                    rec.timestamp,
                    rec.punch_type.as_deref().unwrap_or(""),
                    rec.terminal_id.as_deref().unwrap_or("")
                );

                results.push(ParsedRawPunch {
                    source_row_number: row_num,
                    attendance_device_user_id: rec.device_user_id,
                    punch_timestamp: timestamp,
                    punch_type,
                    device_terminal_id: rec.terminal_id,
                    event_fingerprint: fingerprint,
                    raw_text,
                });
            }
            Err(e) => {
                return Err(AimsError::Import(format!(
                    "CSV parsing error at row {}: {}",
                    row_num, e
                )));
            }
        }
    }

    Ok(results)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_csv_parser_and_event_fingerprint() {
        let org_id = Uuid::now_v7();
        let sample_csv = b"DeviceUserId,Timestamp,PunchType,TerminalId\n1001,2026-08-20 09:00:00,IN,T01\n1001,2026-08-20 17:30:00,OUT,T01\n";

        let punches = parse_csv_punches(org_id, sample_csv).expect("Should parse CSV");
        assert_eq!(punches.len(), 2);

        let p1 = &punches[0];
        assert_eq!(p1.attendance_device_user_id, "1001");
        assert_eq!(p1.punch_type, PunchType::In);
        assert_eq!(p1.source_row_number, 2);

        let p2 = &punches[1];
        assert_eq!(p2.attendance_device_user_id, "1001");
        assert_eq!(p2.punch_type, PunchType::Out);
        assert_eq!(p2.source_row_number, 3);

        // Fingerprints must be distinct for different timestamps
        assert_ne!(p1.event_fingerprint, p2.event_fingerprint);
    }

    #[test]
    fn test_parse_sample_fixture() {
        let fixture_bytes = include_bytes!("../../../database/fixtures/sample_attendance_punches.csv");
        let org_id = Uuid::now_v7();

        let punches = parse_csv_punches(org_id, fixture_bytes).expect("Should parse sample fixture");
        assert_eq!(punches.len(), 6);

        let hash = compute_file_hash(fixture_bytes);
        assert_eq!(hash.len(), 64);
    }
}
