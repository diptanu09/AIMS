#![allow(clippy::collapsible_if)]

use aims_common::{AimsError, Result};
use aims_domain::PunchType;
use chrono::{NaiveDate, NaiveDateTime, NaiveTime, TimeZone, Utc};
use chrono_tz::Asia::Kolkata;
use std::collections::HashMap;
use uuid::Uuid;

use crate::parser::{ParsedRawPunch, compute_event_fingerprint};
use crate::template::ImportTemplate;

pub fn parse_monthly_matrix_csv(
    organization_id: Uuid,
    bytes: &[u8],
    _template: &ImportTemplate,
) -> Result<Vec<ParsedRawPunch>> {
    let text = String::from_utf8_lossy(bytes);
    let lines: Vec<&str> = text.lines().collect();

    if lines.is_empty() {
        return Err(AimsError::Import("Uploaded CSV file is empty".to_string()));
    }

    // 1. Extract Month and Year from metadata (Line 1 or header area)
    let mut year = 2026i32;
    let mut month = 8u32;

    for line in lines.iter().take(5) {
        if line.contains("Month and Year") {
            if let Some(pos) = line.find("Month and Year") {
                let rest = &line[pos..];
                // e.g. Month and Year : 08 - 2026
                let parts: Vec<&str> = rest.split(':').collect();
                if parts.len() >= 2 {
                    let val = parts[1].trim().trim_matches('"').trim();
                    let mm_yyyy: Vec<&str> = val.split('-').map(|s| s.trim()).collect();
                    if mm_yyyy.len() == 2 {
                        if let (Ok(m), Ok(y)) =
                            (mm_yyyy[0].parse::<u32>(), mm_yyyy[1].parse::<i32>())
                        {
                            month = m;
                            year = y;
                        }
                    }
                }
            }
        }
    }

    // 2. Find header row (starts with "Attendance ID")
    let mut header_row_idx = None;
    for (idx, line) in lines.iter().enumerate() {
        if line.contains("Attendance ID") && line.contains("In-Time") || line.contains("1") {
            header_row_idx = Some(idx);
            break;
        }
    }

    let header_idx = header_row_idx.ok_or_else(|| {
        AimsError::Import("Header row containing 'Attendance ID' not found".to_string())
    })?;

    // Parse CSV rows using csv reader
    let csv_content = lines[header_idx..].join("\n");
    let mut reader = csv::ReaderBuilder::new()
        .trim(csv::Trim::All)
        .flexible(true)
        .from_reader(csv_content.as_bytes());

    let headers = reader
        .headers()
        .map_err(|e| AimsError::Import(format!("Failed to parse header: {}", e)))?
        .clone();

    let mut col_map = HashMap::new();
    for (idx, h) in headers.iter().enumerate() {
        let clean = h.trim().trim_matches('"').trim();
        col_map.insert(clean.to_string(), idx);
    }

    let user_id_idx = col_map.get("Attendance ID").copied().ok_or_else(|| {
        AimsError::Import("Column 'Attendance ID' not found in header".to_string())
    })?;

    let date_type_idx = col_map
        .get("Date")
        .or_else(|| col_map.get("Date "))
        .copied()
        .ok_or_else(|| AimsError::Import("Column 'Date' not found in header".to_string()))?;

    // Map day numbers 1..31 to column indices
    let mut day_col_map = HashMap::new();
    for day in 1..=31 {
        let day_str = day.to_string();
        if let Some(&idx) = col_map.get(&day_str) {
            day_col_map.insert(day, idx);
        }
    }

    let mut raw_punches = Vec::new();
    let mut current_user_id = String::new();
    let mut current_in_row: Option<csv::StringRecord> = None;
    let mut current_out_row: Option<csv::StringRecord> = None;

    let mut line_num = header_idx + 1;

    for result in reader.records() {
        line_num += 1;
        let record = result
            .map_err(|e| AimsError::Import(format!("CSV error at line {}: {}", line_num, e)))?;

        let user_id = record
            .get(user_id_idx)
            .unwrap_or("")
            .trim()
            .trim_matches('"')
            .to_string();
        let descriptor = record
            .get(date_type_idx)
            .unwrap_or("")
            .trim()
            .trim_matches('"')
            .to_string();

        if !user_id.is_empty() {
            current_user_id = user_id;
            current_in_row = None;
            current_out_row = None;
        }

        if current_user_id.is_empty() {
            continue;
        }

        if descriptor.eq_ignore_ascii_case("In-Time") {
            current_in_row = Some(record.clone());
        } else if descriptor.eq_ignore_ascii_case("Out-Time") {
            current_out_row = Some(record.clone());
        }

        // When we have both In-Time and Out-Time rows for current user
        if let (Some(in_rec), Some(out_rec)) = (&current_in_row, &current_out_row) {
            for day in 1..=31 {
                if let Some(date) = NaiveDate::from_ymd_opt(year, month, day) {
                    if let Some(&day_idx) = day_col_map.get(&day) {
                        let in_val = in_rec.get(day_idx).unwrap_or("").trim().trim_matches('"');
                        let out_val = out_rec.get(day_idx).unwrap_or("").trim().trim_matches('"');

                        // Emit IN punch if valid time present
                        if !in_val.is_empty() && in_val != "0" && in_val != "00:00" {
                            if let Ok(time) = NaiveTime::parse_from_str(in_val, "%H:%M")
                                .or_else(|_| NaiveTime::parse_from_str(in_val, "%H:%M:%S"))
                            {
                                let ndt = NaiveDateTime::new(date, time);
                                if let Some(local_dt) = Kolkata.from_local_datetime(&ndt).single() {
                                    let utc_dt = local_dt.with_timezone(&Utc);
                                    let fingerprint = compute_event_fingerprint(
                                        organization_id,
                                        &current_user_id,
                                        &utc_dt,
                                        &PunchType::In,
                                        None,
                                    );

                                    raw_punches.push(ParsedRawPunch {
                                        source_row_number: line_num as i32,
                                        attendance_device_user_id: current_user_id.clone(),
                                        punch_timestamp: utc_dt,
                                        punch_type: PunchType::In,
                                        device_terminal_id: None,
                                        event_fingerprint: fingerprint,
                                        raw_text: format!(
                                            "User:{},Date:{},In:{}",
                                            current_user_id, date, in_val
                                        ),
                                        is_inferred: false,
                                    });
                                }
                            }
                        }

                        // Emit OUT punch if valid time present
                        if !out_val.is_empty() && out_val != "0" && out_val != "00:00" {
                            if let Ok(time) = NaiveTime::parse_from_str(out_val, "%H:%M")
                                .or_else(|_| NaiveTime::parse_from_str(out_val, "%H:%M:%S"))
                            {
                                let ndt = NaiveDateTime::new(date, time);
                                if let Some(local_dt) = Kolkata.from_local_datetime(&ndt).single() {
                                    let utc_dt = local_dt.with_timezone(&Utc);
                                    let fingerprint = compute_event_fingerprint(
                                        organization_id,
                                        &current_user_id,
                                        &utc_dt,
                                        &PunchType::Out,
                                        None,
                                    );

                                    raw_punches.push(ParsedRawPunch {
                                        source_row_number: line_num as i32,
                                        attendance_device_user_id: current_user_id.clone(),
                                        punch_timestamp: utc_dt,
                                        punch_type: PunchType::Out,
                                        device_terminal_id: None,
                                        event_fingerprint: fingerprint,
                                        raw_text: format!(
                                            "User:{},Date:{},Out:{}",
                                            current_user_id, date, out_val
                                        ),
                                        is_inferred: false,
                                    });
                                }
                            }
                        }
                    }
                }
            }

            // Clear rows after processing
            current_in_row = None;
            current_out_row = None;
        }
    }

    Ok(raw_punches)
}
