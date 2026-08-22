use aims_common::{AimsError, Result};
use aims_domain::Employee;
use chrono::NaiveDate;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EmployeeRepository;

impl EmployeeRepository {
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        employee_code: &str,
        attendance_device_user_id: &str,
        first_name: &str,
        last_name: &str,
        email: Option<&str>,
        mobile: Option<&str>,
        section_id: Uuid,
        designation_id: Uuid,
        attendance_rule_id: Uuid,
        joining_date: NaiveDate,
    ) -> Result<Employee> {
        let emp = sqlx::query_as::<_, Employee>(
            r#"
            INSERT INTO employees (
                organization_id, employee_code, attendance_device_user_id,
                first_name, last_name, email, mobile, section_id,
                designation_id, attendance_rule_id, joining_date, status
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'ACTIVE')
            RETURNING id, organization_id, employee_code, attendance_device_user_id,
                      first_name, last_name, email, mobile, section_id,
                      designation_id, attendance_rule_id, joining_date, leaving_date,
                      status, created_at, updated_at
            "#,
        )
        .bind(organization_id)
        .bind(employee_code)
        .bind(attendance_device_user_id)
        .bind(first_name)
        .bind(last_name)
        .bind(email)
        .bind(mobile)
        .bind(section_id)
        .bind(designation_id)
        .bind(attendance_rule_id)
        .bind(joining_date)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert employee: {}", e)))?;

        Ok(emp)
    }

    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<Employee>> {
        let emp = sqlx::query_as::<_, Employee>(
            r#"
            SELECT id, organization_id, employee_code, attendance_device_user_id,
                   first_name, last_name, email, mobile, section_id,
                   designation_id, attendance_rule_id, joining_date, leaving_date,
                   status, created_at, updated_at
            FROM employees
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query employee by id: {}", e)))?;

        Ok(emp)
    }

    pub async fn find_by_device_user_id(
        pool: &PgPool,
        organization_id: Uuid,
        device_user_id: &str,
    ) -> Result<Option<Employee>> {
        let emp = sqlx::query_as::<_, Employee>(
            r#"
            SELECT id, organization_id, employee_code, attendance_device_user_id,
                   first_name, last_name, email, mobile, section_id,
                   designation_id, attendance_rule_id, joining_date, leaving_date,
                   status, created_at, updated_at
            FROM employees
            WHERE organization_id = $1 AND attendance_device_user_id = $2
            "#,
        )
        .bind(organization_id)
        .bind(device_user_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query employee: {}", e)))?;

        Ok(emp)
    }

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<Employee>> {
        let employees = sqlx::query_as::<_, Employee>(
            r#"
            SELECT id, organization_id, employee_code, attendance_device_user_id,
                   first_name, last_name, email, mobile, section_id,
                   designation_id, attendance_rule_id, joining_date, leaving_date,
                   status, created_at, updated_at
            FROM employees
            WHERE organization_id = $1
            ORDER BY first_name ASC, last_name ASC
            "#,
        )
        .bind(organization_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list employees: {}", e)))?;

        Ok(employees)
    }

    pub async fn list_by_section(pool: &PgPool, section_id: Uuid) -> Result<Vec<Employee>> {
        let employees = sqlx::query_as::<_, Employee>(
            r#"
            SELECT id, organization_id, employee_code, attendance_device_user_id,
                   first_name, last_name, email, mobile, section_id,
                   designation_id, attendance_rule_id, joining_date, leaving_date,
                   status, created_at, updated_at
            FROM employees
            WHERE section_id = $1
            ORDER BY first_name ASC, last_name ASC
            "#,
        )
        .bind(section_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to list employees by section: {}", e)))?;

        Ok(employees)
    }
}
