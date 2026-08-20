"use client";

import React, { useState } from "react";
import { UploadCloud, FileSpreadsheet, CheckCircle2, AlertTriangle, AlertCircle, HelpCircle, ArrowRight } from "lucide-react";

export default function ImportPage() {
  const [fileUploaded, setFileUploaded] = useState(true);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="pb-2 border-b border-[#1E293B]">
        <h1 className="text-2xl font-bold text-slate-100 tracking-tight">Attendance File Importer</h1>
        <p className="text-xs text-slate-400">Upload CSV / Excel biometric machine log exports for staging & validation</p>
      </div>

      {/* Upload Box */}
      <div className="bg-[#151D2A] border-2 border-dashed border-[#2A364F] hover:border-indigo-500 rounded-xl p-8 text-center transition-colors cursor-pointer">
        <div className="h-12 w-12 rounded-full bg-indigo-600/10 text-indigo-400 flex items-center justify-center mx-auto mb-3">
          <UploadCloud className="h-6 w-6" />
        </div>
        <h3 className="text-sm font-semibold text-slate-200">Drop raw attendance CSV / XLSX file here</h3>
        <p className="text-xs text-slate-400 mt-1">Supports Aadhaar / Biometric machine standard format exports up to 50MB</p>
        <button className="mt-4 bg-[#1E293B] hover:bg-slate-700 text-slate-200 text-xs font-semibold px-4 py-2 rounded-lg transition-colors">
          Browse File
        </button>
      </div>

      {/* Staging Validation Preview */}
      {fileUploaded && (
        <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-6 space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#1E293B]">
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
                <FileSpreadsheet className="h-5 w-5" />
              </div>
              <div>
                <h3 className="font-semibold text-slate-100 text-sm">August_2026_Attendance.xlsx</h3>
                <p className="text-xs font-mono text-slate-400">File Hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855</p>
              </div>
            </div>
            <span className="px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-400 text-xs font-medium">
              Staging Validation Complete
            </span>
          </div>

          {/* Validation Metrics Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
            <div className="bg-[#1E293B]/50 p-3 rounded-lg border border-[#2A364F]">
              <span className="text-[11px] font-semibold text-slate-400 uppercase">Total Records</span>
              <p className="text-xl font-bold font-mono text-slate-100 mt-1">2,846</p>
            </div>

            <div className="bg-[#1E293B]/50 p-3 rounded-lg border border-emerald-500/20">
              <span className="text-[11px] font-semibold text-emerald-400 uppercase">Valid Records</span>
              <p className="text-xl font-bold font-mono text-emerald-400 mt-1">2,807</p>
            </div>

            <div className="bg-[#1E293B]/50 p-3 rounded-lg border border-amber-500/20">
              <span className="text-[11px] font-semibold text-amber-400 uppercase">Duplicates</span>
              <p className="text-xl font-bold font-mono text-amber-400 mt-1">18</p>
            </div>

            <div className="bg-[#1E293B]/50 p-3 rounded-lg border border-purple-500/20">
              <span className="text-[11px] font-semibold text-purple-400 uppercase">Unknown IDs</span>
              <p className="text-xl font-bold font-mono text-purple-400 mt-1">12</p>
            </div>

            <div className="bg-[#1E293B]/50 p-3 rounded-lg border border-rose-500/20">
              <span className="text-[11px] font-semibold text-rose-400 uppercase">Invalid</span>
              <p className="text-xl font-bold font-mono text-rose-400 mt-1">9</p>
            </div>
          </div>

          {/* Action Bar */}
          <div className="flex items-center justify-between pt-4 border-t border-[#1E293B]">
            <button className="text-xs font-semibold text-rose-400 hover:text-rose-300">
              View Detailed Issue Log (39 issues)
            </button>
            <div className="flex items-center gap-3">
              <button className="bg-[#1E293B] hover:bg-slate-700 text-slate-300 text-xs font-semibold px-4 py-2 rounded-lg transition-colors">
                Cancel
              </button>
              <button className="bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold px-5 py-2 rounded-lg shadow-sm transition-colors flex items-center gap-2">
                <span>Commit Import & Execute Engine</span>
                <ArrowRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
