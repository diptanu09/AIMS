"use client";

import React, { useEffect, useState } from "react";
import { AlertTriangle, Clock, UserX, AlertCircle, ChevronLeft, ChevronRight } from "lucide-react";
import { api } from "../../../lib/api";
import { AttendanceExceptionRow } from "../../../types/api";

export default function ExceptionsPage() {
  const [items, setItems] = useState<AttendanceExceptionRow[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [loading, setLoading] = useState(true);
  const [exceptionType, setExceptionType] = useState<string>("");

  const loadExceptions = async () => {
    setLoading(true);
    try {
      const data = await api.getExceptions({
        exception_type: exceptionType || undefined,
        page,
        page_size: pageSize,
      });
      setItems(data.items);
      setTotal(data.total);
    } catch (err) {
      console.error("Failed to load exceptions:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadExceptions();
  }, [exceptionType, page]);

  const totalPages = Math.ceil(total / pageSize) || 1;

  const renderSeverityBadge = (sev: string) => {
    if (sev === "HIGH") {
      return (
        <span className="px-2 py-0.5 rounded bg-rose-500/20 text-rose-400 border border-rose-500/30 font-mono text-[10px] font-bold">
          HIGH SEVERITY
        </span>
      );
    }
    return (
      <span className="px-2 py-0.5 rounded bg-amber-500/20 text-amber-400 border border-amber-500/30 font-mono text-[10px] font-bold">
        MEDIUM SEVERITY
      </span>
    );
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#1E293B]">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
            <AlertTriangle className="h-6 w-6 text-amber-400" />
            <span>Actionable Exception Center</span>
          </h1>
          <p className="text-xs text-slate-400">
            Real-time tracking of late arrivals, absences, and unclosed punch sessions
          </p>
        </div>
      </div>

      {/* Exception Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2">
        <button
          onClick={() => {
            setExceptionType("");
            setPage(1);
          }}
          className={`px-4 py-2 rounded-lg text-xs font-semibold transition-colors shrink-0 ${
            exceptionType === ""
              ? "bg-indigo-600 text-white shadow-lg shadow-indigo-600/30"
              : "bg-[#151D2A] border border-[#1E293B] text-slate-400 hover:text-slate-200"
          }`}
        >
          All Exceptions ({total})
        </button>

        <button
          onClick={() => {
            setExceptionType("LATE");
            setPage(1);
          }}
          className={`px-4 py-2 rounded-lg text-xs font-semibold flex items-center gap-2 transition-colors shrink-0 ${
            exceptionType === "LATE"
              ? "bg-amber-600 text-white shadow-lg shadow-amber-600/30"
              : "bg-[#151D2A] border border-[#1E293B] text-amber-400 hover:bg-[#1E293B]"
          }`}
        >
          <Clock className="h-3.5 w-3.5" />
          <span>Late Arrivals</span>
        </button>

        <button
          onClick={() => {
            setExceptionType("ABSENT");
            setPage(1);
          }}
          className={`px-4 py-2 rounded-lg text-xs font-semibold flex items-center gap-2 transition-colors shrink-0 ${
            exceptionType === "ABSENT"
              ? "bg-rose-600 text-white shadow-lg shadow-rose-600/30"
              : "bg-[#151D2A] border border-[#1E293B] text-rose-400 hover:bg-[#1E293B]"
          }`}
        >
          <UserX className="h-3.5 w-3.5" />
          <span>Absences</span>
        </button>

        <button
          onClick={() => {
            setExceptionType("INCOMPLETE");
            setPage(1);
          }}
          className={`px-4 py-2 rounded-lg text-xs font-semibold flex items-center gap-2 transition-colors shrink-0 ${
            exceptionType === "INCOMPLETE"
              ? "bg-sky-600 text-white shadow-lg shadow-sky-600/30"
              : "bg-[#151D2A] border border-[#1E293B] text-sky-400 hover:bg-[#1E293B]"
          }`}
        >
          <AlertCircle className="h-3.5 w-3.5" />
          <span>Incomplete Punches</span>
        </button>
      </div>

      {/* Exception Table */}
      <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl overflow-hidden shadow-lg">
        {loading ? (
          <div className="flex h-64 items-center justify-center text-slate-400 text-xs">
            <div className="flex items-center gap-2">
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
              <span>Querying Exception Records...</span>
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#1E293B]/60 text-slate-400 uppercase font-semibold text-[10px]">
                <tr>
                  <th className="p-3">Date</th>
                  <th className="p-3">Employee</th>
                  <th className="p-3">Section</th>
                  <th className="p-3">Exception Type</th>
                  <th className="p-3 text-center">Late / Exit Shift</th>
                  <th className="p-3 text-center">Severity</th>
                  <th className="p-3 text-right">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1E293B] text-slate-200">
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="p-8 text-center text-slate-500">
                      No attendance exceptions found for selected category.
                    </td>
                  </tr>
                ) : (
                  items.map((row) => (
                    <tr key={row.id} className="hover:bg-[#1E293B]/30 transition-colors">
                      <td className="p-3 font-mono text-slate-300">{row.attendance_date}</td>
                      <td className="p-3">
                        <div className="font-semibold text-slate-100">{row.employee_name}</div>
                        <div className="text-[10px] font-mono text-indigo-400">{row.employee_code}</div>
                      </td>
                      <td className="p-3 text-slate-400">{row.section_name}</td>
                      <td className="p-3 font-semibold text-amber-400">{row.exception_type}</td>
                      <td className="p-3 text-center font-mono text-amber-300">
                        {row.late_minutes > 0 ? `+${row.late_minutes}m late` : "--"}
                      </td>
                      <td className="p-3 text-center">{renderSeverityBadge(row.severity)}</td>
                      <td className="p-3 text-right font-mono font-bold text-slate-300">{row.status}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination Bar */}
        <div className="flex items-center justify-between p-4 border-t border-[#1E293B] bg-[#151D2A]">
          <span className="text-xs text-slate-400 font-mono">
            Page {page} of {totalPages} ({total} exception records)
          </span>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1}
              className="p-1.5 rounded-lg bg-[#0B0F17] border border-[#1E293B] text-slate-300 disabled:opacity-30 hover:bg-[#1E293B] transition-colors"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages}
              className="p-1.5 rounded-lg bg-[#0B0F17] border border-[#1E293B] text-slate-300 disabled:opacity-30 hover:bg-[#1E293B] transition-colors"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
