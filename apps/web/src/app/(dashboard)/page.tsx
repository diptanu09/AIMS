import React from "react";
import { Users, Clock, UserX, AlertCircle, CheckCircle2, TrendingUp, Calendar, ArrowRight } from "lucide-react";
import Link from "next/link";

export default function DashboardOverview() {
  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#1E293B]">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight">Attendance Intelligence Overview</h1>
          <p className="text-xs text-slate-400">Daily punch aggregation, status classification & section metrics</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-[#151D2A] border border-[#1E293B] px-3 py-1.5 rounded-lg text-xs text-slate-300">
            <Calendar className="h-4 w-4 text-indigo-400" />
            <span className="font-mono font-medium">20 Aug 2026</span>
          </div>
          <button className="bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold px-4 py-2 rounded-lg shadow-sm transition-colors">
            Run Batch Reprocess
          </button>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {/* Total Employees */}
        <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase">Total Staff</span>
            <Users className="h-4 w-4 text-slate-400" />
          </div>
          <div className="mt-3">
            <span className="text-2xl font-bold font-mono text-slate-100">286</span>
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
            <span className="text-2xl font-bold font-mono text-emerald-400">251</span>
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
            <span className="text-2xl font-bold font-mono text-amber-400">19</span>
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
            <span className="text-2xl font-bold font-mono text-rose-400">16</span>
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
            <span className="text-2xl font-bold font-mono text-sky-400">7</span>
            <p className="text-[11px] text-sky-500/80 mt-1">Missing OUT punch</p>
          </div>
        </div>
      </div>

      {/* Main Grid Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Section Intelligence Table (2 Cols) */}
        <div className="lg:col-span-2 bg-[#151D2A] border border-[#1E293B] rounded-xl p-5 space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-[#1E293B]">
            <div>
              <h2 className="font-semibold text-slate-100 text-sm">Section Breakdown & Hierarchy</h2>
              <p className="text-xs text-slate-400">BO / AAO supervisory scope & section metrics</p>
            </div>
            <Link href="/sections" className="text-xs font-medium text-indigo-400 hover:text-indigo-300 flex items-center gap-1">
              View All <ArrowRight className="h-3 w-3" />
            </Link>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#1E293B]/50 text-slate-400 uppercase font-semibold text-[10px]">
                <tr>
                  <th className="p-3">Section</th>
                  <th className="p-3">Branch Officer (BO)</th>
                  <th className="p-3">AAO Officer</th>
                  <th className="p-3 text-center">Staff</th>
                  <th className="p-3 text-center">Present</th>
                  <th className="p-3 text-center">Late</th>
                  <th className="p-3 text-right">Rate</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1E293B] text-slate-200">
                <tr className="hover:bg-[#1E293B]/30 transition-colors">
                  <td className="p-3 font-semibold text-indigo-300">SECTION A</td>
                  <td className="p-3 text-slate-300">Rajesh Sharma (BO)</td>
                  <td className="p-3 text-slate-400">V. K. Mehta</td>
                  <td className="p-3 text-center font-mono">34</td>
                  <td className="p-3 text-center font-mono text-emerald-400">30</td>
                  <td className="p-3 text-center font-mono text-amber-400">2</td>
                  <td className="p-3 text-right font-mono font-semibold text-emerald-400">94.1%</td>
                </tr>
                <tr className="hover:bg-[#1E293B]/30 transition-colors">
                  <td className="p-3 font-semibold text-indigo-300">SECTION B</td>
                  <td className="p-3 text-slate-300">Anil Kumar (Sr. AO)</td>
                  <td className="p-3 text-slate-400">Suresh Verma</td>
                  <td className="p-3 text-center font-mono">42</td>
                  <td className="p-3 text-center font-mono text-emerald-400">37</td>
                  <td className="p-3 text-center font-mono text-amber-400">4</td>
                  <td className="p-3 text-right font-mono font-semibold text-emerald-400">88.1%</td>
                </tr>
                <tr className="hover:bg-[#1E293B]/30 transition-colors">
                  <td className="p-3 font-semibold text-indigo-300">SECTION C</td>
                  <td className="p-3 text-slate-300">Priya Nair (BO)</td>
                  <td className="p-3 text-slate-400">Deepak Gupta</td>
                  <td className="p-3 text-center font-mono">29</td>
                  <td className="p-3 text-center font-mono text-emerald-400">24</td>
                  <td className="p-3 text-center font-mono text-amber-400">3</td>
                  <td className="p-3 text-right font-mono font-semibold text-amber-400">82.7%</td>
                </tr>
                <tr className="hover:bg-[#1E293B]/30 transition-colors">
                  <td className="p-3 font-semibold text-indigo-300">SECTION D</td>
                  <td className="p-3 text-slate-300">M. P. Singh (BO)</td>
                  <td className="p-3 text-slate-400">R. C. Das</td>
                  <td className="p-3 text-center font-mono">38</td>
                  <td className="p-3 text-center font-mono text-emerald-400">35</td>
                  <td className="p-3 text-center font-mono text-amber-400">1</td>
                  <td className="p-3 text-right font-mono font-semibold text-emerald-400">92.1%</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        {/* Actionable Exception Panel (1 Col) */}
        <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-5 space-y-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-3 border-b border-[#1E293B]">
              <h2 className="font-semibold text-slate-100 text-sm">Actionable Exceptions</h2>
              <span className="px-2 py-0.5 rounded bg-rose-500/20 text-rose-400 font-mono text-[11px]">42 Pending</span>
            </div>

            <div className="mt-4 space-y-3">
              <Link href="/exceptions?type=late" className="flex items-center justify-between p-3 rounded-lg bg-[#1E293B]/50 hover:bg-[#1E293B] transition-colors border border-amber-500/20">
                <div className="flex items-center gap-3">
                  <div className="h-2 w-2 rounded-full bg-amber-400"></div>
                  <div>
                    <p className="text-xs font-semibold text-slate-200">Late Arrivals</p>
                    <p className="text-[10px] text-slate-400">Punches after 09:45:00</p>
                  </div>
                </div>
                <span className="font-mono text-xs font-bold text-amber-400">19</span>
              </Link>

              <Link href="/exceptions?type=absent" className="flex items-center justify-between p-3 rounded-lg bg-[#1E293B]/50 hover:bg-[#1E293B] transition-colors border border-rose-500/20">
                <div className="flex items-center gap-3">
                  <div className="h-2 w-2 rounded-full bg-rose-400"></div>
                  <div>
                    <p className="text-xs font-semibold text-slate-200">Absences</p>
                    <p className="text-[10px] text-slate-400">Zero log entries</p>
                  </div>
                </div>
                <span className="font-mono text-xs font-bold text-rose-400">16</span>
              </Link>

              <Link href="/exceptions?type=incomplete" className="flex items-center justify-between p-3 rounded-lg bg-[#1E293B]/50 hover:bg-[#1E293B] transition-colors border border-sky-500/20">
                <div className="flex items-center gap-3">
                  <div className="h-2 w-2 rounded-full bg-sky-400"></div>
                  <div>
                    <p className="text-xs font-semibold text-slate-200">Incomplete Punches</p>
                    <p className="text-[10px] text-slate-400">Missing exit logs</p>
                  </div>
                </div>
                <span className="font-mono text-xs font-bold text-sky-400">7</span>
              </Link>
            </div>
          </div>

          <Link href="/exceptions" className="w-full text-center py-2.5 rounded-lg bg-[#1E293B] hover:bg-slate-700 text-xs font-semibold text-slate-200 transition-colors block">
            Open Exception Center
          </Link>
        </div>
      </div>
    </div>
  );
}
