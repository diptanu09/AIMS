"use client";

import React from "react";
import { FileText, Download, FileSpreadsheet, Calendar, Filter, ShieldCheck } from "lucide-react";

export default function ReportsPage() {
  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="pb-2 border-b border-[#1E293B]">
        <h1 className="text-2xl font-bold text-slate-100 tracking-tight">Official Report Engine</h1>
        <p className="text-xs text-slate-400">Generate auditable PDF and Excel reports directly from database records</p>
      </div>

      {/* Report Generator Control Card */}
      <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-6 space-y-5">
        <h3 className="font-semibold text-slate-100 text-sm border-b border-[#1E293B] pb-3">Report Filter & Export Parameters</h3>
        
        <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
          <div>
            <label className="block text-[11px] font-semibold text-slate-400 uppercase mb-1">Report Category</label>
            <select className="w-full bg-[#1E293B] border border-[#2A364F] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500">
              <option>Daily Attendance Register</option>
              <option>Section-wise Monthly Attendance</option>
              <option>Late Arrival & Grace Analysis</option>
              <option>Absence Summary & Leave Audit</option>
              <option>Incomplete Punch Exception Log</option>
            </select>
          </div>

          <div>
            <label className="block text-[11px] font-semibold text-slate-400 uppercase mb-1">Target Section</label>
            <select className="w-full bg-[#1E293B] border border-[#2A364F] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500">
              <option>All Sections (Organization-wide)</option>
              <option>SECTION A (Rajesh Sharma, BO)</option>
              <option>SECTION B (Anil Kumar, Sr. AO)</option>
              <option>SECTION C (Priya Nair, BO)</option>
              <option>SECTION D (M. P. Singh, BO)</option>
            </select>
          </div>

          <div>
            <label className="block text-[11px] font-semibold text-slate-400 uppercase mb-1">Date Period</label>
            <input
              type="date"
              defaultValue="2026-08-20"
              className="w-full bg-[#1E293B] border border-[#2A364F] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div>
            <label className="block text-[11px] font-semibold text-slate-400 uppercase mb-1">Export Format</label>
            <select className="w-full bg-[#1E293B] border border-[#2A364F] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500">
              <option>Official Signed PDF (.pdf)</option>
              <option>Excel Workbook (.xlsx)</option>
              <option>Comma-Separated Values (.csv)</option>
            </select>
          </div>
        </div>

        <div className="flex items-center justify-between pt-3 border-t border-[#1E293B]">
          <div className="flex items-center gap-2 text-slate-400 text-xs">
            <ShieldCheck className="h-4 w-4 text-emerald-400" />
            <span>Reports embed digital audit hash header and officer sign-off blocks.</span>
          </div>

          <button className="bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold px-5 py-2.5 rounded-lg shadow-sm transition-colors flex items-center gap-2">
            <Download className="h-4 w-4" />
            <span>Generate & Download</span>
          </button>
        </div>
      </div>

      {/* Preset Report Templates Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-4 space-y-3">
          <div className="flex items-center gap-3">
            <div className="h-9 w-9 rounded-lg bg-rose-500/10 text-rose-400 flex items-center justify-center">
              <FileText className="h-5 w-5" />
            </div>
            <div>
              <h4 className="font-semibold text-xs text-slate-200">Daily Attendance PDF</h4>
              <p className="text-[10px] text-slate-400">Complete daily breakdown by section</p>
            </div>
          </div>
          <button className="w-full text-center py-2 rounded-lg bg-[#1E293B] hover:bg-slate-700 text-xs font-medium text-slate-300 transition-colors">
            Download PDF
          </button>
        </div>

        <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-4 space-y-3">
          <div className="flex items-center gap-3">
            <div className="h-9 w-9 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <FileSpreadsheet className="h-5 w-5" />
            </div>
            <div>
              <h4 className="font-semibold text-xs text-slate-200">Monthly Attendance Excel</h4>
              <p className="text-[10px] text-slate-400">Grid matrix of all 31 days per employee</p>
            </div>
          </div>
          <button className="w-full text-center py-2 rounded-lg bg-[#1E293B] hover:bg-slate-700 text-xs font-medium text-slate-300 transition-colors">
            Download XLSX
          </button>
        </div>

        <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-4 space-y-3">
          <div className="flex items-center gap-3">
            <div className="h-9 w-9 rounded-lg bg-amber-500/10 text-amber-400 flex items-center justify-center">
              <FileText className="h-5 w-5" />
            </div>
            <div>
              <h4 className="font-semibold text-xs text-slate-200">Late & Exception Analysis</h4>
              <p className="text-[10px] text-slate-400">Summary of late minutes and grace limits</p>
            </div>
          </div>
          <button className="w-full text-center py-2 rounded-lg bg-[#1E293B] hover:bg-slate-700 text-xs font-medium text-slate-300 transition-colors">
            Download PDF
          </button>
        </div>
      </div>
    </div>
  );
}
