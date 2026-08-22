use serde::{Deserialize, Serialize};

use crate::template::ImportTemplate;
use crate::validation::{ImportRowError, ImportWarning};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportPreviewResponse {
    pub file_name: String,
    pub file_hash: String,
    pub template_name: String,
    pub source_mode: String,
    pub total_records: i32,
    pub valid_records: i32,
    pub duplicate_records: i32,
    pub unknown_employees: i32,
    pub invalid_records: i32,
    pub warnings_count: i32,
    pub errors: Vec<ImportRowError>,
    pub warnings: Vec<ImportWarning>,
}

impl ImportPreviewResponse {
    pub fn from_summary(
        summary: &crate::validation::ImportValidationSummary,
        template: &ImportTemplate,
    ) -> Self {
        Self {
            file_name: summary.file_name.clone(),
            file_hash: summary.file_hash.clone(),
            template_name: template.name.clone(),
            source_mode: format!("{:?}", template.interpretation_mode),
            total_records: summary.total_records,
            valid_records: summary.valid_records,
            duplicate_records: summary.duplicate_records,
            unknown_employees: summary.unknown_employees,
            invalid_records: summary.invalid_records,
            warnings_count: summary.warnings_count,
            errors: summary.errors.clone(),
            warnings: summary.warnings.clone(),
        }
    }
}
