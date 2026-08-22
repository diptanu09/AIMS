export interface ApiResponse<T> {
  success: boolean;
  data: T;
}

export interface PaginatedData<T> {
  items: T[];
  page: number;
  page_size: number;
  total: number;
}

export interface User {
  user_id: string;
  organization_id: string;
  username: string;
  roles: string[];
  permissions: string[];
  section_ids: string[];
}

export interface DashboardSummary {
  date: string;
  total_employees: number;
  present: number;
  late: number;
  absent: number;
  half_day: number;
  incomplete: number;
  early_exit: number;
  attendance_rate: number;
  average_duty_minutes: number;
}

export interface SectionSummary {
  section_id: string;
  section_name: string;
  total: number;
  present: number;
  late: number;
  absent: number;
  incomplete: number;
  attendance_rate: number;
}

export interface AttendanceTrendRow {
  date: string;
  present: number;
  absent: number;
  late: number;
  incomplete: number;
  attendance_rate: number;
  average_duty_minutes: number;
}

export interface DetailedAttendanceRow {
  id: string;
  organization_id: string;
  employee_id: string;
  employee_code: string;
  employee_name: string;
  designation_id: string;
  designation_name: string;
  section_id: string;
  section_name: string;
  attendance_date: string;
  first_in: string | null;
  last_out: string | null;
  total_duty_minutes: number;
  late_minutes: number;
  late_minutes_beyond_grace: number;
  early_exit_minutes: number;
  status: string;
}

export interface AttendanceExceptionRow {
  id: string;
  organization_id: string;
  employee_id: string;
  employee_code: string;
  employee_name: string;
  section_id: string;
  section_name: string;
  attendance_date: string;
  first_in: string | null;
  last_out: string | null;
  total_duty_minutes: number;
  late_minutes: number;
  early_exit_minutes: number;
  status: string;
  exception_type: string;
  severity: 'HIGH' | 'MEDIUM' | 'LOW';
}

export interface SectionHierarchy {
  section_id: string;
  section_code: string;
  section_name: string;
  parent_section_id: string | null;
  branch_officers: string[];
  assistant_accounts_officers: string[];
  total_employees: number;
}

export interface ReportDefinition {
  id: string;
  organization_id: string;
  code: string;
  name: string;
  description: string | null;
  category: string;
  active: boolean;
}

export interface ReportRun {
  id: string;
  organization_id: string;
  report_definition_id: string;
  generated_by: string;
  parameters: any;
  output_format: string;
  status: 'QUEUED' | 'PROCESSING' | 'COMPLETED' | 'FAILED';
  file_path: string | null;
  error_message: string | null;
  started_at: string | null;
  completed_at: string | null;
  created_at: string;
}

export interface AttendanceCorrectionRow {
  id: string;
  attendance_daily_id: string;
  employee_id: string;
  employee_code: string;
  employee_name: string;
  section_name: string;
  attendance_date: string;
  requested_by: string;
  requester_name: string;
  original_first_in: string | null;
  original_last_out: string | null;
  original_status: string;
  corrected_first_in: string | null;
  corrected_last_out: string | null;
  corrected_status: string;
  reason: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  approved_by: string | null;
  approver_name: string | null;
  approved_at: string | null;
  rejection_reason: string | null;
  created_at: string;
}

export interface HolidayRow {
  id: string;
  organization_id: string;
  holiday_date: string;
  name: string;
  description: string | null;
  is_optional: boolean;
  created_at: string;
}

export interface LeaveRecordRow {
  id: string;
  organization_id: string;
  employee_id: string;
  employee_code: string;
  employee_name: string;
  leave_type: string;
  start_date: string;
  end_date: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'CANCELLED';
  reason: string | null;
  requested_by: string;
  approved_by: string | null;
  approved_at: string | null;
  rejection_reason: string | null;
  created_at: string;
}

export interface AuditLogRow {
  id: string;
  organization_id: string | null;
  user_id: string | null;
  username: string | null;
  action: string;
  entity_name: string;
  entity_id: string | null;
  old_value: any;
  new_value: any;
  client_ip: string | null;
  user_agent: string | null;
  created_at: string;
}

export interface Employee {
  id: string;
  organization_id: string;
  employee_code: string;
  attendance_device_user_id: string;
  first_name: string;
  last_name: string | null;
  section_id: string;
  section_name?: string;
  designation_id: string;
  designation_name?: string;
  attendance_rule_id: string;
  is_active: boolean;
  created_at: string;
}

export interface AttendanceRule {
  id: string;
  organization_id: string;
  code: string;
  name: string;
  shift_start: string;
  shift_end: string;
  grace_period_minutes: number;
  half_day_minimum_minutes: number;
  full_day_minimum_minutes: number;
  early_exit_threshold_minutes: number;
  crosses_midnight: boolean;
}
