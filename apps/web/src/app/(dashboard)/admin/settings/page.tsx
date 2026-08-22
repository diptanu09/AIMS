"use client";

import React, { useState } from "react";
import { Settings, Save, Building } from "lucide-react";

export default function SystemSettingsPage() {
  const [orgName, setOrgName] = useState("Comptroller and Auditor General of India");
  const [officeLocation, setOfficeLocation] = useState("Office of the Accountant General");
  const [timezone, setTimezone] = useState("Asia/Kolkata (IST +05:30)");
  const [reportFooter, setReportFooter] = useState("Confidential — CAG Internal Attendance Intelligence Document");

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    alert("System settings saved successfully.");
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      {/* Header */}
      <div className="pb-2 border-b border-[#1E293B]">
        <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
          <Settings className="h-6 w-6 text-indigo-400" />
          <span>System & Report Branding Settings</span>
        </h1>
        <p className="text-xs text-slate-400">
          Organization identity, report PDF headers, timezone standards & system branding
        </p>
      </div>

      <form onSubmit={handleSave} className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-6 space-y-4 shadow-lg">
        <div>
          <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
            Organization Formal Name
          </label>
          <input
            type="text"
            required
            value={orgName}
            onChange={(e) => setOrgName(e.target.value)}
            className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 focus:outline-none focus:border-indigo-500 font-semibold"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
            Office Location / Division
          </label>
          <input
            type="text"
            required
            value={officeLocation}
            onChange={(e) => setOfficeLocation(e.target.value)}
            className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 focus:outline-none focus:border-indigo-500"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
            System Timezone Standard
          </label>
          <input
            type="text"
            disabled
            value={timezone}
            className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-400 font-mono"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
            Official Report Footer Classification
          </label>
          <input
            type="text"
            required
            value={reportFooter}
            onChange={(e) => setReportFooter(e.target.value)}
            className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 focus:outline-none focus:border-indigo-500"
          />
        </div>

        <div className="pt-3 border-t border-[#1E293B] flex justify-end">
          <button
            type="submit"
            className="bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs px-5 py-2.5 rounded-lg transition-colors shadow-lg shadow-indigo-600/30 flex items-center gap-2"
          >
            <Save className="h-4 w-4" />
            <span>Save System Settings</span>
          </button>
        </div>
      </form>
    </div>
  );
}
