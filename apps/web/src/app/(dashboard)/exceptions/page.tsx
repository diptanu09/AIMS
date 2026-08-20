"use client";

import React, { useState } from "react";
import { AlertTriangle, Clock, UserX, AlertCircle, Search, Filter } from "lucide-react";

export default function ExceptionsPage() {
  const [activeFilter, setActiveFilter] = useState<"all" | "late" | "absent" | "incomplete">("late");

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="pb-2 border-b border-[#1E293B]">
        <h1 className="text-2xl font-bold text-slate-100 tracking-tight">Attendance Exception Center</h1>
        <p className="text-xs text-slate-400">Operational management of late arrivals, absences, and missing punches</p>
      </div>

      {/* Filter Tabs Header */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <button
          onClick={() => setActiveFilter("late")}
          className={`p-4 rounded-xl border text-left transition-all ${
            activeFilter === "late"
              ? "bg-amber-500/10 border-amber-500 text-amber-400"
              : "bg-[#151D2A] border-[#1E293B] text-slate-400 hover:border-slate-700"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase">Late Arrivals</span>
            <Clock className="h-4 w-4" />
          </div>
          <p className="text-2xl font-bold font-mono mt-2">19</p>
        </button>

        <button
          onClick={() => setActiveFilter("absent")}
          className={`p-4 rounded-xl border text-left transition-all ${
            activeFilter === "absent"
              ? "bg-rose-500/10 border-rose-500 text-rose-400"
              : "bg-[#151D2A] border-[#1E293B] text-slate-400 hover:border-slate-700"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase">Absences</span>
            <UserX className="h-4 w-4" />
          </div>
          <p className="text-2xl font-bold font-mono mt-2">16</p>
        </button>

        <button
          onClick={() => setActiveFilter("incomplete")}
          className={`p-4 rounded-xl border text-left transition-all ${
            activeFilter === "incomplete"
              ? "bg-sky-500/10 border-sky-500 text-sky-400"
              : "bg-[#151D2A] border-[#1E293B] text-slate-400 hover:border-slate-700"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase">Incomplete</span>
            <AlertCircle className="h-4 w-4" />
          </div>
          <p className="text-2xl font-bold font-mono mt-2">7</p>
        </button>

        <button
          onClick={() => setActiveFilter("all")}
          className={`p-4 rounded-xl border text-left transition-all ${
            activeFilter === "all"
              ? "bg-indigo-500/10 border-indigo-500 text-indigo-400"
              : "bg-[#151D2A] border-[#1E293B] text-slate-400 hover:border-slate-700"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase">Total Exceptions</span>
            <AlertTriangle className="h-4 w-4" />
          </div>
          <p className="text-2xl font-bold font-mono mt-2">42</p>
        </button>
      </div>

      {/* Exception Table Container */}
      <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-5 space-y-4">
        {/* Search Bar */}
        <div className="flex items-center justify-between gap-4">
          <div className="relative flex-1 max-w-sm">
            <Search className="h-4 w-4 absolute left-3 top-2.5 text-slate-500" />
            <input
              type="text"
              placeholder="Search employee code, name or section..."
              className="w-full bg-[#1E293B] border border-[#2A364F] rounded-lg pl-9 pr-4 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500"
            />
          </div>
          <button className="flex items-center gap-2 bg-[#1E293B] border border-[#2A364F] px-3 py-2 rounded-lg text-xs font-medium text-slate-300">
            <Filter className="h-3.5 w-3.5" />
            <span>Filter Section</span>
          </button>
        </div>

        {/* Records Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#1E293B]/50 text-slate-400 uppercase font-semibold text-[10px]">
              <tr>
                <th className="p-3">Employee Code</th>
                <th className="p-3">Name</th>
                <th className="p-3">Section</th>
                <th className="p-3">First IN</th>
                <th className="p-3">Expected IN</th>
                <th className="p-3">Variance / Late</th>
                <th className="p-3">Status</th>
                <th className="p-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1E293B] text-slate-200 font-mono">
              <tr className="hover:bg-[#1E293B]/30 transition-colors">
                <td className="p-3 font-semibold text-slate-100">EMP-1042</td>
                <td className="p-3 font-sans font-medium text-slate-300">Amitabh Banerjee</td>
                <td className="p-3 font-sans text-indigo-300">SECTION A</td>
                <td className="p-3 text-amber-400">09:54:12</td>
                <td className="p-3 text-slate-400">09:30:00</td>
                <td className="p-3 text-amber-400 font-semibold">+24 min</td>
                <td className="p-3">
                  <span className="px-2 py-0.5 rounded bg-amber-500/20 text-amber-400 font-sans text-[10px] font-semibold">
                    LATE
                  </span>
                </td>
                <td className="p-3 text-right font-sans">
                  <button className="text-indigo-400 hover:text-indigo-300 text-xs font-medium">
                    Request Correction
                  </button>
                </td>
              </tr>

              <tr className="hover:bg-[#1E293B]/30 transition-colors">
                <td className="p-3 font-semibold text-slate-100">EMP-1089</td>
                <td className="p-3 font-sans font-medium text-slate-300">Sunita Sharma</td>
                <td className="p-3 font-sans text-indigo-300">SECTION B</td>
                <td className="p-3 text-amber-400">10:02:45</td>
                <td className="p-3 text-slate-400">09:30:00</td>
                <td className="p-3 text-amber-400 font-semibold">+32 min</td>
                <td className="p-3">
                  <span className="px-2 py-0.5 rounded bg-amber-500/20 text-amber-400 font-sans text-[10px] font-semibold">
                    LATE
                  </span>
                </td>
                <td className="p-3 text-right font-sans">
                  <button className="text-indigo-400 hover:text-indigo-300 text-xs font-medium">
                    Request Correction
                  </button>
                </td>
              </tr>

              <tr className="hover:bg-[#1E293B]/30 transition-colors">
                <td className="p-3 font-semibold text-slate-100">EMP-1102</td>
                <td className="p-3 font-sans font-medium text-slate-300">Rohan Kulkarni</td>
                <td className="p-3 font-sans text-indigo-300">SECTION C</td>
                <td className="p-3 text-sky-400">09:28:10</td>
                <td className="p-3 text-slate-400">09:30:00</td>
                <td className="p-3 text-sky-400 font-semibold">MISSING OUT</td>
                <td className="p-3">
                  <span className="px-2 py-0.5 rounded bg-sky-500/20 text-sky-400 font-sans text-[10px] font-semibold">
                    INCOMPLETE
                  </span>
                </td>
                <td className="p-3 text-right font-sans">
                  <button className="text-indigo-400 hover:text-indigo-300 text-xs font-medium">
                    Add OUT Punch
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
