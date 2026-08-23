use aims_auth::CurrentUser;
use aims_database::repositories::{
    attendance_rules::AttendanceRuleRepository,
    designations::DesignationRepository,
    employees::{EmployeeFilter, EmployeeRepository},
    organizations::OrganizationRepository,
    sections::SectionRepository,
};
use aims_domain::EmployeeStatus;
use chrono::{NaiveDate, NaiveTime};
use sqlx::postgres::PgPoolOptions;
use uuid::Uuid;

async fn setup_db() -> sqlx::PgPool {
    let database_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgres://postgres:root@123@127.0.0.1:5432/AIMS?search_path=AIMS".to_string()
    });

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to connect to PostgreSQL");

    sqlx::migrate!("./database/migrations")
        .run(&pool)
        .await
        .expect("Failed to run migrations");

    pool
}

#[tokio::test]
async fn test_organization_crud_and_uniqueness() {
    let db = setup_db().await;
    let code = format!("ORG{}", &Uuid::new_v4().to_string()[..6]).to_uppercase();

    // Create
    let org = OrganizationRepository::create(&db, &code, "Test Organization", "Asia/Kolkata")
        .await
        .unwrap();
    assert_eq!(org.code, code);
    assert_eq!(org.timezone, "Asia/Kolkata");

    // Find by code
    let found = OrganizationRepository::find_by_code(&db, &code)
        .await
        .unwrap();
    assert!(found.is_some());
    assert_eq!(found.unwrap().id, org.id);

    // Duplicate code should error
    let dup_res = OrganizationRepository::create(&db, &code, "Duplicate Org", "Asia/Kolkata").await;
    assert!(dup_res.is_err());
}

#[tokio::test]
async fn test_section_crud_and_circular_prevention() {
    let db = setup_db().await;
    let org_code = format!("ORG{}", &Uuid::new_v4().to_string()[..6]).to_uppercase();
    let org = OrganizationRepository::create(&db, &org_code, "Section Org", "Asia/Kolkata")
        .await
        .unwrap();

    // Create Root Section A
    let sec_a = SectionRepository::create(&db, org.id, "SEC_A", "Section A", None)
        .await
        .unwrap();

    // Create Child Section B under A
    let sec_b = SectionRepository::create(&db, org.id, "SEC_B", "Section B", Some(sec_a.id))
        .await
        .unwrap();

    // Create Child Section C under B
    let sec_c = SectionRepository::create(&db, org.id, "SEC_C", "Section C", Some(sec_b.id))
        .await
        .unwrap();

    // Test Circular Hierarchy: Attempting to set Section A's parent to Section C must return true (circular)
    let is_circular = SectionRepository::check_circular_reference(&db, sec_a.id, sec_c.id)
        .await
        .unwrap();
    assert!(
        is_circular,
        "Setting Sec C as parent of Sec A must be detected as circular"
    );

    // Non-circular check: Setting Sec C's parent to Sec A is fine
    let is_circular_valid = SectionRepository::check_circular_reference(&db, sec_c.id, sec_a.id)
        .await
        .unwrap();
    assert!(!is_circular_valid, "Valid hierarchy should not be circular");
}

#[tokio::test]
async fn test_designation_and_attendance_rule_crud() {
    let db = setup_db().await;
    let org_code = format!("ORG{}", &Uuid::new_v4().to_string()[..6]).to_uppercase();
    let org = OrganizationRepository::create(&db, &org_code, "Master Org", "Asia/Kolkata")
        .await
        .unwrap();

    // Designation
    let des = DesignationRepository::create(&db, org.id, "AO", "Accounts Officer", 90)
        .await
        .unwrap();
    assert_eq!(des.level, 90);

    let updated_des = DesignationRepository::update(
        &db,
        org.id,
        des.id,
        Some("Senior Accounts Officer"),
        Some(95),
    )
    .await
    .unwrap();
    assert_eq!(updated_des.title, "Senior Accounts Officer");
    assert_eq!(updated_des.level, 95);

    // Attendance Rule
    let rule = AttendanceRuleRepository::create(
        &db,
        org.id,
        "Standard Office",
        NaiveTime::from_hms_opt(9, 30, 0).unwrap(),
        NaiveTime::from_hms_opt(17, 30, 0).unwrap(),
        15,
        240,
        420,
        15,
        14,
        false,
        NaiveDate::from_ymd_opt(2026, 8, 1).unwrap(),
        None,
    )
    .await
    .unwrap();
    assert_eq!(rule.name, "Standard Office");
    assert_eq!(rule.grace_period_minutes, 15);
}

