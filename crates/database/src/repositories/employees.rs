use aims_common::{AimsError, Result};
use aims_domain::{Employee, EmployeeStatus};
use chrono::NaiveDate;
use sqlx::{PgPool, Postgres, QueryBuilder};
use uuid::Uuid;

pub struct EmployeeRepository;

pub struct EmployeeFilter<'a> {
    pub search: Option<&'a str>,
    pub section_id: Option<Uuid>,
    pub designation_id: Option<Uuid>,
    pub status: Option<EmployeeStatus>,
    pub attendance_rule_id: Option<Uuid>,
    pub joining_date_from: Option<NaiveDate>,
    pub joining_date_to: Option<NaiveDate>,
    pub allowed_section_ids: Option<Vec<Uuid>>,
}

impl EmployeeRepository {
    #[allow(clippy::too_many_arguments)]
    pub async fn create(
        pool: &PgPool,
        organization_id: Uuid,
        employee_code: &str,
        attendance_device_user_id: &str,
        first_name: &str,
        middle_name: Option<&str>,
        last_name: Option<&str>,
        email: Option<&str>,
        mobile: Option<&str>,
        section_id: Uuid,
        designation_id: Uuid,
        attendance_rule_id: Uuid,
        joining_date: NaiveDate,
        status: EmployeeStatus,
        created_by: Option<Uuid>,
    ) -> Result<Employee> {
        let mut tx = pool
            .begin()
            .await
            .map_err(|e| AimsError::Database(format!("Failed to begin transaction: {}", e)))?;

        let emp = sqlx::query_as::<_, Employee>(
            r#"
            INSERT INTO employees (
                organization_id, employee_code, attendance_device_user_id,
                first_name, middle_name, last_name, email, mobile, section_id,
                designation_id, attendance_rule_id, joining_date, status
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING id, organization_id, employee_code, attendance_device_user_id,
                      first_name, middle_name, last_name, email, mobile, section_id,
                      designation_id, attendance_rule_id, joining_date, leaving_date,
                      status, created_at, updated_at
            "#,
        )
        .bind(organization_id)
        .bind(employee_code)
        .bind(attendance_device_user_id)
        .bind(first_name)
        .bind(middle_name)
        .bind(last_name)
        .bind(email)
        .bind(mobile)
        .bind(section_id)
        .bind(designation_id)
        .bind(attendance_rule_id)
        .bind(joining_date)
        .bind(status)
        .fetch_one(&mut *tx)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to insert employee: {}", e)))?;

        // Record initial section assignment history
        sqlx::query(
            r#"
            INSERT INTO employee_section_assignments (
                employee_id, section_id, effective_from, reason, created_by
            )
            VALUES ($1, $2, $3, 'Initial assignment', $4)
            "#,
        )
        .bind(emp.id)
        .bind(section_id)
        .bind(joining_date)
        .bind(created_by)
        .execute(&mut *tx)
        .await
        .map_err(|e| {
            AimsError::Database(format!(
                "Failed to record initial section assignment: {}",
                e
            ))
        })?;

        tx.commit().await.map_err(|e| {
            AimsError::Database(format!("Failed to commit employee creation tx: {}", e))
        })?;

        Ok(emp)
    }

    pub async fn find_by_id(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
    ) -> Result<Option<Employee>> {
        let emp = sqlx::query_as::<_, Employee>(
            r#"
            SELECT id, organization_id, employee_code, attendance_device_user_id,
                   first_name, middle_name, last_name, email, mobile, section_id,
                   designation_id, attendance_rule_id, joining_date, leaving_date,
                   status, created_at, updated_at
            FROM employees
            WHERE id = $1 AND organization_id = $2
            "#,
        )
        .bind(id)
        .bind(organization_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query employee by id: {}", e)))?;

        Ok(emp)
    }

    pub async fn find_any_by_id(pool: &PgPool, id: Uuid) -> Result<Option<Employee>> {
        let emp = sqlx::query_as::<_, Employee>(
            r#"
            SELECT id, organization_id, employee_code, attendance_device_user_id,
                   first_name, middle_name, last_name, email, mobile, section_id,
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

    pub async fn list_by_organization(
        pool: &PgPool,
        organization_id: Uuid,
    ) -> Result<Vec<Employee>> {
        let (items, _) = Self::list_paginated(
            pool,
            organization_id,
            EmployeeFilter {
                search: None,
                section_id: None,
                designation_id: None,
                status: None,
                attendance_rule_id: None,
                joining_date_from: None,
                joining_date_to: None,
                allowed_section_ids: None,
            },
            1,
            1000,
        )
        .await?;

        Ok(items)
    }

    pub async fn find_by_code(
        pool: &PgPool,
        organization_id: Uuid,
        employee_code: &str,
    ) -> Result<Option<Employee>> {
        let emp = sqlx::query_as::<_, Employee>(
            r#"
            SELECT id, organization_id, employee_code, attendance_device_user_id,
                   first_name, middle_name, last_name, email, mobile, section_id,
                   designation_id, attendance_rule_id, joining_date, leaving_date,
                   status, created_at, updated_at
            FROM employees
            WHERE organization_id = $1 AND employee_code = $2
            "#,
        )
        .bind(organization_id)
        .bind(employee_code)
        .fetch_optional(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query employee by code: {}", e)))?;

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
                   first_name, middle_name, last_name, email, mobile, section_id,
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

    #[allow(clippy::too_many_arguments)]
    pub async fn update(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
        first_name: Option<&str>,
        middle_name: Option<Option<&str>>,
        last_name: Option<Option<&str>>,
        email: Option<Option<&str>>,
        mobile: Option<Option<&str>>,
        designation_id: Option<Uuid>,
        attendance_rule_id: Option<Uuid>,
    ) -> Result<Employee> {
        let current = Self::find_by_id(pool, organization_id, id)
            .await?
            .ok_or_else(|| AimsError::NotFound(format!("Employee {} not found", id)))?;

        let new_first = first_name.unwrap_or(&current.first_name);
        let new_middle = match middle_name {
            Some(v) => v,
            None => current.middle_name.as_deref(),
        };
        let new_last = match last_name {
            Some(v) => v,
            None => current.last_name.as_deref(),
        };
        let new_email = match email {
            Some(v) => v,
            None => current.email.as_deref(),
        };
        let new_mobile = match mobile {
            Some(v) => v,
            None => current.mobile.as_deref(),
        };
        let new_desig = designation_id.unwrap_or(current.designation_id);
        let new_rule = attendance_rule_id.unwrap_or(current.attendance_rule_id);

        let updated = sqlx::query_as::<_, Employee>(
            r#"
            UPDATE employees
            SET first_name = $1, middle_name = $2, last_name = $3,
                email = $4, mobile = $5, designation_id = $6,
                attendance_rule_id = $7, updated_at = CURRENT_TIMESTAMP
            WHERE id = $8 AND organization_id = $9
            RETURNING id, organization_id, employee_code, attendance_device_user_id,
                      first_name, middle_name, last_name, email, mobile, section_id,
                      designation_id, attendance_rule_id, joining_date, leaving_date,
                      status, created_at, updated_at
            "#,
        )
        .bind(new_first)
        .bind(new_middle)
        .bind(new_last)
        .bind(new_email)
        .bind(new_mobile)
        .bind(new_desig)
        .bind(new_rule)
        .bind(id)
        .bind(organization_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to update employee: {}", e)))?;

        Ok(updated)
    }

    pub async fn update_status(
        pool: &PgPool,
        organization_id: Uuid,
        id: Uuid,
        status: EmployeeStatus,
        leaving_date: Option<NaiveDate>,
    ) -> Result<Employee> {
        let updated = sqlx::query_as::<_, Employee>(
            r#"
            UPDATE employees
            SET status = $1, leaving_date = $2, updated_at = CURRENT_TIMESTAMP
            WHERE id = $3 AND organization_id = $4
            RETURNING id, organization_id, employee_code, attendance_device_user_id,
                      first_name, middle_name, last_name, email, mobile, section_id,
                      designation_id, attendance_rule_id, joining_date, leaving_date,
                      status, created_at, updated_at
            "#,
        )
        .bind(status)
        .bind(leaving_date)
        .bind(id)
        .bind(organization_id)
        .fetch_one(pool)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to update employee status: {}", e)))?;

        Ok(updated)
    }

    pub async fn transfer_section(
        pool: &PgPool,
        organization_id: Uuid,
        employee_id: Uuid,
        new_section_id: Uuid,
        effective_date: NaiveDate,
        reason: Option<&str>,
        created_by: Option<Uuid>,
    ) -> Result<Employee> {
        let mut tx = pool
            .begin()
            .await
            .map_err(|e| AimsError::Database(format!("Failed to begin transaction: {}", e)))?;

        let current = sqlx::query_as::<_, Employee>(
            r#"
            SELECT id, organization_id, employee_code, attendance_device_user_id,
                   first_name, middle_name, last_name, email, mobile, section_id,
                   designation_id, attendance_rule_id, joining_date, leaving_date,
                   status, created_at, updated_at
            FROM employees
            WHERE id = $1 AND organization_id = $2
            "#,
        )
        .bind(employee_id)
        .bind(organization_id)
        .fetch_optional(&mut *tx)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to query employee: {}", e)))?
        .ok_or_else(|| AimsError::NotFound(format!("Employee {} not found", employee_id)))?;

        if current.section_id == new_section_id {
            return Err(AimsError::Validation(
                "Employee is already assigned to this section".to_string(),
            ));
        }

        // Close current assignment
        let day_before = effective_date.pred_opt().unwrap_or(effective_date);
        sqlx::query(
            r#"
            UPDATE employee_section_assignments
            SET effective_to = $1
            WHERE employee_id = $2 AND effective_to IS NULL
            "#,
        )
        .bind(day_before)
        .bind(employee_id)
        .execute(&mut *tx)
        .await
        .map_err(|e| {
            AimsError::Database(format!(
                "Failed to close previous section assignment: {}",
                e
            ))
        })?;

        // Insert new assignment
        sqlx::query(
            r#"
            INSERT INTO employee_section_assignments (
                employee_id, section_id, effective_from, reason, created_by
            )
            VALUES ($1, $2, $3, $4, $5)
            "#,
        )
        .bind(employee_id)
        .bind(new_section_id)
        .bind(effective_date)
        .bind(reason)
        .bind(created_by)
        .execute(&mut *tx)
        .await
        .map_err(|e| {
            AimsError::Database(format!("Failed to insert new section assignment: {}", e))
        })?;

        // Update employee current section
        let updated = sqlx::query_as::<_, Employee>(
            r#"
            UPDATE employees
            SET section_id = $1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $2 AND organization_id = $3
            RETURNING id, organization_id, employee_code, attendance_device_user_id,
                      first_name, middle_name, last_name, email, mobile, section_id,
                      designation_id, attendance_rule_id, joining_date, leaving_date,
                      status, created_at, updated_at
            "#,
        )
        .bind(new_section_id)
        .bind(employee_id)
        .bind(organization_id)
        .fetch_one(&mut *tx)
        .await
        .map_err(|e| AimsError::Database(format!("Failed to update employee section: {}", e)))?;

        tx.commit().await.map_err(|e| {
            AimsError::Database(format!("Failed to commit section transfer tx: {}", e))
        })?;

        Ok(updated)
    }

    pub async fn list_paginated(
        pool: &PgPool,
        organization_id: Uuid,
        filter: EmployeeFilter<'_>,
        page: u32,
        page_size: u32,
    ) -> Result<(Vec<Employee>, u64)> {
        let page = if page == 0 { 1 } else { page };
        let limit = page_size.clamp(1, 100) as i64;
        let offset = ((page - 1) as i64) * limit;

        let mut builder: QueryBuilder<Postgres> = QueryBuilder::new(
            r#"
            SELECT id, organization_id, employee_code, attendance_device_user_id,
                   first_name, middle_name, last_name, email, mobile, section_id,
                   designation_id, attendance_rule_id, joining_date, leaving_date,
                   status, created_at, updated_at
            FROM employees
            WHERE organization_id =
            "#,
        );
        builder.push_bind(organization_id);

        if let Some(search) = filter.search {
            let pattern = format!("%{}%", search);
            builder.push(" AND (employee_code ILIKE ");
            builder.push_bind(pattern.clone());
            builder.push(" OR attendance_device_user_id ILIKE ");
            builder.push_bind(pattern.clone());
            builder.push(" OR first_name ILIKE ");
            builder.push_bind(pattern.clone());
            builder.push(" OR middle_name ILIKE ");
            builder.push_bind(pattern.clone());
            builder.push(" OR last_name ILIKE ");
            builder.push_bind(pattern.clone());
            builder.push(")");
        }

        if let Some(sec_id) = filter.section_id {
            builder.push(" AND section_id = ");
            builder.push_bind(sec_id);
        }

        if let Some(ref allowed_secs) = filter.allowed_section_ids {
            builder.push(" AND section_id = ANY(");
            builder.push_bind(allowed_secs);
            builder.push(")");
        }

        if let Some(des_id) = filter.designation_id {
            builder.push(" AND designation_id = ");
            builder.push_bind(des_id);
        }

        if let Some(st) = filter.status {
            builder.push(" AND status = ");
            builder.push_bind(st);
        }

        if let Some(rule_id) = filter.attendance_rule_id {
            builder.push(" AND attendance_rule_id = ");
            builder.push_bind(rule_id);
        }

        if let Some(from_date) = filter.joining_date_from {
            builder.push(" AND joining_date >= ");
            builder.push_bind(from_date);
        }

        if let Some(to_date) = filter.joining_date_to {
            builder.push(" AND joining_date <= ");
            builder.push_bind(to_date);
        }

        // Count query
        let count_sql = builder.sql().replace(
            "SELECT id, organization_id, employee_code, attendance_device_user_id,\n                   first_name, middle_name, last_name, email, mobile, section_id,\n                   designation_id, attendance_rule_id, joining_date, leaving_date,\n                   status, created_at, updated_at",
            "SELECT COUNT(*)"
        );

        // Fetch items query
        builder.push(" ORDER BY first_name ASC, last_name ASC LIMIT ");
        builder.push_bind(limit);
        builder.push(" OFFSET ");
        builder.push_bind(offset);

        let items = builder
            .build_query_as::<Employee>()
            .fetch_all(pool)
            .await
            .map_err(|e| AimsError::Database(format!("Failed to list employees: {}", e)))?;

        // Calculate total count using matching query
        let total_count = sqlx::query_scalar::<_, i64>(&count_sql)
            .fetch_one(pool)
            .await
            .unwrap_or(items.len() as i64) as u64;

        Ok((items, total_count))
    }
}
