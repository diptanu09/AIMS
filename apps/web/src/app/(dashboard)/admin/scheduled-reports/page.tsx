"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { ScheduledReport } from "@/types/api";

export default function ScheduledReportsPage() {
  const [schedules, setSchedules] = useState<ScheduledReport[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);

  const [name, setName] = useState("");
  const [cron, setCron] = useState("0 8 1 * *");
  const [reportType, setReportType] = useState("MONTHLY_SECTION_ATTENDANCE");
  const [recipients, setRecipients] = useState("bo.accounts@cag.gov.in");

  useEffect(() => {
    loadSchedules();
  }, []);

  async function loadSchedules() {
    try {
      const data = await api.listScheduledReports();
      setSchedules(data);
    } catch (err) {
      console.error("Failed to load scheduled reports", err);
    } finally {
      setIsLoading(false);
    }
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    try {
      const recipientList = recipients.split(",").map((r) => r.trim()).filter(Boolean);
      await api.createScheduledReport({
        name,
        cron_expression: cron,
        report_type: reportType,
        recipients: recipientList,
      });
      setShowModal(false);
      setName("");
      loadSchedules();
    } catch (err) {
      console.error("Failed to create scheduled report", err);
    }
  }

  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-100">
            Automated Scheduled Reports & Notifications
          </h1>
          <p className="text-sm text-slate-400">
            Configure automated cron reporting schedules and email/in-app alert triggers.
          </p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="rounded-lg bg-indigo-600 px-4 py-2 text-xs font-medium text-white hover:bg-indigo-500 shadow-md"
        >
          + Create New Report Schedule
        </button>
      </div>

      <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-6 shadow-xl">
        {isLoading ? (
          <div className="py-12 text-center text-xs text-slate-500">Loading schedules...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-950/60 text-xs font-medium uppercase text-slate-400">
                <tr>
                  <th className="px-4 py-3">Schedule Name</th>
                  <th className="px-4 py-3">Report Type</th>
                  <th className="px-4 py-3">Cron Schedule</th>
                  <th className="px-4 py-3">Recipients</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3">Created Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60">
                {schedules.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-slate-500">
                      No automated report schedules configured yet.
                    </td>
                  </tr>
                ) : (
                  schedules.map((s) => (
                    <tr key={s.id} className="hover:bg-slate-800/30">
                      <td className="px-4 py-3 font-semibold text-slate-200">{s.name}</td>
                      <td className="px-4 py-3 font-mono text-xs text-cyan-400">{s.report_type}</td>
                      <td className="px-4 py-3 font-mono text-xs text-indigo-400">{s.cron_expression}</td>
                      <td className="px-4 py-3 text-xs text-slate-400">
                        {Array.isArray(s.recipients) ? s.recipients.join(", ") : "None"}
                      </td>
                      <td className="px-4 py-3">
                        <span className="rounded bg-emerald-500/10 px-2 py-0.5 text-xs font-bold text-emerald-400 border border-emerald-500/20">
                          Active
                        </span>
                      </td>
                      <td className="px-4 py-3 text-xs text-slate-500">
                        {new Date(s.created_at).toLocaleDateString()}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
          <div className="w-full max-w-md rounded-xl border border-slate-800 bg-slate-900 p-6 shadow-2xl space-y-4">
            <h2 className="text-lg font-bold text-slate-100">Add Automated Schedule</h2>
            <form onSubmit={handleCreate} className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-slate-400 mb-1">Schedule Name</label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Monthly Accounts Section PDF Export"
                  className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-xs text-slate-200"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-400 mb-1">Cron Expression</label>
                <input
                  type="text"
                  required
                  value={cron}
                  onChange={(e) => setCron(e.target.value)}
                  placeholder="0 8 1 * *"
                  className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-xs font-mono text-indigo-400"
                />
                <p className="mt-1 text-[10px] text-slate-500">Format: Minute Hour Day Month DayOfWeek</p>
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-400 mb-1">Report Type</label>
                <select
                  value={reportType}
                  onChange={(e) => setReportType(e.target.value)}
                  className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-xs text-slate-200"
                >
                  <option value="MONTHLY_SECTION_ATTENDANCE">Monthly Section Register (PDF)</option>
                  <option value="DAILY_LATE_ARRIVALS">Daily Late Arrivals Summary (CSV)</option>
                  <option value="UNCLOSED_PUNCH_EXCEPTIONS">Unclosed Punch Exceptions (CSV)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-400 mb-1">Recipient Email Addresses</label>
                <input
                  type="text"
                  required
                  value={recipients}
                  onChange={(e) => setRecipients(e.target.value)}
                  placeholder="bo.accounts@cag.gov.in, aao.admin@cag.gov.in"
                  className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-xs text-slate-200"
                />
              </div>

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-xs text-slate-300 hover:bg-slate-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-indigo-600 px-4 py-2 text-xs font-semibold text-white hover:bg-indigo-500 shadow-md"
                >
                  Save Schedule
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
