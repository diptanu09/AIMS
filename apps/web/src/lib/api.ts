import {
  ApiResponse,
  AttendanceExceptionRow,
  AttendanceTrendRow,
  DashboardSummary,
  DetailedAttendanceRow,
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
};
