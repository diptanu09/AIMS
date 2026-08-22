use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Default)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum FileLayout {
    #[default]
    RowPerPunch,
    MonthlyEmployeeMatrix,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Default)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum InterpretationMode {
    #[default]
    ExplicitDirection,
    AlternatingPunches,
    DeviceStateBased,
    ControlledInference,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ColumnMapping {
    pub device_user_id: String,
    pub date: Option<String>,
    pub time: Option<String>,
    pub datetime: Option<String>,
    pub punch_type: Option<String>,
    pub device_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportTemplate {
    pub id: Option<Uuid>,
    pub name: String,
    pub description: Option<String>,
    pub file_type: String,
    pub delimiter: String,
    pub header_row_index: i32,
    pub column_mapping: ColumnMapping,
    pub date_format: String,
    pub time_format: String,
    pub interpretation_mode: InterpretationMode,
    #[serde(default)]
    pub file_layout: FileLayout,
}

impl ImportTemplate {
    pub fn canonical_default() -> Self {
        Self {
            id: None,
            name: "Canonical Attendance Format".into(),
            description: Some("Default canonical CSV format".into()),
            file_type: "CSV".into(),
            delimiter: ",".into(),
            header_row_index: 1,
            column_mapping: ColumnMapping {
                device_user_id: "Attendance ID".into(),
                date: Some("Date".into()),
                time: Some("Time".into()),
                datetime: None,
                punch_type: Some("Punch Type".into()),
                device_id: Some("Device ID".into()),
            },
            date_format: "%Y-%m-%d".into(),
            time_format: "%H:%M:%S".into(),
            interpretation_mode: InterpretationMode::ExplicitDirection,
            file_layout: FileLayout::RowPerPunch,
        }
    }

    pub fn nic_aadhaar_default() -> Self {
        Self {
            id: None,
            name: "NIC Aadhaar BAS Monthly Export".into(),
            description: Some(
                "Monthly employee matrix format from CAG / NIC Aadhaar Attendance System".into(),
            ),
            file_type: "CSV".into(),
            delimiter: ",".into(),
            header_row_index: 3,
            column_mapping: ColumnMapping {
                device_user_id: "Attendance ID".into(),
                date: Some("Date".into()),
                time: None,
                datetime: None,
                punch_type: None,
                device_id: None,
            },
            date_format: "%Y-%m-%d".into(),
            time_format: "%H:%M".into(),
            interpretation_mode: InterpretationMode::ExplicitDirection,
            file_layout: FileLayout::MonthlyEmployeeMatrix,
        }
    }

    pub fn match_confidence(&self, headers: &[String]) -> u32 {
        let normalized_headers: Vec<String> =
            headers.iter().map(|h| h.trim().to_lowercase()).collect();

        let mut matched = 0u32;
        let mut total = 0u32;

        // User ID column (Required)
        total += 2;
        if normalized_headers.contains(&self.column_mapping.device_user_id.trim().to_lowercase()) {
            matched += 2;
        }

        // Date/Time columns (Required)
        if let Some(ref dt_col) = self.column_mapping.datetime {
            total += 2;
            if normalized_headers.contains(&dt_col.trim().to_lowercase()) {
                matched += 2;
            }
        } else {
            if let Some(ref d_col) = self.column_mapping.date {
                total += 1;
                if normalized_headers.contains(&d_col.trim().to_lowercase()) {
                    matched += 1;
                }
            }
            if let Some(ref t_col) = self.column_mapping.time {
                total += 1;
                if normalized_headers.contains(&t_col.trim().to_lowercase()) {
                    matched += 1;
                }
            }
        }

        // Optional columns
        if let Some(ref pt_col) = self.column_mapping.punch_type {
            total += 1;
            if normalized_headers.contains(&pt_col.trim().to_lowercase()) {
                matched += 1;
            }
        }

        if let Some(ref dev_col) = self.column_mapping.device_id {
            total += 1;
            if normalized_headers.contains(&dev_col.trim().to_lowercase()) {
                matched += 1;
            }
        }

        if total == 0 {
            0
        } else {
            ((matched as f64 / total as f64) * 100.0) as u32
        }
    }
}
