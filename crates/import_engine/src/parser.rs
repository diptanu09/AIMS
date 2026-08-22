use aims_common::{AimsError, Result};
use aims_domain::PunchType;
use chrono::{DateTime, NaiveDate, NaiveDateTime, NaiveTime, TimeZone, Utc};
use chrono_tz::Asia::Kolkata;
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use uuid::Uuid;

use crate::template::{ImportTemplate, InterpretationMode};

#[derive(Debug, Clone)]
pub struct ParsedRawPunch {
    pub source_row_number: i32,
    pub attendance_device_user_id: String,
    pub punch_timestamp: DateTime<Utc>,
    pub punch_type: PunchType,
    pub device_terminal_id: Option<String>,
    pub event_fingerprint: String,
    pub raw_text: String,
    pub is_inferred: bool,
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

pub fn parse_date_time_to_utc(
    date_str: Option<&str>,
    time_str: Option<&str>,
    datetime_str: Option<&str>,
) -> Result<DateTime<Utc>> {
    if let Some(dt_raw) = datetime_str {
        let cleaned = dt_raw.trim();
        if let Ok(dt) = DateTime::parse_from_rfc3339(cleaned) {
            return Ok(dt.with_timezone(&Utc));
        }

        if let Ok(ndt) = NaiveDateTime::parse_from_str(cleaned, "%Y-%m-%d %H:%M:%S") {
            let local_dt = Kolkata.from_local_datetime(&ndt).single().ok_or_else(|| {
                AimsError::Import(format!("Ambiguous or invalid local datetime '{}'", cleaned))
            })?;
            return Ok(local_dt.with_timezone(&Utc));
        }

        if let Ok(ndt) = NaiveDateTime::parse_from_str(cleaned, "%d/%m/%Y %H:%M:%S") {
            let local_dt = Kolkata.from_local_datetime(&ndt).single().ok_or_else(|| {
                AimsError::Import(format!("Ambiguous or invalid local datetime '{}'", cleaned))
            })?;
            return Ok(local_dt.with_timezone(&Utc));
        }
    }

    if let (Some(d_raw), Some(t_raw)) = (date_str, time_str) {
        let d_cleaned = d_raw.trim();
        let t_cleaned = t_raw.trim();

        let date = NaiveDate::parse_from_str(d_cleaned, "%Y-%m-%d")
            .or_else(|_| NaiveDate::parse_from_str(d_cleaned, "%d/%m/%Y"))
            .or_else(|_| NaiveDate::parse_from_str(d_cleaned, "%Y/%m/%d"))
            .map_err(|e| {
                AimsError::Import(format!("Failed to parse date '{}': {}", d_cleaned, e))
            })?;

        let time = NaiveTime::parse_from_str(t_cleaned, "%H:%M:%S")
            .or_else(|_| NaiveTime::parse_from_str(t_cleaned, "%H:%M"))
            .map_err(|e| {
                AimsError::Import(format!("Failed to parse time '{}': {}", t_cleaned, e))
            })?;

        let ndt = NaiveDateTime::new(date, time);
        let local_dt = Kolkata
            .from_local_datetime(&ndt)
            .single()
            .ok_or_else(|| AimsError::Import(format!("Invalid local datetime '{:?}'", ndt)))?;

        return Ok(local_dt.with_timezone(&Utc));
    }

    Err(AimsError::Import("Missing date/time values".to_string()))
}

pub fn parse_csv_bytes(
    organization_id: Uuid,
    bytes: &[u8],
    template: &ImportTemplate,
) -> Result<Vec<ParsedRawPunch>> {
    let mut reader = csv::ReaderBuilder::new()
        .trim(csv::Trim::All)
        .flexible(true)
        .from_reader(bytes);

    let headers = reader
        .headers()
        .map_err(|e| AimsError::Import(format!("Failed to read CSV header: {}", e)))?
        .clone();

    let header_index_map: HashMap<String, usize> = headers
        .iter()
        .enumerate()
        .map(|(idx, name)| (name.trim().to_lowercase(), idx))
        .collect();

    let user_id_col = template.column_mapping.device_user_id.trim().to_lowercase();
    let user_id_idx = *header_index_map.get(&user_id_col).ok_or_else(|| {
        AimsError::Import(format!(
            "Column '{}' for Attendance ID not found in CSV header",
            template.column_mapping.device_user_id
        ))
    })?;

    let date_idx = template
        .column_mapping
        .date
        .as_ref()
        .and_then(|name| header_index_map.get(&name.trim().to_lowercase()).copied());

    let time_idx = template
        .column_mapping
        .time
        .as_ref()
        .and_then(|name| header_index_map.get(&name.trim().to_lowercase()).copied());

    let datetime_idx = template
        .column_mapping
        .datetime
        .as_ref()
        .and_then(|name| header_index_map.get(&name.trim().to_lowercase()).copied());

    let punch_type_idx = template
        .column_mapping
        .punch_type
        .as_ref()
        .and_then(|name| header_index_map.get(&name.trim().to_lowercase()).copied());

    let device_id_idx = template
        .column_mapping
        .device_id
        .as_ref()
        .and_then(|name| header_index_map.get(&name.trim().to_lowercase()).copied());

    let mut raw_punches = Vec::new();
    let mut row_num = 1;

    #[allow(clippy::explicit_counter_loop)]
    for result in reader.records() {
        row_num += 1;
        let record = result
            .map_err(|e| AimsError::Import(format!("CSV error at row {}: {}", row_num, e)))?;

        let device_user_id = record.get(user_id_idx).unwrap_or("").trim().to_string();
        if device_user_id.is_empty() {
            continue;
        }

        let d_str = date_idx.and_then(|idx| record.get(idx));
        let t_str = time_idx.and_then(|idx| record.get(idx));
        let dt_str = datetime_idx.and_then(|idx| record.get(idx));

        let timestamp = parse_date_time_to_utc(d_str, t_str, dt_str)?;
        let raw_type = punch_type_idx.and_then(|idx| record.get(idx));
        let punch_type = parse_punch_type(raw_type);
        let terminal_id = device_id_idx
            .and_then(|idx| record.get(idx))
            .map(|s| s.trim().to_string());

        let raw_text = record.iter().collect::<Vec<&str>>().join(",");

        let fingerprint = compute_event_fingerprint(
            organization_id,
            &device_user_id,
            &timestamp,
            &punch_type,
            terminal_id.as_deref(),
        );

        raw_punches.push(ParsedRawPunch {
            source_row_number: row_num,
            attendance_device_user_id: device_user_id,
            punch_timestamp: timestamp,
            punch_type,
            device_terminal_id: terminal_id,
            event_fingerprint: fingerprint,
            raw_text,
            is_inferred: false,
        });
    }

    // Apply interpretation mode logic (e.g. AlternatingPunches)
    if template.interpretation_mode == InterpretationMode::AlternatingPunches {
        apply_alternating_punches(&mut raw_punches);
    }

    Ok(raw_punches)
}

fn apply_alternating_punches(punches: &mut [ParsedRawPunch]) {
    // Group punches by user and date, then set 1st = IN, 2nd = OUT, 3rd = IN, 4th = OUT
    punches.sort_by_key(|p| (p.attendance_device_user_id.clone(), p.punch_timestamp));

    let mut current_user = String::new();
    let mut current_date = None;
    let mut index_in_day = 0;

    for p in punches.iter_mut() {
        let p_date = p.punch_timestamp.date_naive();
        if p.attendance_device_user_id != current_user || current_date != Some(p_date) {
            current_user = p.attendance_device_user_id.clone();
            current_date = Some(p_date);
            index_in_day = 0;
        }

        if p.punch_type == PunchType::Unknown {
            p.punch_type = if index_in_day % 2 == 0 {
                PunchType::In
            } else {
                PunchType::Out
            };
            p.is_inferred = true;
        }
        index_in_day += 1;
    }
}
