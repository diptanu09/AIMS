"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { ReconciliationDiscrepancy, ReconciliationSummary } from "@/types/api";

export default function PilotReconciliationPage() {
  const [summary, setSummary] = useState<ReconciliationSummary | null>(null);
  const [discrepancies, setDiscrepancies] = useState<ReconciliationDiscrepancy[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>("ALL");

  useEffect(() => {
    async function loadData() {
      try {
        const [sumRes, discRes] = await Promise.all([
          api.getReconciliationSummary(),
          api.getReconciliationDiscrepancies(),
        ]);
        setSummary(sumRes);
        setDiscrepancies(discRes);
      } catch (err) {
        console.error("Failed to load pilot reconciliation data", err);
      } finally {
        setIsLoading(false);
      }
    }
    loadData();
  }, []);

  const filteredDiscrepancies = discrepancies.filter((d) =>
    selectedCategory === "ALL" ? true : d.category === selectedCategory
  );

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-100">
            Pilot Parallel Validation & Reconciliation
          </h1>
          <p className="text-sm text-slate-400">
            Comparing official legacy attendance records against AIMS processed facts (August 2026).
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className="inline-flex items-center rounded-full bg-emerald-500/10 px-3 py-1 text-xs font-semibold text-emerald-400 border border-emerald-500/20">
            ● Parallel Pilot Run Active
          </span>
          <button
            onClick={() => window.print()}
            className="rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-xs font-medium text-slate-200 hover:bg-slate-700"
          >
            Export Reconciliation Report
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="rounded-xl border border-slate-800 bg-slate-900/50 p-12 text-center text-slate-400">
          Loading reconciliation data...
        </div>
      ) : summary ? (
        <>
          {/* KPI Cards Grid */}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-5 shadow-lg">
              <div className="text-xs font-medium text-slate-400">Reconciliation Match Rate</div>
              <div className="mt-2 flex items-baseline justify-between">
                <span className="text-3xl font-bold text-emerald-400">
                  {summary.match_rate_percentage.toFixed(2)}%
                </span>
                <span className="text-xs font-semibold text-emerald-400">Target: ≥99.5%</span>
              </div>
              <p className="mt-2 text-xs text-slate-500">
                100% Core Status Accuracy
              </p>
            </div>

            <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-5 shadow-lg">
              <div className="text-xs font-medium text-slate-400">Total Official Records</div>
              <div className="mt-2 text-3xl font-bold text-slate-100">
                {summary.total_official_records.toLocaleString()}
              </div>
              <p className="mt-2 text-xs text-slate-500">August 2026 Audit Period</p>
            </div>

            <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-5 shadow-lg">
              <div className="text-xs font-medium text-slate-400">Exact Matches</div>
              <div className="mt-2 text-3xl font-bold text-emerald-400">
                {summary.exact_matches.toLocaleString()}
              </div>
              <p className="mt-2 text-xs text-slate-500">Zero Discrepancy Records</p>
            </div>

            <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-5 shadow-lg">
              <div className="text-xs font-medium text-slate-400">Categorized Differences</div>
              <div className="mt-2 text-3xl font-bold text-amber-400">
                {summary.differences}
              </div>
              <p className="mt-2 text-xs text-amber-400/80">Pending Rule Alignment</p>
            </div>
          </div>

          {/* Category Breakdown Table */}
          <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-6">
            <h2 className="text-lg font-bold text-slate-100 mb-4">
              Discrepancies by Cause & Category
            </h2>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {summary.category_breakdown.map((cat) => (
                <div
                  key={cat.category}
                  onClick={() => setSelectedCategory(cat.category)}
                  className={`cursor-pointer rounded-lg border p-4 transition-all ${
                    selectedCategory === cat.category
                      ? "border-cyan-500 bg-cyan-500/10 text-cyan-200"
                      : "border-slate-800 bg-slate-950/40 text-slate-300 hover:border-slate-700"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs font-semibold">{cat.category}</span>
                    <span className="rounded-full bg-slate-800 px-2.5 py-0.5 text-xs font-bold text-slate-200">
                      {cat.count}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Detailed Discrepancies Table */}
          <div className="rounded-xl border border-slate-800 bg-slate-900/60 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-slate-100">
                Reconciliation Discrepancy Detail
              </h2>
              {selectedCategory !== "ALL" && (
                <button
                  onClick={() => setSelectedCategory("ALL")}
                  className="text-xs text-cyan-400 hover:underline"
                >
                  Reset Category Filter
                </button>
              )}
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm text-slate-300">
                <thead className="bg-slate-950/60 text-xs font-medium uppercase text-slate-400">
                  <tr>
                    <th className="px-4 py-3">Employee</th>
                    <th className="px-4 py-3">Date</th>
                    <th className="px-4 py-3">Official Status</th>
                    <th className="px-4 py-3">AIMS Status</th>
                    <th className="px-4 py-3">Cause Category</th>
                    <th className="px-4 py-3">Resolution Note</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {filteredDiscrepancies.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-4 py-8 text-center text-slate-500">
                        No discrepancies found for category '{selectedCategory}'.
                      </td>
                    </tr>
                  ) : (
                    filteredDiscrepancies.map((d) => (
                      <tr key={d.id} className="hover:bg-slate-800/30">
                        <td className="px-4 py-3">
                          <div className="font-medium text-slate-200">{d.employee_name}</div>
                          <div className="font-mono text-xs text-slate-500">{d.employee_code}</div>
                        </td>
                        <td className="px-4 py-3 font-mono text-xs">{d.attendance_date}</td>
                        <td className="px-4 py-3 font-semibold text-slate-300">
                          {d.official_status}
                        </td>
                        <td className="px-4 py-3">
                          <span className="rounded bg-cyan-500/10 px-2 py-0.5 text-xs font-bold text-cyan-400 border border-cyan-500/20">
                            {d.aims_status}
                          </span>
                        </td>
                        <td className="px-4 py-3 font-mono text-xs text-amber-400">
                          {d.category}
                        </td>
                        <td className="px-4 py-3 text-xs text-slate-400">
                          {d.resolution_notes || "Pending verification"}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}
