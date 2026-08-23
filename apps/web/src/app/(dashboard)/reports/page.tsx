"use client";

import React, { useEffect, useState } from "react";
import { FileText, Download, Play, CheckCircle2, AlertCircle, Clock } from "lucide-react";
import { api } from "../../../lib/api";
import { ReportRun, SectionSummary } from "../../../types/api";

export default function ReportsPage() {
  const [runs, setRuns] = useState<ReportRun[]>([]);
  const [sections, setSections] = useState<SectionSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);

  // Form State
  const [reportType] = useState("MonthlySection");
  const [format, setFormat] = useState("Pdf");
  const [dateFrom, setDateFrom] = useState("2026-08-01");
  const [dateTo, setDateTo] = useState("2026-08-31");
  const [sectionId, setSectionId] = useState("");

  const loadData = async () => {
    setLoading(true);
    try {
      const [rRuns, rSecs] = await Promise.all([
        api.listReportRuns(),
        api.getSectionSummaries("2026-08-22"),
      ]);
      setRuns(rRuns);
      setSections(rSecs);
      if (rSecs.length > 0 && !sectionId) {
        setSectionId(rSecs[0].section_id);
      }
    } catch (err) {
      console.error("Failed to load report data:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleGenerate = async (e: React.FormEvent) => {
    e.preventDefault();
    setGenerating(true);
    try {
      await api.generateReport({
        report_type: reportType,
        format,
        date_from: dateFrom,
        date_to: dateTo,
        section_id: sectionId || undefined,
      });
      await loadData();
    } catch (err: any) {
      alert(err.message || "Failed to generate report");
    } finally {
      setGenerating(false);
    }
  };

  const handleDownload = async (runId: string, formatName: string) => {
    try {
      const downloadUrl = api.getReportDownloadUrl(runId);
      const res = await fetch(downloadUrl, { credentials: "include" });
      if (!res.ok) {
        throw new Error(`Failed to download report (HTTP ${res.status})`);
      }
      const blob = await res.blob();
      const ext = formatName.toLowerCase() === "pdf" ? "pdf" : formatName.toLowerCase() === "xlsx" ? "xlsx" : "csv";
      const filename = `report_${runId}.${ext}`;
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch (err: any) {
      alert(err.message || "Failed to download report");
    }
  };

  const renderStatus = (st: string) => {
    const s = (st || "").toUpperCase();
    if (s === "FAILED") {
      return (
        <span className="flex items-center gap-1 text-rose-400 font-mono text-[11px] font-bold">
          <AlertCircle className="h-3.5 w-3.5" /> FAILED
        </span>
      );
    }
    if (s === "PROCESSING") {
      return (
        <span className="flex items-center gap-1 text-amber-400 font-mono text-[11px] font-bold animate-pulse">
          <Clock className="h-3.5 w-3.5" /> PROCESSING
        </span>
      );
    }
    return (
      <span className="flex items-center gap-1 text-emerald-400 font-mono text-[11px] font-bold">
        <CheckCircle2 className="h-3.5 w-3.5" /> COMPLETED
      </span>
    );
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="pb-2 border-b border-[#1E293B]">
        <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
          <FileText className="h-6 w-6 text-purple-400" />
          <span>Professional Report Engine</span>
        </h1>
        <p className="text-xs text-slate-400">
          Generate formal section attendance registers, officer hierarchy summaries & exports
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Report Generation Generator Form */}
        <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-5 space-y-4">
          <h2 className="font-semibold text-slate-100 text-sm border-b border-[#1E293B] pb-3">
            Generate Report
          </h2>

          <form onSubmit={handleGenerate} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
                Report Template
              </label>
              <select
                value={reportType}
                disabled
                className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none"
              >
                <option value="MonthlySection">
                  Monthly Section Attendance Report (Gold Standard)
                </option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
                Section
              </label>
              <select
                value={sectionId}
                onChange={(e) => setSectionId(e.target.value)}
                required
                className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500"
              >
                {sections.map((sec) => (
                  <option key={sec.section_id} value={sec.section_id}>
                    {sec.section_name} ({sec.total} Staff)
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
                  From Date
                </label>
                <input
                  type="date"
                  value={dateFrom}
                  onChange={(e) => setDateFrom(e.target.value)}
                  required
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500 font-mono"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
                  To Date
                </label>
                <input
                  type="date"
                  value={dateTo}
                  onChange={(e) => setDateTo(e.target.value)}
                  required
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500 font-mono"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
                Output Format
              </label>
              <div className="grid grid-cols-3 gap-2">
                {["Pdf", "Csv", "Xlsx"].map((fmt) => (
                  <button
                    key={fmt}
                    type="button"
                    onClick={() => setFormat(fmt)}
                    className={`py-2 rounded-lg text-xs font-bold font-mono transition-colors border ${
                      format === fmt
                        ? "bg-indigo-600/20 text-indigo-300 border-indigo-500"
                        : "bg-[#0B0F17] text-slate-400 border-[#1E293B] hover:text-slate-200"
                    }`}
                  >
                    {fmt.toUpperCase()}
                  </button>
                ))}
              </div>
            </div>

            <button
              type="submit"
              disabled={generating}
              className="w-full bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white font-semibold text-xs py-3 rounded-lg transition-colors shadow-lg shadow-indigo-600/25 flex items-center justify-center gap-2 mt-4"
            >
              <Play className="h-4 w-4" />
              <span>{generating ? "Generating..." : "Queue Report Run"}</span>
            </button>
          </form>
        </div>

        {/* Report Execution History List */}
        <div className="lg:col-span-2 bg-[#151D2A] border border-[#1E293B] rounded-xl p-5 space-y-4">
          <h2 className="font-semibold text-slate-100 text-sm border-b border-[#1E293B] pb-3">
            Recent Report Execution Runs
          </h2>

          {loading ? (
            <div className="flex h-48 items-center justify-center text-slate-400 text-xs">
              <div className="flex items-center gap-2">
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
                <span>Loading Report Run Log...</span>
              </div>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-[#1E293B]/50 text-slate-400 uppercase font-semibold text-[10px]">
                  <tr>
                    <th className="p-3">Created At</th>
                    <th className="p-3">Format</th>
                    <th className="p-3">Status</th>
                    <th className="p-3 text-right">Download</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#1E293B] text-slate-200">
                  {runs.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="p-8 text-center text-slate-500">
                        No report runs recorded. Select parameters and click &apos;Queue Report Run&apos;.
                      </td>
                    </tr>
                  ) : (
                    runs.map((run) => (
                      <tr key={run.id} className="hover:bg-[#1E293B]/30 transition-colors">
                        <td className="p-3 font-mono text-slate-300">
                          {new Date(run.created_at).toLocaleString("en-IN")}
                        </td>
                        <td className="p-3 font-mono font-bold text-indigo-400">
                          {run.output_format}
                        </td>
                        <td className="p-3">{renderStatus(run.status)}</td>
                        <td className="p-3 text-right">
                          {run.status?.toUpperCase() !== "FAILED" ? (
                            <button
                              onClick={() => handleDownload(run.id, run.output_format)}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 border border-emerald-500/30 font-semibold text-xs transition-colors cursor-pointer"
                            >
                              <Download className="h-3.5 w-3.5" />
                              <span>Download</span>
                            </button>
                          ) : (
                            <span className="text-slate-500 text-[11px]">--</span>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
