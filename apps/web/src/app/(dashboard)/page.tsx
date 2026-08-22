"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  Users,
  Clock,
  UserX,
  AlertCircle,
  CheckCircle2,
  Calendar,
  ArrowRight,
  RefreshCw,
} from "lucide-react";
import { api } from "../../lib/api";
import { DashboardSummary, SectionSummary } from "../../types/api";

export default function DashboardOverview() {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [sections, setSections] = useState<SectionSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [reprocessing, setReprocessing] = useState(false);
  const [selectedDate, setSelectedDate] = useState("2026-08-22");

  const loadDashboard = async (dateStr: string) => {
    setLoading(true);
    try {
      const [sum, secs] = await Promise.all([
        api.getDashboardSummary(dateStr),
        api.getSectionSummaries(dateStr),
      ]);
      setSummary(sum);
      setSections(secs);
    } catch (err) {
      console.error("Failed to load dashboard data:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDashboard(selectedDate);
  }, [selectedDate]);

  const handleReprocess = async () => {
    setReprocessing(true);
    try {
      await api.getDashboardSummary(selectedDate);
      await loadDashboard(selectedDate);
    } catch (err) {
      console.error("Reprocess error:", err);
    } finally {
      setReprocessing(false);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#1E293B]">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight">
            Attendance Intelligence Overview
          </h1>
          <p className="text-xs text-slate-400">
            Daily punch aggregation, status classification & section metrics
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-[#151D2A] border border-[#1E293B] px-3 py-1.5 rounded-lg text-xs text-slate-300">
            <Calendar className="h-4 w-4 text-indigo-400" />
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="bg-transparent text-slate-200 focus:outline-none font-mono font-medium"
            />
          </div>
          <button
            onClick={handleReprocess}
            disabled={reprocessing}
            className="bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white text-xs font-semibold px-4 py-2 rounded-lg shadow-sm transition-colors flex items-center gap-2"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${reprocessing ? "animate-spin" : ""}`} />
            <span>{reprocessing ? "Reprocessing..." : "Run Batch Reprocess"}</span>
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex h-64 items-center justify-center text-slate-400 text-xs">
          <div className="flex items-center gap-2">
            <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
            <span>Loading Attendance Facts...</span>
          </div>
        </div>
      ) : (
        <>
          {/* KPI Cards Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
            {/* Total Employees */}
            <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-400 uppercase">Total Staff</span>
                <Users className="h-4 w-4 text-slate-400" />
              </div>
              <div className="mt-3">
                <span className="text-2xl font-bold font-mono text-slate-100">
                  {summary?.total_employees ?? 0}
                </span>
                <p className="text-[11px] text-slate-400 mt-1">Active employee records</p>
              </div>
            </div>

            {/* Present */}
            <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between border-l-4 border-l-emerald-500">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-emerald-400 uppercase">Present</span>
                <CheckCircle2 className="h-4 w-4 text-emerald-400" />
              </div>
              <div className="mt-3">
                <span className="text-2xl font-bold font-mono text-emerald-400">
                  {summary?.present ?? 0}
                </span>
                <p className="text-[11px] text-emerald-500/80 mt-1">On-time duty entries</p>
              </div>
            </div>

            {/* Late */}
            <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between border-l-4 border-l-amber-500">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-amber-400 uppercase">Late Arrivals</span>
                <Clock className="h-4 w-4 text-amber-400" />
              </div>
              <div className="mt-3">
                <span className="text-2xl font-bold font-mono text-amber-400">
                  {summary?.late ?? 0}
                </span>
                <p className="text-[11px] text-amber-500/80 mt-1">Beyond grace period (15m)</p>
              </div>
            </div>

            {/* Absent */}
            <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between border-l-4 border-l-rose-500">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-rose-400 uppercase">Absent</span>
                <UserX className="h-4 w-4 text-rose-400" />
              </div>
              <div className="mt-3">
                <span className="text-2xl font-bold font-mono text-rose-400">
                  {summary?.absent ?? 0}
                </span>
                <p className="text-[11px] text-rose-500/80 mt-1">Zero punch activity</p>
              </div>
            </div>

            {/* Incomplete / Exceptions */}
            <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between border-l-4 border-l-sky-500">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-sky-400 uppercase">Incomplete</span>
                <AlertCircle className="h-4 w-4 text-sky-400" />
              </div>
              <div className="mt-3">
                <span className="text-2xl font-bold font-mono text-sky-400">
                  {summary?.incomplete ?? 0}
                </span>
                <p className="text-[11px] text-sky-500/80 mt-1">Missing OUT punch</p>
              </div>
            </div>
          </div>

          {/* Overall Attendance Rate Progress Bar */}
          <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-5">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-semibold text-slate-300">
                Central Organization Attendance Rate
              </span>
              <span className="font-mono font-bold text-sm text-emerald-400">
                {summary?.attendance_rate.toFixed(2)}%
              </span>
            </div>
            <div className="h-3 w-full bg-[#0B0F17] rounded-full overflow-hidden border border-[#1E293B]">
              <div
                className="h-full bg-gradient-to-r from-emerald-500 to-indigo-500 rounded-full transition-all duration-500"
                style={{ width: `${summary?.attendance_rate || 0}%` }}
              />
            </div>
          </div>

          {/* Main Grid Section */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Section Breakdown Table */}
            <div className="lg:col-span-2 bg-[#151D2A] border border-[#1E293B] rounded-xl p-5 space-y-4">
              <div className="flex items-center justify-between pb-3 border-b border-[#1E293B]">
                <div>
                  <h2 className="font-semibold text-slate-100 text-sm">
                    Section Breakdown & Metrics
                  </h2>
                  <p className="text-xs text-slate-400">
                    Live Section aggregation facts from calculated attendance
                  </p>
                </div>
                <Link
                  href="/sections"
                  className="text-xs font-medium text-indigo-400 hover:text-indigo-300 flex items-center gap-1"
                >
                  View Sections <ArrowRight className="h-3 w-3" />
                </Link>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-[#1E293B]/50 text-slate-400 uppercase font-semibold text-[10px]">
                    <tr>
                      <th className="p-3">Section Name</th>
                      <th className="p-3 text-center">Staff Count</th>
                      <th className="p-3 text-center">Present</th>
                      <th className="p-3 text-center">Late</th>
                      <th className="p-3 text-center">Absent</th>
                      <th className="p-3 text-right">Attendance Rate</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#1E293B] text-slate-200">
                    {sections.length === 0 ? (
                      <tr>
                        <td colSpan={6} className="p-4 text-center text-slate-500">
                          No section records available for selected date
                        </td>
                      </tr>
                    ) : (
                      sections.map((sec) => (
                        <tr
                          key={sec.section_id}
                          className="hover:bg-[#1E293B]/30 transition-colors"
                        >
                          <td className="p-3 font-semibold text-indigo-300">
                            {sec.section_name}
                          </td>
                          <td className="p-3 text-center font-mono">{sec.total}</td>
                          <td className="p-3 text-center font-mono text-emerald-400">
                            {sec.present}
                          </td>
                          <td className="p-3 text-center font-mono text-amber-400">
                            {sec.late}
                          </td>
                          <td className="p-3 text-center font-mono text-rose-400">
                            {sec.absent}
                          </td>
                          <td className="p-3 text-right font-mono font-semibold text-emerald-400">
                            {sec.attendance_rate.toFixed(1)}%
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Actionable Exception Panel */}
            <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-5 space-y-4 flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-[#1E293B]">
                  <h2 className="font-semibold text-slate-100 text-sm">
                    Actionable Exception Center
                  </h2>
                  <span className="px-2 py-0.5 rounded bg-rose-500/20 text-rose-400 font-mono text-[11px]">
                    {(summary?.late || 0) + (summary?.absent || 0) + (summary?.incomplete || 0)}{" "}
                    Total
                  </span>
                </div>

                <div className="mt-4 space-y-3">
                  <Link
                    href="/exceptions?type=LATE"
                    className="flex items-center justify-between p-3 rounded-lg bg-[#1E293B]/50 hover:bg-[#1E293B] transition-colors border border-amber-500/20"
                  >
                    <div className="flex items-center gap-3">
                      <div className="h-2 w-2 rounded-full bg-amber-400" />
                      <div>
                        <p className="text-xs font-semibold text-slate-200">Late Arrivals</p>
                        <p className="text-[10px] text-slate-400">Punches after grace threshold</p>
                      </div>
                    </div>
                    <span className="font-mono text-xs font-bold text-amber-400">
                      {summary?.late ?? 0}
                    </span>
                  </Link>

                  <Link
                    href="/exceptions?type=ABSENT"
                    className="flex items-center justify-between p-3 rounded-lg bg-[#1E293B]/50 hover:bg-[#1E293B] transition-colors border border-rose-500/20"
                  >
                    <div className="flex items-center gap-3">
                      <div className="h-2 w-2 rounded-full bg-rose-400" />
                      <div>
                        <p className="text-xs font-semibold text-slate-200">Absences</p>
                        <p className="text-[10px] text-slate-400">Zero log entries</p>
                      </div>
                    </div>
                    <span className="font-mono text-xs font-bold text-rose-400">
                      {summary?.absent ?? 0}
                    </span>
                  </Link>

                  <Link
                    href="/exceptions?type=INCOMPLETE"
                    className="flex items-center justify-between p-3 rounded-lg bg-[#1E293B]/50 hover:bg-[#1E293B] transition-colors border border-sky-500/20"
                  >
                    <div className="flex items-center gap-3">
                      <div className="h-2 w-2 rounded-full bg-sky-400" />
                      <div>
                        <p className="text-xs font-semibold text-slate-200">
                          Incomplete Punches
                        </p>
                        <p className="text-[10px] text-slate-400">Missing exit logs</p>
                      </div>
                    </div>
                    <span className="font-mono text-xs font-bold text-sky-400">
                      {summary?.incomplete ?? 0}
                    </span>
                  </Link>
                </div>
              </div>

              <Link
                href="/exceptions"
                className="w-full text-center py-2.5 rounded-lg bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-300 border border-indigo-500/30 text-xs font-semibold transition-colors block"
              >
                Open Exception Center
              </Link>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