#[tokio::test]
async fn test_employee_crud_transfer_and_section_scope_security() {
    let db = setup_db().await;
    let org_code = format!("ORG{}", &Uuid::new_v4().to_string()[..6]).to_uppercase();
    let org = OrganizationRepository::create(&db, &org_code, "Emp Security Org", "Asia/Kolkata")
        .await
        .unwrap();

    let sec_a = SectionRepository::create(&db, org.id, "SEC_A", "Section A", None)
        .await
        .unwrap();
    let sec_b = SectionRepository::create(&db, org.id, "SEC_B", "Section B", None)
        .await
        .unwrap();

    let des = DesignationRepository::create(&db, org.id, "STAFF", "Senior Staff", 50)
        .await
        .unwrap();

    let rule = AttendanceRuleRepository::create(
        &db,
        org.id,
        "Shift 1",
        NaiveTime::from_hms_opt(9, 0, 0).unwrap(),
        NaiveTime::from_hms_opt(17, 0, 0).unwrap(),
        15,
        240,
        420,
        15,
        14,
        false,
        NaiveDate::from_ymd_opt(2026, 8, 1).unwrap(),
        None,
    )
    .await
    .unwrap();

    let emp_code = format!("EMP{}", &Uuid::new_v4().to_string()[..6]);
    let device_id = format!("DEV{}", &Uuid::new_v4().to_string()[..6]);

    // Create Employee in Section A
    let emp = EmployeeRepository::create(
        &db,
        org.id,
        &emp_code,
        &device_id,
        "Rajesh",
        Some("Kumar"),
        Some("Sharma"),
        Some("rajesh@org.gov.in"),
        None,
        sec_a.id,
        des.id,
        rule.id,
        NaiveDate::from_ymd_opt(2026, 1, 15).unwrap(),
        EmployeeStatus::Active,
        None,
    )
    .await
    .unwrap();

    assert_eq!(emp.section_id, sec_a.id);

    // Section Scope Security Checks (Section 6.34):
    // User BO_A is assigned strictly to Section A
    let bo_a = CurrentUser {
        user_id: Uuid::new_v4(),
        organization_id: org.id,
        username: "bo_sec_a".to_string(),
        roles: vec!["BO".to_string()],
        permissions: vec!["attendance.view.section".to_string()],
        section_ids: vec![sec_a.id],
    };

    assert!(
        bo_a.can_access_section(sec_a.id),
        "BO_A must have access to Section A"
    );
    assert!(
        !bo_a.can_access_section(sec_b.id),
        "BO_A must NOT have access to Section B"
    );

    // BO_A listing employees with allowed_section_ids = [sec_a.id]
    let (sec_a_items, _) = EmployeeRepository::list_paginated(
        &db,
        org.id,
        EmployeeFilter {
            search: None,
            section_id: None,
            designation_id: None,
            status: None,
            attendance_rule_id: None,
            joining_date_from: None,
            joining_date_to: None,
            allowed_section_ids: Some(vec![sec_a.id]),
        },
        1,
        10,
    )
    .await
    .unwrap();

    assert_eq!(sec_a_items.len(), 1);
    assert_eq!(sec_a_items[0].id, emp.id);

    // BO_A attempting to list Section B returns 0 items
    let (sec_b_items, _) = EmployeeRepository::list_paginated(
        &db,
        org.id,
        EmployeeFilter {
            search: None,
            section_id: None,
            designation_id: None,
            status: None,
            attendance_rule_id: None,
            joining_date_from: None,
            joining_date_to: None,
            allowed_section_ids: Some(vec![sec_b.id]),
        },
        1,
        10,
    )
    .await
    .unwrap();

    assert_eq!(sec_b_items.len(), 0);

    // Employee Section Transfer: Transfer Rajesh from Section A to Section B
    let transferred = EmployeeRepository::transfer_section(
        &db,
        org.id,
        emp.id,
        sec_b.id,
        NaiveDate::from_ymd_opt(2026, 9, 1).unwrap(),
        Some("Administrative transfer"),
        None,
    )
    .await
    .unwrap();

    assert_eq!(transferred.section_id, sec_b.id);

    // Employee Status Transition: Resign/Deactivate
    let resigned = EmployeeRepository::update_status(
        &db,
        org.id,
        emp.id,
        EmployeeStatus::Resigned,
        Some(NaiveDate::from_ymd_opt(2026, 9, 15).unwrap()),
    )
    .await
    .unwrap();

    assert_eq!(resigned.status, EmployeeStatus::Resigned);
    assert_eq!(
        resigned.leaving_date,
        Some(NaiveDate::from_ymd_opt(2026, 9, 15).unwrap())
    );
}
