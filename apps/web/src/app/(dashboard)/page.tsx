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
  TrendingUp,
  ShieldAlert,
  Building2,
  Activity,
  Layers,
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
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      {/* Top Controls Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-6 rounded-2xl bg-[#151D2A]/90 border border-slate-800/80 backdrop-blur-xl shadow-xl">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <h1 className="text-2xl font-extrabold text-white tracking-tight">
              Attendance Intelligence Matrix
            </h1>
            <span className="px-2.5 py-0.5 rounded-full bg-indigo-500/20 text-indigo-300 font-mono text-xs font-semibold border border-indigo-500/30">
              REALTIME
            </span>
          </div>
          <p className="text-xs text-slate-400">
            Daily punch aggregation, status classification & section-level intelligence
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-[#0B0F17] border border-slate-800 px-3.5 py-2 rounded-xl text-xs text-slate-200 shadow-inner">
            <Calendar className="h-4 w-4 text-indigo-400" />
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="bg-transparent text-slate-200 focus:outline-none font-mono font-semibold"
            />
          </div>
          <button
            onClick={handleReprocess}
            disabled={reprocessing}
            className="bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 disabled:opacity-50 text-white text-xs font-semibold px-4 py-2.5 rounded-xl shadow-lg shadow-indigo-600/20 transition-all flex items-center gap-2 active:scale-95"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${reprocessing ? "animate-spin" : ""}`} />
            <span>{reprocessing ? "Reprocessing..." : "Run Batch Reprocess"}</span>
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex h-72 items-center justify-center text-slate-400 text-xs bg-[#151D2A]/50 rounded-2xl border border-slate-800/80">
          <div className="flex flex-col items-center gap-3">
            <div className="h-8 w-8 animate-spin rounded-full border-3 border-indigo-500 border-t-transparent shadow-lg shadow-indigo-500/30" />
            <span className="font-mono text-slate-400">Aggregating Biometric Punch Facts...</span>
          </div>
        </div>
      ) : (
        <>
          {/* KPI Stat Cards Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
            {/* Total Staff */}
            <div className="group bg-[#151D2A] border border-slate-800/80 hover:border-slate-700 rounded-2xl p-5 transition-all duration-200 hover:-translate-y-1 shadow-lg">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">Total Staff</span>
                <div className="p-2 rounded-xl bg-slate-800/80 text-slate-300">
                  <Users className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-4">
                <span className="text-3xl font-extrabold font-mono text-white tracking-tight">
                  {summary?.total_employees ?? 0}
                </span>
                <p className="text-[11px] text-slate-400 mt-1 font-medium">Active registered staff</p>
              </div>
            </div>

            {/* Present */}
            <div className="group bg-[#151D2A] border border-slate-800/80 hover:border-emerald-500/50 rounded-2xl p-5 transition-all duration-200 hover:-translate-y-1 shadow-lg relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-1 bg-emerald-500" />
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-emerald-400 uppercase tracking-wider">Present</span>
                <div className="p-2 rounded-xl bg-emerald-500/10 text-emerald-400">
                  <CheckCircle2 className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-4">
                <span className="text-3xl font-extrabold font-mono text-emerald-400 tracking-tight">
                  {summary?.present ?? 0}
                </span>
                <p className="text-[11px] text-emerald-500/80 mt-1 font-medium">On-time duty entries</p>
              </div>
            </div>

            {/* Late Arrivals */}
            <div className="group bg-[#151D2A] border border-slate-800/80 hover:border-amber-500/50 rounded-2xl p-5 transition-all duration-200 hover:-translate-y-1 shadow-lg relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-1 bg-amber-500" />
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-amber-400 uppercase tracking-wider">Late Arrivals</span>
                <div className="p-2 rounded-xl bg-amber-500/10 text-amber-400">
                  <Clock className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-4">
                <span className="text-3xl font-extrabold font-mono text-amber-400 tracking-tight">
                  {summary?.late ?? 0}
                </span>
                <p className="text-[11px] text-amber-500/80 mt-1 font-medium">Past grace period (15m)</p>
              </div>
            </div>

            {/* Absences */}
            <div className="group bg-[#151D2A] border border-slate-800/80 hover:border-rose-500/50 rounded-2xl p-5 transition-all duration-200 hover:-translate-y-1 shadow-lg relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-1 bg-rose-500" />
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-rose-400 uppercase tracking-wider">Absences</span>
                <div className="p-2 rounded-xl bg-rose-500/10 text-rose-400">
                  <UserX className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-4">
                <span className="text-3xl font-extrabold font-mono text-rose-400 tracking-tight">
                  {summary?.absent ?? 0}
                </span>
                <p className="text-[11px] text-rose-500/80 mt-1 font-medium">Zero punch activity</p>
              </div>
            </div>

            {/* Incomplete */}
            <div className="group bg-[#151D2A] border border-slate-800/80 hover:border-sky-500/50 rounded-2xl p-5 transition-all duration-200 hover:-translate-y-1 shadow-lg relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-1 bg-sky-500" />
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-sky-400 uppercase tracking-wider">Incomplete</span>
                <div className="p-2 rounded-xl bg-sky-500/10 text-sky-400">
                  <AlertCircle className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-4">
                <span className="text-3xl font-extrabold font-mono text-sky-400 tracking-tight">
                  {summary?.incomplete ?? 0}
                </span>
                <p className="text-[11px] text-sky-500/80 mt-1 font-medium">Missing OUT punch</p>
              </div>
            </div>
          </div>

          {/* Central Attendance Rate Bar */}
          <div className="bg-[#151D2A] border border-slate-800/80 rounded-2xl p-6 shadow-xl">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <TrendingUp className="h-4 w-4 text-emerald-400" />
                <span className="text-xs font-bold text-slate-200 uppercase tracking-wider">
                  Organization Attendance Performance Index
                </span>
              </div>
              <span className="font-mono font-extrabold text-lg text-emerald-400">
                {summary?.attendance_rate.toFixed(2)}%
              </span>
            </div>
            <div className="h-3.5 w-full bg-[#0B0F17] rounded-full overflow-hidden border border-slate-800 p-0.5">
              <div
                className="h-full bg-gradient-to-r from-emerald-500 via-indigo-500 to-purple-500 rounded-full transition-all duration-700 shadow-glow"
                style={{ width: `${summary?.attendance_rate || 0}%` }}
              />
            </div>
          </div>

          {/* Main Analytics Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Section Breakdown Table */}
            <div className="lg:col-span-2 bg-[#151D2A] border border-slate-800/80 rounded-2xl p-6 space-y-4 shadow-xl">
              <div className="flex items-center justify-between pb-4 border-b border-slate-800">
                <div className="flex items-center gap-2.5">
                  <Building2 className="h-4 w-4 text-purple-400" />
                  <div>
                    <h2 className="font-bold text-white text-sm">
                      Section Breakdown & Compliance Metrics
                    </h2>
                    <p className="text-xs text-slate-400">
                      Live section-level facts calculated from raw biometric logs
                    </p>
                  </div>
                </div>
                <Link
                  href="/sections"
                  className="text-xs font-semibold text-indigo-400 hover:text-indigo-300 flex items-center gap-1.5 transition-colors"
                >
                  View All Sections <ArrowRight className="h-3.5 w-3.5" />
                </Link>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-[#0B0F17]/80 text-slate-400 uppercase font-bold text-[10px] tracking-wider border-b border-slate-800">
                    <tr>
                      <th className="p-3.5 rounded-l-xl">Section Name</th>
                      <th className="p-3.5 text-center">Staff Count</th>
                      <th className="p-3.5 text-center">Present</th>
                      <th className="p-3.5 text-center">Late</th>
                      <th className="p-3.5 text-center">Absent</th>
                      <th className="p-3.5 text-right rounded-r-xl">Compliance</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60 text-slate-200 font-medium">
                    {sections.length === 0 ? (
                      <tr>
                        <td colSpan={6} className="p-6 text-center text-slate-500 font-mono">
                          No section activity recorded for selected audit date
                        </td>
                      </tr>
                    ) : (
                      sections.map((sec) => (
                        <tr
                          key={sec.section_id}
                          className="hover:bg-slate-800/40 transition-colors"
                        >
                          <td className="p-3.5 font-semibold text-indigo-300 flex items-center gap-2">
                            <span className="h-2 w-2 rounded-full bg-indigo-500" />
                            {sec.section_name}
                          </td>
                          <td className="p-3.5 text-center font-mono text-slate-300">{sec.total}</td>
                          <td className="p-3.5 text-center font-mono text-emerald-400 font-semibold">
                            {sec.present}
                          </td>
                          <td className="p-3.5 text-center font-mono text-amber-400 font-semibold">
                            {sec.late}
                          </td>
                          <td className="p-3.5 text-center font-mono text-rose-400 font-semibold">
                            {sec.absent}
                          </td>
                          <td className="p-3.5 text-right font-mono font-bold text-emerald-400">
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
            <div className="bg-[#151D2A] border border-slate-800/80 rounded-2xl p-6 space-y-5 flex flex-col justify-between shadow-xl">
              <div>
                <div className="flex items-center justify-between pb-4 border-b border-slate-800">
                  <div className="flex items-center gap-2">
                    <ShieldAlert className="h-4 w-4 text-amber-400" />
                    <h2 className="font-bold text-white text-sm">
                      Actionable Exceptions
                    </h2>
                  </div>
                  <span className="px-2.5 py-0.5 rounded-full bg-rose-500/20 text-rose-400 font-mono text-xs font-bold border border-rose-500/30">
                    {(summary?.late || 0) + (summary?.absent || 0) + (summary?.incomplete || 0)} Anomalies
                  </span>
                </div>

                <div className="mt-4 space-y-3">
                  <Link
                    href="/exceptions?type=LATE"
                    className="flex items-center justify-between p-3.5 rounded-xl bg-slate-900/60 hover:bg-slate-800/80 transition-all border border-amber-500/30 group"
                  >
                    <div className="flex items-center gap-3">
                      <span className="relative flex h-2.5 w-2.5">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75" />
                        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-amber-500" />
                      </span>
                      <div>
                        <p className="text-xs font-semibold text-slate-100 group-hover:text-amber-300 transition-colors">
                          Late Arrivals
                        </p>
                        <p className="text-[10px] text-slate-400">Arrived after 15m grace period</p>
                      </div>
                    </div>
                    <span className="font-mono text-sm font-bold text-amber-400">
                      {summary?.late ?? 0}
                    </span>
                  </Link>

                  <Link
                    href="/exceptions?type=ABSENT"
                    className="flex items-center justify-between p-3.5 rounded-xl bg-slate-900/60 hover:bg-slate-800/80 transition-all border border-rose-500/30 group"
                  >
                    <div className="flex items-center gap-3">
                      <span className="relative flex h-2.5 w-2.5">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75" />
                        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-rose-500" />
                      </span>
                      <div>
                        <p className="text-xs font-semibold text-slate-100 group-hover:text-rose-300 transition-colors">
                          Unexcused Absences
                        </p>
                        <p className="text-[10px] text-slate-400">Zero biometric log entries</p>
                      </div>
                    </div>
                    <span className="font-mono text-sm font-bold text-rose-400">
                      {summary?.absent ?? 0}
                    </span>
                  </Link>

                  <Link
                    href="/exceptions?type=INCOMPLETE"
                    className="flex items-center justify-between p-3.5 rounded-xl bg-slate-900/60 hover:bg-slate-800/80 transition-all border border-sky-500/30 group"
                  >
                    <div className="flex items-center gap-3">
                      <span className="relative flex h-2.5 w-2.5">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-sky-400 opacity-75" />
                        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-sky-500" />
                      </span>
                      <div>
                        <p className="text-xs font-semibold text-slate-100 group-hover:text-sky-300 transition-colors">
                          Unclosed Shifts
                        </p>
                        <p className="text-[10px] text-slate-400">Missing exit punch</p>
                      </div>
                    </div>
                    <span className="font-mono text-sm font-bold text-sky-400">
                      {summary?.incomplete ?? 0}
                    </span>
                  </Link>
                </div>
              </div>

              <Link
                href="/exceptions"
                className="w-full text-center py-3 rounded-xl bg-gradient-to-r from-indigo-600/30 to-purple-600/30 hover:from-indigo-600/40 hover:to-purple-600/40 text-indigo-200 border border-indigo-500/40 text-xs font-semibold transition-all block shadow-lg active:scale-95"
              >
                Open Exception Resolution Center
              </Link>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
