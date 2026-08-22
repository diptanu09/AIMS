"use client";

import React, { useEffect, useState } from "react";
import { Calendar, Plus } from "lucide-react";
import { api } from "../../../../lib/api";
import { HolidayRow } from "../../../../types/api";

export default function HolidaysPage() {
  const [holidays, setHolidays] = useState<HolidayRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);

  const [date, setDate] = useState("2026-08-15");
  const [name, setName] = useState("Independence Day");
  const [description, setDescription] = useState("National Holiday");
  const [isOptional, setIsOptional] = useState(false);

  const loadHolidays = async () => {
    setLoading(true);
    try {
      const data = await api.listHolidays();
      setHolidays(data);
    } catch (err) {
      console.error("Failed to load holidays:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadHolidays();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.createHoliday({
        holiday_date: date,
        name,
        description,
        is_optional: isOptional,
      });
      setShowAddModal(false);
      await loadHolidays();
    } catch (err: any) {
      alert(err.message || "Failed to create holiday");
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#1E293B]">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
            <Calendar className="h-6 w-6 text-purple-400" />
            <span>Holiday Calendar Management</span>
          </h1>
          <p className="text-xs text-slate-400">
            Define official gazetted holidays, restricted optional holidays & non-working dates
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs px-4 py-2.5 rounded-lg transition-colors shadow-lg shadow-indigo-600/30 flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          <span>Add Holiday</span>
        </button>
      </div>

      {/* Holiday Table */}
      <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl overflow-hidden shadow-lg">
        {loading ? (
          <div className="flex h-64 items-center justify-center text-slate-400 text-xs">
            <div className="flex items-center gap-2">
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
              <span>Querying Holiday Calendar...</span>
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#1E293B]/60 text-slate-400 uppercase font-semibold text-[10px]">
                <tr>
                  <th className="p-3">Date</th>
                  <th className="p-3">Holiday Name</th>
                  <th className="p-3">Description</th>
                  <th className="p-3 text-right">Type</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1E293B] text-slate-200">
                {holidays.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="p-8 text-center text-slate-500">
                      No official holiday dates recorded.
                    </td>
                  </tr>
                ) : (
                  holidays.map((h) => (
                    <tr key={h.id} className="hover:bg-[#1E293B]/30 transition-colors">
                      <td className="p-3 font-mono font-bold text-indigo-300">{h.holiday_date}</td>
                      <td className="p-3 font-semibold text-slate-100">{h.name}</td>
                      <td className="p-3 text-slate-400">{h.description || "--"}</td>
                      <td className="p-3 text-right">
                        {h.is_optional ? (
                          <span className="px-2 py-0.5 rounded bg-purple-500/20 text-purple-400 border border-purple-500/30 font-mono text-[10px] font-bold">
                            OPTIONAL / RESTRICTED
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 font-mono text-[10px] font-bold">
                            GAZETTED
                          </span>
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

      {/* Add Holiday Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center p-4 z-50">
          <div className="bg-[#151D2A] border border-[#1E293B] rounded-2xl p-6 w-full max-w-md space-y-4 shadow-2xl">
            <h2 className="text-lg font-bold text-slate-100">Add Holiday Entry</h2>

            <form onSubmit={handleCreate} className="space-y-3">
              <div>
                <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Holiday Date
                </label>
                <input
                  type="date"
                  required
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono"
                />
              </div>

              <div>
                <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Holiday Name
                </label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100"
                />
              </div>

              <div>
                <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Description
                </label>
                <input
                  type="text"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100"
                />
              </div>

              <div className="flex items-center gap-2 pt-1">
                <input
                  type="checkbox"
                  id="opt"
                  checked={isOptional}
                  onChange={(e) => setIsOptional(e.target.checked)}
                  className="rounded border-[#1E293B] text-indigo-600 focus:ring-0"
                />
                <label htmlFor="opt" className="text-xs text-slate-300">
                  Is Optional / Restricted Holiday
                </label>
              </div>

              <div className="flex items-center justify-end gap-3 pt-3">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-400 hover:text-slate-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs px-4 py-2 rounded-lg transition-colors shadow-lg shadow-indigo-600/30"
                >
                  Save Holiday
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
