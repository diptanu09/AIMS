import {
  ApiResponse,
  AttendanceCorrectionRow,
  AttendanceExceptionRow,
  AttendanceRule,
  AttendanceTrendRow,
  AuditLogRow,
  DashboardSummary,
  DetailedAttendanceRow,
  Employee,
  HolidayRow,
  LeaveRecordRow,
  PaginatedData,
  ReportDefinition,
  ReportRun,
  SectionHierarchy,
  SectionSummary,
  User,
} from "../types/api";

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000/api/v1";

async function request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
    credentials: "include", // Include HttpOnly cookies
  });

  if (!res.ok) {
    let errorMsg = `HTTP error ${res.status}`;
    try {
      const errBody = await res.json();
      if (errBody.message) errorMsg = errBody.message;
    } catch {}
    throw new Error(errorMsg);
  }

  const json: ApiResponse<T> = await res.json();
  return json.data;
}

export const api = {
  // Auth
  login: (credentials: { username: string; password_hash: string }) =>
    request<{ user: User }>("/auth/login", {
      method: "POST",
      body: JSON.stringify(credentials),
    }),

  logout: () =>
    request<{ success: boolean }>("/auth/logout", {
      method: "POST",
    }),

  getMe: () => request<User>("/auth/me"),

  // Dashboard APIs
  getDashboardSummary: (date?: string) =>
    request<DashboardSummary>(`/dashboard/summary${date ? `?date=${date}` : ""}`),

  getSectionSummaries: (date?: string) =>
    request<SectionSummary[]>(`/dashboard/sections${date ? `?date=${date}` : ""}`),

  getAttendanceTrends: (from?: string, to?: string, sectionId?: string) => {
    const params = new URLSearchParams();
    if (from) params.set("from", from);
    if (to) params.set("to", to);
    if (sectionId) params.set("section_id", sectionId);
    return request<AttendanceTrendRow[]>(`/dashboard/trends?${params.toString()}`);
  },

  // Attendance Queries
  getDailyAttendance: (params: {
    date?: string;
    start_date?: string;
    end_date?: string;
    section_id?: string;
    employee_id?: string;
    status?: string;
    search?: string;
    page?: number;
    page_size?: number;
  }) => {
    const query = new URLSearchParams();
    Object.entries(params).forEach(([key, val]) => {
      if (val !== undefined && val !== null && val !== "") {
        query.set(key, String(val));
      }
    });
    return request<PaginatedData<DetailedAttendanceRow>>(`/attendance/daily?${query.toString()}`);
  },

  // Exception Center
  getExceptions: (params: {
    date_from?: string;
    date_to?: string;
    section_id?: string;
    employee_id?: string;
    exception_type?: string;
    page?: number;
    page_size?: number;
  }) => {
    const query = new URLSearchParams();
    Object.entries(params).forEach(([key, val]) => {
      if (val !== undefined && val !== null && val !== "") {
        query.set(key, String(val));
      }
    });
    return request<PaginatedData<AttendanceExceptionRow>>(`/exceptions?${query.toString()}`);
  },

  // Section Hierarchy
  getSectionHierarchy: (sectionId: string) =>
    request<SectionHierarchy>(`/sections/${sectionId}/hierarchy`),

  // Reports
  getReportDefinitions: () => request<ReportDefinition[]>("/reports/definitions"),

  listReportRuns: () => request<ReportRun[]>("/reports/runs"),

  generateReport: (payload: {
    report_type: string;
    format: string;
    date_from: string;
    date_to: string;
    section_id?: string;
    employee_id?: string;
  }) =>
    request<ReportRun>("/reports/generate", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  getReportDownloadUrl: (runId: string) => `${API_BASE}/reports/runs/${runId}/download`,

  // Corrections Workflow
  listCorrections: (status?: string) =>
    request<AttendanceCorrectionRow[]>(`/corrections${status ? `?status=${status}` : ""}`),

  requestCorrection: (payload: {
    attendance_daily_id: string;
    corrected_first_in?: string;
    corrected_last_out?: string;
    corrected_status: string;
    reason: string;
  }) =>
    request<AttendanceCorrectionRow>("/corrections/request", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  approveCorrection: (id: string) =>
    request<AttendanceCorrectionRow>(`/corrections/${id}/approve`, {
      method: "POST",
    }),

  rejectCorrection: (id: string, reason: string) =>
    request<AttendanceCorrectionRow>(`/corrections/${id}/reject`, {
      method: "POST",
      body: JSON.stringify({ reason }),
    }),

  // Employee Master Administration
  listEmployees: (params?: { search?: string; section_id?: string; is_active?: boolean }) => {
    const query = new URLSearchParams();
    if (params?.search) query.set("search", params.search);
    if (params?.section_id) query.set("section_id", params.section_id);
    if (params?.is_active !== undefined) query.set("is_active", String(params.is_active));
    return request<PaginatedData<Employee>>(`/employees?${query.toString()}`);
  },

  createEmployee: (payload: {
    employee_code: string;
    attendance_device_user_id: string;
    first_name: string;
    last_name?: string;
    section_id: string;
    designation_id: string;
    attendance_rule_id: string;
  }) =>
    request<Employee>("/employees", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  activateEmployee: (id: string) =>
    request<Employee>(`/employees/${id}/activate`, { method: "POST" }),

  deactivateEmployee: (id: string) =>
    request<Employee>(`/employees/${id}/deactivate`, { method: "POST" }),

  transferEmployee: (id: string, new_section_id: string) =>
    request<Employee>(`/employees/${id}/transfer`, {
      method: "POST",
      body: JSON.stringify({ new_section_id }),
    }),

  // Shift Rules
  listRules: () => request<AttendanceRule[]>("/attendance-rules"),

  createRule: (payload: Partial<AttendanceRule>) =>
    request<AttendanceRule>("/attendance-rules", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  // Holidays
  listHolidays: () => request<HolidayRow[]>("/holidays"),

  createHoliday: (payload: {
    holiday_date: string;
    name: string;
    description?: string;
    is_optional?: boolean;
  }) =>
    request<HolidayRow>("/holidays", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  // Leave
  listLeave: () => request<LeaveRecordRow[]>("/leave"),

  submitLeave: (payload: {
    employee_id: string;
    leave_type: string;
    start_date: string;
    end_date: string;
    reason?: string;
  }) =>
    request<string>("/leave", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  // Audit Logs
  listAuditLogs: (limit = 50, offset = 0) =>
    request<AuditLogRow[]>(`/admin/audit?limit=${limit}&offset=${offset}`),
};
