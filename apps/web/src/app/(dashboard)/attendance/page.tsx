"use client";

import React, { useEffect, useState } from "react";
import { Search, Filter, Calendar, ChevronLeft, ChevronRight } from "lucide-react";
import { api } from "../../../lib/api";
import { DetailedAttendanceRow } from "../../../types/api";

export default function AttendancePage() {
  const [items, setItems] = useState<DetailedAttendanceRow[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [loading, setLoading] = useState(true);

  // Filters
  const [date, setDate] = useState("2026-08-22");
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState("");

  const loadAttendance = async () => {
    setLoading(true);
    try {
      const data = await api.getDailyAttendance({
        date,
        status: status || undefined,
        search: search || undefined,
        page,
        page_size: pageSize,
      });
      setItems(data.items);
      setTotal(data.total);
    } catch (err) {
      console.error("Failed to load attendance daily list:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAttendance();
  }, [date, status, search, page]);

  const totalPages = Math.ceil(total / pageSize) || 1;

  const renderStatusBadge = (st: string) => {
    switch (st) {
      case "PRESENT":
        return (
          <span className="px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-mono text-[10px] font-bold">
            🟢 PRESENT
          </span>
        );
      case "LATE":
        return (
          <span className="px-2 py-0.5 rounded bg-amber-500/10 text-amber-400 border border-amber-500/20 font-mono text-[10px] font-bold">
            🟡 LATE
          </span>
        );
      case "ABSENT":
        return (
          <span className="px-2 py-0.5 rounded bg-rose-500/10 text-rose-400 border border-rose-500/20 font-mono text-[10px] font-bold">
            🔴 ABSENT
          </span>
        );
      case "HALF_DAY":
        return (
          <span className="px-2 py-0.5 rounded bg-purple-500/10 text-purple-400 border border-purple-500/20 font-mono text-[10px] font-bold">
            🟣 HALF DAY
          </span>
        );
      case "INCOMPLETE":
        return (
          <span className="px-2 py-0.5 rounded bg-sky-500/10 text-sky-400 border border-sky-500/20 font-mono text-[10px] font-bold">
            🔵 INCOMPLETE
          </span>
        );
      default:
        return (
          <span className="px-2 py-0.5 rounded bg-slate-500/10 text-slate-400 border border-slate-500/20 font-mono text-[10px] font-bold">
            {st}
          </span>
        );
    }
  };

  const formatTime = (ts: string | null) => {
    if (!ts) return "--:--";
    return new Date(ts).toLocaleTimeString("en-IN", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
  };

  const formatMinutes = (mins: number) => {
    const hrs = Math.floor(mins / 60);
    const m = mins % 60;
    return `${String(hrs).padStart(2, "0")}h ${String(m).padStart(2, "0")}m`;
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#1E293B]">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight">Daily Attendance Register</h1>
          <p className="text-xs text-slate-400">Detailed employee check-in/out records and duty durations</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-[#151D2A] border border-[#1E293B] px-3 py-1.5 rounded-lg text-xs text-slate-300">
            <Calendar className="h-4 w-4 text-indigo-400" />
            <input
              type="date"
              value={date}
              onChange={(e) => {
                setDate(e.target.value);
                setPage(1);
              }}
              className="bg-transparent text-slate-200 focus:outline-none font-mono font-medium"
            />
          </div>
        </div>
      </div>

      {/* Filter Controls */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-[#151D2A] border border-[#1E293B] p-4 rounded-xl">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search employee name or code..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg pl-9 pr-4 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500"
          />
        </div>

        <div className="flex items-center gap-3 w-full sm:w-auto">
          <div className="flex items-center gap-2 text-xs text-slate-400">
            <Filter className="h-4 w-4" />
            <span>Status:</span>
          </div>
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value);
              setPage(1);
            }}
            className="bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500"
          >
            <option value="">All Statuses</option>
            <option value="PRESENT">PRESENT</option>
            <option value="LATE">LATE</option>
            <option value="ABSENT">ABSENT</option>
            <option value="HALF_DAY">HALF DAY</option>
            <option value="INCOMPLETE">INCOMPLETE</option>
          </select>
        </div>
      </div>

      {/* Attendance Table */}
      <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl overflow-hidden shadow-lg">
        {loading ? (
          <div className="flex h-64 items-center justify-center text-slate-400 text-xs">
            <div className="flex items-center gap-2">
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
              <span>Fetching Attendance Daily Register...</span>
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#1E293B]/60 text-slate-400 uppercase font-semibold text-[10px]">
                <tr>
                  <th className="p-3">Employee</th>
                  <th className="p-3">Designation</th>
                  <th className="p-3">Section</th>
                  <th className="p-3 text-center">First IN</th>
                  <th className="p-3 text-center">Last OUT</th>
                  <th className="p-3 text-center">Duty Time</th>
                  <th className="p-3 text-center">Late (Grace)</th>
                  <th className="p-3 text-right">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1E293B] text-slate-200">
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="p-8 text-center text-slate-500">
                      No daily attendance facts match your filter criteria.
                    </td>
                  </tr>
                ) : (
                  items.map((row) => (
                    <tr key={row.id} className="hover:bg-[#1E293B]/30 transition-colors">
                      <td className="p-3">
                        <div className="font-semibold text-slate-100">{row.employee_name}</div>
                        <div className="text-[10px] font-mono text-indigo-400">{row.employee_code}</div>
                      </td>
                      <td className="p-3 text-slate-300">{row.designation_name}</td>
                      <td className="p-3 text-slate-400">{row.section_name}</td>
                      <td className="p-3 text-center font-mono font-medium text-slate-200">
                        {formatTime(row.first_in)}
                      </td>
                      <td className="p-3 text-center font-mono font-medium text-slate-200">
                        {formatTime(row.last_out)}
                      </td>
                      <td className="p-3 text-center font-mono text-emerald-400 font-semibold">
                        {formatMinutes(row.total_duty_minutes)}
                      </td>
                      <td className="p-3 text-center font-mono text-amber-400">
                        {row.late_minutes_beyond_grace > 0
                          ? `+${row.late_minutes_beyond_grace}m`
                          : "0m"}
                      </td>
                      <td className="p-3 text-right">{renderStatusBadge(row.status)}</td>
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
            Showing Page {page} of {totalPages} ({total} records total)
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
