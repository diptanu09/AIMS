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
  ReconciliationDiscrepancy,
  ReconciliationSummary,
  InAppNotification,
  ScheduledReport,
  CandidateOfficer,
  SectionOfficerAssignment,
  UpdateSectionOfficersRequest,
} from "../types/api";

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "/api/v1";

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
      if (errBody.message) {
        errorMsg = errBody.message;
      } else if (errBody.error) {
        errorMsg = errBody.error;
      }
    } catch {
      try {
        const text = await res.text();
        if (text) errorMsg = text;
      } catch {}
    }
    throw new Error(errorMsg);
  }

  const json: ApiResponse<T> = await res.json();
  return json.data;
}

export const api = {
  login: (credentials: { username: string; password?: string; password_hash?: string }) =>
    request<{ user: User }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({
        username: credentials.username,
        password: credentials.password || credentials.password_hash || "",
      }),
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

  // Section Hierarchy & Officers
  getSectionHierarchy: (sectionId: string) =>
    request<SectionHierarchy>(`/sections/${sectionId}/hierarchy`),

  getSectionOfficers: (sectionId: string) =>
    request<SectionOfficerAssignment[]>(`/sections/${sectionId}/officers`),

  updateSectionOfficers: (sectionId: string, payload: UpdateSectionOfficersRequest) =>
    request<boolean>(`/sections/${sectionId}/officers`, {
      method: "PUT",
      body: JSON.stringify(payload),
    }),

  getCandidateOfficers: () =>
    request<CandidateOfficer[]>("/sections/candidate-officers"),

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
  listEmployees: (params?: { search?: string; section_id?: string; is_active?: boolean; page_size?: number }) => {
    const query = new URLSearchParams();
    if (params?.search) query.set("search", params.search);
    if (params?.section_id) query.set("section_id", params.section_id);
    if (params?.is_active !== undefined) query.set("is_active", String(params.is_active));
    if (params?.page_size) query.set("page_size", String(params.page_size));
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

  transferEmployee: (id: string, new_section_id: string, effective_date?: string, reason?: string) =>
    request<Employee>(`/employees/${id}/transfer`, {
      method: "POST",
      body: JSON.stringify({
        new_section_id,
        effective_date: effective_date || new Date().toISOString().split("T")[0],
        reason: reason || "Section update from web UI",
      }),
    }),

  // Sections List
  listSections: () =>
    request<Array<{ id: string; code: string; name: string }>>("/sections"),

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

  // Pilot Reconciliation
  getReconciliationSummary: () =>
    request<ReconciliationSummary>("/reconciliation/summary"),

  getReconciliationDiscrepancies: () =>
    request<ReconciliationDiscrepancy[]>("/reconciliation/discrepancies"),

  // Scheduled Reports
  listScheduledReports: () =>
    request<ScheduledReport[]>("/scheduled-reports"),

  createScheduledReport: (payload: {
    name: string;
    cron_expression: string;
    report_type: string;
    section_id?: string;
    recipients: string[];
  }) =>
    request<ScheduledReport>("/scheduled-reports", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  // Notifications
  listNotifications: () =>
    request<InAppNotification[]>("/notifications"),

  markNotificationRead: (id: string) =>
    request<void>(`/notifications/${id}/read`, { method: "POST" }),

  // Biometric CSV/XLSX Import
  uploadImportPreview: async (file: File) => {
    const formData = new FormData();
    formData.append("file", file);
    const res = await fetch(`${API_BASE}/imports/preview`, {
      method: "POST",
      body: formData,
      credentials: "include",
    });
    if (!res.ok) {
      throw new Error(`Import preview failed with status ${res.status}`);
    }
    const json = await res.json();
    return json.data;
  },

  commitImport: async (file: File) => {
    const formData = new FormData();
    formData.append("file", file);
    const res = await fetch(`${API_BASE}/imports/commit`, {
      method: "POST",
      body: formData,
      credentials: "include",
    });
    if (!res.ok) {
      throw new Error(`Import commit failed with status ${res.status}`);
    }
    const json = await res.json();
    return json.data;
  },
};
