use aims_common::Result;
use aims_database::repositories::{
    attendance_rules::AttendanceRuleRepository, designations::DesignationRepository,
    employees::EmployeeRepository, import_batches::ImportBatchRepository,
    import_templates::ImportTemplateRepository, organizations::OrganizationRepository,
    sections::SectionRepository,
};
use aims_domain::{EmployeeStatus, PunchType};
use aims_import_engine::{
    ColumnMapping, FileLayout, ImportTemplate, ImportValidationSummary, InterpretationMode,
    compute_file_hash, parse_csv_bytes, validate_parsed_punches,
};
use chrono::{NaiveDate, NaiveTime};
use sqlx::postgres::PgPoolOptions;
use uuid::Uuid;

async fn setup_db() -> sqlx::PgPool {
    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://aims_app:change_this_password@127.0.0.1:5434/aims".into());

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&db_url)
        .await
        .expect("Failed to connect to test database");

    sqlx::migrate!("./database/migrations")
        .run(&pool)
        .await
        .expect("Failed to run migrations");

    pool
}

#[tokio::test]
async fn test_canonical_import_parsing_and_validation() -> Result<()> {
    let pool = setup_db().await;
    let org_code = format!("IMP_{}", &Uuid::now_v7().simple().to_string()[..24]);
    let org =
        OrganizationRepository::create(&pool, &org_code, "Import Test Org", "Asia/Kolkata").await?;

    let sec = SectionRepository::create(&pool, org.id, "SEC_IMP", "Import Sec", None).await?;
    let des = DesignationRepository::create(&pool, org.id, "DES_IMP", "Tester", 1).await?;
    let rule = AttendanceRuleRepository::create(
        &pool,
        org.id,
        "General Shift",
        NaiveTime::from_hms_opt(9, 0, 0).unwrap(),
        NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
        15,
        240,
        420,
        15,
        14,
        false,
        NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        None,
    )
    .await?;

    // Create 2 known employees (IDs 1001, 1002)
    let _emp1 = EmployeeRepository::create(
        &pool,
        org.id,
        "EMP1001",
        "1001",
        "John",
        None,
        Some("Doe"),
        Some("john@example.com"),
        None,
        sec.id,
        des.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    let _emp2 = EmployeeRepository::create(
        &pool,
        org.id,
        "EMP1002",
        "1002",
        "Jane",
        None,
        Some("Smith"),
        Some("jane@example.com"),
        None,
        sec.id,
        des.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await?;

    let sample_csv = b"Attendance ID,Date,Time,Punch Type,Device ID\n1001,2026-08-20,09:12:14,IN,BIO-01\n1001,2026-08-20,17:36:05,OUT,BIO-01\n1002,2026-08-20,09:48:11,IN,BIO-01\n1003,2026-08-20,09:21:02,IN,BIO-01\n1001,2026-08-20,09:12:14,IN,BIO-01\n";

    let template = ImportTemplate::canonical_default();
    let parsed_punches = parse_csv_bytes(org.id, sample_csv, &template)?;

    assert_eq!(parsed_punches.len(), 5);

    let known_ids: std::collections::HashSet<String> = vec!["1001".to_string(), "1002".to_string()]
        .into_iter()
        .collect();
    let existing_fingerprints = std::collections::HashSet::new();

    let mut summary =
        ImportValidationSummary::new("test_import.csv".into(), compute_file_hash(sample_csv));
    validate_parsed_punches(
        parsed_punches,
        &known_ids,
        &existing_fingerprints,
        &mut summary,
    );

    // 5 total: 3 valid (1001 IN, 1001 OUT, 1002 IN), 1 unknown (1003), 1 duplicate (1001 IN duplicate row)
    assert_eq!(summary.total_records, 5);
    assert_eq!(summary.valid_records, 3);
    assert_eq!(summary.unknown_employees, 1);
    assert_eq!(summary.duplicate_records, 1);
    assert_eq!(summary.invalid_records, 0);

    Ok(())
}

#[tokio::test]
async fn test_alternating_punches_mode() -> Result<()> {
    let org_id = Uuid::now_v7();
    let sample_csv =
        b"Attendance ID,Date,Time\n1001,2026-08-20,09:12:00\n1001,2026-08-20,17:36:00\n";

    let template = ImportTemplate {
        id: None,
        name: "Alternating Mode".into(),
        description: None,
        file_type: "CSV".into(),
        delimiter: ",".into(),
        header_row_index: 1,
        column_mapping: ColumnMapping {
            device_user_id: "Attendance ID".into(),
            date: Some("Date".into()),
            time: Some("Time".into()),
            datetime: None,
            punch_type: None,
            device_id: None,
        },
        date_format: "%Y-%m-%d".into(),
        time_format: "%H:%M:%S".into(),
        interpretation_mode: InterpretationMode::AlternatingPunches,
        file_layout: FileLayout::RowPerPunch,
    };

    let punches = parse_csv_bytes(org_id, sample_csv, &template)?;
    assert_eq!(punches.len(), 2);
    assert_eq!(punches[0].punch_type, PunchType::In);
    assert_eq!(punches[1].punch_type, PunchType::Out);
    assert!(punches[0].is_inferred);
    assert!(punches[1].is_inferred);

    Ok(())
}

#[tokio::test]
async fn test_import_batch_and_template_db_flow() -> Result<()> {
    let pool = setup_db().await;
    let org_code = format!("TPL_{}", &Uuid::now_v7().simple().to_string()[..24]);
    let org =
        OrganizationRepository::create(&pool, &org_code, "Template DB Org", "Asia/Kolkata").await?;

    let mapping = serde_json::json!({
        "device_user_id": "User ID",
        "date": "Log Date",
        "time": "Log Time",
        "punch_type": "State",
        "device_id": "Terminal"
    });

    let _tpl = ImportTemplateRepository::create(
        &pool,
        org.id,
        "Biometric Export v2",
        Some("Custom device export format"),
        "CSV",
        ",",
        1,
        &mapping,
        "YYYY-MM-DD",
        "HH:mm:ss",
        "EXPLICIT_DIRECTION",
    )
    .await?;

    let user_id = Uuid::now_v7();
    let username = format!("user_{}", &user_id.simple().to_string()[..10]);
    let email = format!("user_{}@example.com", &user_id.simple().to_string()[..10]);
    sqlx::query(
        "INSERT INTO users (id, organization_id, username, password_hash, full_name, email) VALUES ($1, $2, $3, $4, $5, $6)"
    )
    .bind(user_id)
    .bind(org.id)
    .bind(&username)
    .bind("hash")
    .bind("Test Admin")
    .bind(&email)
    .execute(&pool)
    .await
    .map_err(|e| aims_common::AimsError::Database(e.to_string()))?;

    let batch =
        ImportBatchRepository::create(&pool, org.id, "august_20.csv", "hash1234567890", user_id)
            .await?;

    let fetched_batch = ImportBatchRepository::find_by_file_hash(&pool, org.id, "hash1234567890")
        .await?
        .expect("Should find batch by file hash");

    assert_eq!(fetched_batch.id, batch.id);

    Ok(())
}
