"use client";

import React, { useEffect, useState } from "react";
import { Settings, Clock, ShieldAlert, Plus, AlertTriangle, Edit3 } from "lucide-react";
import { api } from "../../../../lib/api";
import { AttendanceRule } from "../../../../types/api";

export default function AttendanceRulesPage() {
  const [rules, setRules] = useState<AttendanceRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState<AttendanceRule | null>(null);

  // Form State
  const [code, setCode] = useState("REGULAR");
  const [name, setName] = useState("Regular Office Shift");
  const [shiftStart, setShiftStart] = useState("09:30");
  const [shiftEnd, setShiftEnd] = useState("17:30");
  const [gracePeriod, setGracePeriod] = useState(15);
  const [halfDayMin, setHalfDayMin] = useState(240);
  const [fullDayMin, setFullDayMin] = useState(420);
  const [earlyExitMin, setEarlyExitMin] = useState(15);

  // Edit Form State
  const [editName, setEditName] = useState("");
  const [editShiftStart, setEditShiftStart] = useState("09:30");
  const [editShiftEnd, setEditShiftEnd] = useState("17:30");
  const [editGracePeriod, setEditGracePeriod] = useState(15);
  const [editHalfDayMin, setEditHalfDayMin] = useState(240);
  const [editFullDayMin, setEditFullDayMin] = useState(420);
  const [editEarlyExitMin, setEditEarlyExitMin] = useState(15);
  const [submitting, setSubmitting] = useState(false);

  const loadRules = async () => {
    setLoading(true);
    try {
      const data = await api.listRules();
      setRules(data);
    } catch (err) {
      console.error("Failed to load attendance rules:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRules();
  }, []);

  const handleCreateRule = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await api.createRule({
        code,
        name,
        shift_start: shiftStart,
        shift_end: shiftEnd,
        grace_period_minutes: gracePeriod,
        half_day_minimum_minutes: halfDayMin,
        full_day_minimum_minutes: fullDayMin,
        early_exit_threshold_minutes: earlyExitMin,
        crosses_midnight: false,
      });
      setShowAddModal(false);
      await loadRules();
    } catch (err: any) {
      alert(err.message || "Failed to create attendance rule");
    } finally {
      setSubmitting(false);
    }
  };

  const openEditModal = (rule: AttendanceRule) => {
    setShowEditModal(rule);
    setEditName(rule.name);
    setEditShiftStart(rule.shift_start);
    setEditShiftEnd(rule.shift_end);
    setEditGracePeriod(rule.grace_period_minutes);
    setEditHalfDayMin(rule.half_day_minimum_minutes);
    setEditFullDayMin(rule.full_day_minimum_minutes);
    setEditEarlyExitMin(rule.early_exit_threshold_minutes);
  };

  const handleUpdateRule = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!showEditModal) return;

    setSubmitting(true);
    try {
      await api.updateRule(showEditModal.id, {
        name: editName,
        shift_start: editShiftStart,
        shift_end: editShiftEnd,
        grace_period_minutes: editGracePeriod,
        half_day_minimum_minutes: editHalfDayMin,
        full_day_minimum_minutes: editFullDayMin,
        early_exit_threshold_minutes: editEarlyExitMin,
      });
      setShowEditModal(null);
      await loadRules();
    } catch (err: any) {
      alert(err.message || "Failed to update attendance rule");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#1E293B]">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
            <Settings className="h-6 w-6 text-indigo-400" />
            <span>Attendance & Shift Rules Configuration</span>
          </h1>
          <p className="text-xs text-slate-400">
            Define shift hours, grace periods, punctuality thresholds & duty duration requirements
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs px-4 py-2.5 rounded-lg transition-colors shadow-lg shadow-indigo-600/30 flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          <span>Add Shift Rule</span>
        </button>
      </div>

      {/* Warning Banner */}
      <div className="p-4 rounded-xl bg-[#151D2A] border border-amber-500/30 flex items-center gap-3 text-xs text-amber-300">
        <AlertTriangle className="h-5 w-5 shrink-0 text-amber-400" />
        <span>
          <strong>Historical Integrity Guard:</strong> Modifying attendance rules changes future punch calculations. Historical attendance daily facts remain protected and will not automatically rewrite until batch recalculation is explicitly executed by an administrator.
        </span>
      </div>

      {/* Shift Rules List Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {loading ? (
          <div className="col-span-2 flex h-48 items-center justify-center text-slate-400 text-xs">
            <div className="flex items-center gap-2">
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
              <span>Loading Shift Rules...</span>
            </div>
          </div>
        ) : (
          rules.map((rule) => (
            <div
              key={rule.id}
              className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-5 space-y-4 shadow-lg flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-[#1E293B]">
                  <div>
                    <h2 className="font-bold text-slate-100 text-base">{rule.name}</h2>
                    <span className="text-[10px] font-mono text-indigo-400 font-bold">
                      CODE: {rule.code}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="px-2.5 py-1 rounded bg-indigo-600/20 text-indigo-300 border border-indigo-500/30 font-mono text-xs font-bold">
                      {rule.shift_start} - {rule.shift_end}
                    </div>
                    <button
                      onClick={() => openEditModal(rule)}
                      className="p-1.5 rounded bg-sky-600/20 hover:bg-sky-600/30 text-sky-300 border border-sky-500/30 transition-colors flex items-center gap-1 text-[11px] px-2 font-semibold"
                      title="Configure Shift & Attendance Rule Parameters"
                    >
                      <Edit3 className="h-3.5 w-3.5" />
                      <span>Edit Rule</span>
                    </button>
                  </div>
                </div>

                <div className="mt-4 grid grid-cols-2 gap-3 text-xs">
                  <div className="p-3 rounded-lg bg-[#0B0F17] border border-[#1E293B]">
                    <span className="text-slate-400 text-[10px] uppercase font-semibold">
                      Grace Period
                    </span>
                    <p className="font-bold font-mono text-amber-400 text-sm mt-0.5">
                      {rule.grace_period_minutes} minutes
                    </p>
                  </div>

                  <div className="p-3 rounded-lg bg-[#0B0F17] border border-[#1E293B]">
                    <span className="text-slate-400 text-[10px] uppercase font-semibold">
                      Early Exit Threshold
                    </span>
                    <p className="font-bold font-mono text-rose-400 text-sm mt-0.5">
                      {rule.early_exit_threshold_minutes} minutes
                    </p>
                  </div>

                  <div className="p-3 rounded-lg bg-[#0B0F17] border border-[#1E293B]">
                    <span className="text-slate-400 text-[10px] uppercase font-semibold">
                      Full Day Minimum
                    </span>
                    <p className="font-bold font-mono text-emerald-400 text-sm mt-0.5">
                      {rule.full_day_minimum_minutes} minutes (7h)
                    </p>
                  </div>

                  <div className="p-3 rounded-lg bg-[#0B0F17] border border-[#1E293B]">
                    <span className="text-slate-400 text-[10px] uppercase font-semibold">
                      Half Day Minimum
                    </span>
                    <p className="font-bold font-mono text-purple-400 text-sm mt-0.5">
                      {rule.half_day_minimum_minutes} minutes (4h)
                    </p>
                  </div>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Add Shift Rule Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center p-4 z-50">
          <div className="bg-[#151D2A] border border-[#1E293B] rounded-2xl p-6 w-full max-w-md space-y-4 shadow-2xl">
            <h2 className="text-lg font-bold text-slate-100">Create Shift Attendance Rule</h2>

            <form onSubmit={handleCreateRule} className="space-y-3">
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Rule Code
                  </label>
                  <input
                    type="text"
                    required
                    value={code}
                    onChange={(e) => setCode(e.target.value)}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono"
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Rule Name
                  </label>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Shift Start (HH:MM)
                  </label>
                  <input
                    type="text"
                    required
                    value={shiftStart}
                    onChange={(e) => setShiftStart(e.target.value)}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono"
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Shift End (HH:MM)
                  </label>
                  <input
                    type="text"
                    required
                    value={shiftEnd}
                    onChange={(e) => setShiftEnd(e.target.value)}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Grace Period (Mins)
                  </label>
                  <input
                    type="number"
                    required
                    value={gracePeriod}
                    onChange={(e) => setGracePeriod(Number(e.target.value))}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono text-amber-400 font-bold"
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Early Exit (Mins)
                  </label>
                  <input
                    type="number"
                    required
                    value={earlyExitMin}
                    onChange={(e) => setEarlyExitMin(Number(e.target.value))}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono text-rose-400 font-bold"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Full Day Min (Mins)
                  </label>
                  <input
                    type="number"
                    required
                    value={fullDayMin}
                    onChange={(e) => setFullDayMin(Number(e.target.value))}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono text-emerald-400 font-bold"
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Half Day Min (Mins)
                  </label>
                  <input
                    type="number"
                    required
                    value={halfDayMin}
                    onChange={(e) => setHalfDayMin(Number(e.target.value))}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono text-purple-400 font-bold"
                  />
                </div>
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
                  Save Shift Rule
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {/* Edit Shift Rule Modal */}
      {showEditModal && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center p-4 z-50">
          <div className="bg-[#151D2A] border border-[#1E293B] rounded-2xl p-6 w-full max-w-md space-y-4 shadow-2xl">
            <div className="flex items-center justify-between border-b border-[#1E293B] pb-3">
              <h2 className="text-sm font-bold text-slate-100 flex items-center gap-2">
                <Edit3 className="h-4 w-4 text-sky-400" />
                <span>Configure Shift Attendance Rule</span>
              </h2>
              <span className="text-[10px] font-mono text-indigo-400 font-bold bg-indigo-500/10 px-2 py-0.5 rounded border border-indigo-500/20">
                {showEditModal.code}
              </span>
            </div>

            <form onSubmit={handleUpdateRule} className="space-y-3">
              <div>
                <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Rule Name
                </label>
                <input
                  type="text"
                  required
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 focus:outline-none focus:border-sky-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Shift Start (HH:MM)
                  </label>
                  <input
                    type="text"
                    required
                    value={editShiftStart}
                    onChange={(e) => setEditShiftStart(e.target.value)}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono focus:outline-none focus:border-sky-500"
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Shift End (HH:MM)
                  </label>
                  <input
                    type="text"
                    required
                    value={editShiftEnd}
                    onChange={(e) => setEditShiftEnd(e.target.value)}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono focus:outline-none focus:border-sky-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Grace Period (Mins)
                  </label>
                  <input
                    type="number"
                    required
                    value={editGracePeriod}
                    onChange={(e) => setEditGracePeriod(Number(e.target.value))}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono text-amber-400 font-bold focus:outline-none focus:border-sky-500"
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Early Exit (Mins)
                  </label>
                  <input
                    type="number"
                    required
                    value={editEarlyExitMin}
                    onChange={(e) => setEditEarlyExitMin(Number(e.target.value))}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono text-rose-400 font-bold focus:outline-none focus:border-sky-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Full Day Min (Mins)
                  </label>
                  <input
                    type="number"
                    required
                    value={editFullDayMin}
                    onChange={(e) => setEditFullDayMin(Number(e.target.value))}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono text-emerald-400 font-bold focus:outline-none focus:border-sky-500"
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Half Day Min (Mins)
                  </label>
                  <input
                    type="number"
                    required
                    value={editHalfDayMin}
                    onChange={(e) => setEditHalfDayMin(Number(e.target.value))}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 font-mono text-purple-400 font-bold focus:outline-none focus:border-sky-500"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-3 border-t border-[#1E293B]">
                <button
                  type="button"
                  onClick={() => setShowEditModal(null)}
                  className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-400 hover:text-slate-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="bg-sky-600 hover:bg-sky-500 text-white font-semibold text-xs px-4 py-2 rounded-lg transition-colors shadow-lg shadow-sky-600/30"
                >
                  {submitting ? "Saving..." : "Update Shift Rule"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
