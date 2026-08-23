"use client";

import React, { useEffect, useState } from "react";
import { Building2, Users, UserCheck, Edit3, Check, X, Search, ShieldCheck } from "lucide-react";
import { api } from "../../../lib/api";
import { CandidateOfficer, SectionHierarchy, SectionSummary } from "../../../types/api";

export default function SectionsPage() {
  const [sections, setSections] = useState<SectionSummary[]>([]);
  const [hierarchies, setHierarchies] = useState<Record<string, SectionHierarchy>>({});
  const [loading, setLoading] = useState(true);

  // Modal State
  const [modalOpen, setModalOpen] = useState(false);
  const [activeSection, setActiveSection] = useState<SectionSummary | null>(null);
  const [candidates, setCandidates] = useState<CandidateOfficer[]>([]);
  const [activeTab, setActiveTab] = useState<"BRANCH_OFFICER" | "SECTION_OFFICER">("BRANCH_OFFICER");
  const [selectedBoIds, setSelectedBoIds] = useState<string[]>([]);
  const [selectedAaoIds, setSelectedAaoIds] = useState<string[]>([]);
  const [modalLoading, setModalLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const secs = await api.getSectionSummaries("2026-08-22");
      setSections(secs);

      const hMap: Record<string, SectionHierarchy> = {};
      await Promise.all(
        secs.map(async (sec) => {
          try {
            const h = await api.getSectionHierarchy(sec.section_id);
            hMap[sec.section_id] = h;
          } catch {}
        })
      );
      setHierarchies(hMap);
    } catch (err) {
      console.error("Failed to load section data:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const openAllocationModal = async (sec: SectionSummary) => {
    setActiveSection(sec);
    setModalOpen(true);
    setModalLoading(true);
    setSearchQuery("");
    try {
      const [candList, assignedList] = await Promise.all([
        api.getCandidateOfficers(),
        api.getSectionOfficers(sec.section_id),
      ]);
      setCandidates(candList);

      const boIds = assignedList
        .filter((a) => a.role_title === "BRANCH_OFFICER")
        .map((a) => a.employee_id);
      const aaoIds = assignedList
        .filter((a) => a.role_title === "SECTION_OFFICER")
        .map((a) => a.employee_id);

      setSelectedBoIds(boIds);
      setSelectedAaoIds(aaoIds);
    } catch (err) {
      console.error("Failed to load allocation data:", err);
    } finally {
      setModalLoading(false);
    }
  };

  const handleSaveAllocation = async () => {
    if (!activeSection) return;
    setSaving(true);
    try {
      await Promise.all([
        api.updateSectionOfficers(activeSection.section_id, {
          role_title: "BRANCH_OFFICER",
          employee_ids: selectedBoIds,
        }),
        api.updateSectionOfficers(activeSection.section_id, {
          role_title: "SECTION_OFFICER",
          employee_ids: selectedAaoIds,
        }),
      ]);

      // Refresh section hierarchy for active section
      const updatedH = await api.getSectionHierarchy(activeSection.section_id);
      setHierarchies((prev) => ({ ...prev, [activeSection.section_id]: updatedH }));

      setToastMessage(`Updated officer allocations for ${activeSection.section_name}`);
      setTimeout(() => setToastMessage(null), 4000);
      setModalOpen(false);
    } catch (err: any) {
      alert(`Failed to save officer assignments: ${err.message || err}`);
    } finally {
      setSaving(false);
    }
  };

  const toggleOfficerSelection = (empId: string, role: "BRANCH_OFFICER" | "SECTION_OFFICER") => {
    if (role === "BRANCH_OFFICER") {
      setSelectedBoIds((prev) =>
        prev.includes(empId) ? prev.filter((id) => id !== empId) : [...prev, empId]
      );
    } else {
      setSelectedAaoIds((prev) =>
        prev.includes(empId) ? prev.filter((id) => id !== empId) : [...prev, empId]
      );
    }
  };

  const filteredCandidates = candidates.filter((c) => {
    const matchesRole =
      activeTab === "BRANCH_OFFICER"
        ? c.category === "BRANCH_OFFICER" || c.designation_title.toLowerCase().includes("sao") || c.designation_title.toLowerCase().includes("senior")
        : c.category === "SECTION_OFFICER" || c.designation_title.toLowerCase().includes("aao") || c.designation_title.toLowerCase().includes("assistant");
    const matchesSearch =
      c.employee_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.employee_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.designation_title.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesRole && matchesSearch;
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-5 right-5 z-50 bg-emerald-600 text-white px-4 py-3 rounded-lg shadow-xl flex items-center gap-2 text-xs font-medium">
          <Check className="h-4 w-4" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header */}
      <div className="pb-2 border-b border-[#1E293B] flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
            <Building2 className="h-6 w-6 text-purple-400" />
            <span>Sections & Officer Hierarchy</span>
          </h1>
          <p className="text-xs text-slate-400">
            Organizational section structure, Branch Officers (BO / Sr. AO) & AAO supervisory allocations
          </p>
        </div>
      </div>

      {loading ? (
        <div className="flex h-64 items-center justify-center text-slate-400 text-xs">
          <div className="flex items-center gap-2">
            <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
            <span>Loading Section Hierarchy & Supervisory Assignments...</span>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {sections.map((sec) => {
            const h = hierarchies[sec.section_id];
            return (
              <div
                key={sec.section_id}
                className="bg-[#151D2A] border border-[#1E293B] rounded-xl p-5 space-y-4 shadow-lg flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-center justify-between pb-3 border-b border-[#1E293B]">
                    <div>
                      <h2 className="font-bold text-slate-100 text-base">{sec.section_name}</h2>
                      <span className="text-[10px] font-mono text-purple-400">
                        CODE: {h?.section_code || "SEC"}
                      </span>
                    </div>
                    <div className="flex items-center gap-3">
                      <button
                        onClick={() => openAllocationModal(sec)}
                        className="px-2.5 py-1 text-xs font-semibold rounded-md bg-indigo-600/20 text-indigo-300 border border-indigo-500/30 hover:bg-indigo-600 hover:text-white transition flex items-center gap-1.5"
                        title="Allocate / Manage Officers"
                      >
                        <Edit3 className="h-3.5 w-3.5" />
                        <span>Allocate Officers</span>
                      </button>
                      <div className="text-right">
                        <span className="text-sm font-bold font-mono text-emerald-400">
                          {sec.attendance_rate.toFixed(1)}%
                        </span>
                        <p className="text-[10px] text-slate-400">Attendance</p>
                      </div>
                    </div>
                  </div>

                  {/* Supervisory Officers Hierarchy */}
                  <div className="mt-4 space-y-3">
                    <div className="p-3 rounded-lg bg-[#0B0F17] border border-[#1E293B]">
                      <div className="flex items-center justify-between text-xs font-semibold text-slate-300 mb-1">
                        <div className="flex items-center gap-2">
                          <UserCheck className="h-3.5 w-3.5 text-indigo-400" />
                          <span>Branch Officer (BO / Sr. AO):</span>
                        </div>
                        {h?.branch_officers && h.branch_officers.length > 0 && (
                          <span className="px-1.5 py-0.5 rounded bg-indigo-500/20 text-indigo-300 text-[10px] font-mono">
                            {h.branch_officers.length} Allocated
                          </span>
                        )}
                      </div>
                      <p className="text-xs font-medium text-slate-100 pl-5">
                        {h?.branch_officers && h.branch_officers.length > 0
                          ? h.branch_officers.join(", ")
                          : "Unassigned"}
                      </p>
                    </div>

                    <div className="p-3 rounded-lg bg-[#0B0F17] border border-[#1E293B]">
                      <div className="flex items-center justify-between text-xs font-semibold text-slate-300 mb-1">
                        <div className="flex items-center gap-2">
                          <UserCheck className="h-3.5 w-3.5 text-purple-400" />
                          <span>Assistant Accounts Officer (AAO):</span>
                        </div>
                        {h?.assistant_accounts_officers && h.assistant_accounts_officers.length > 0 && (
                          <span className="px-1.5 py-0.5 rounded bg-purple-500/20 text-purple-300 text-[10px] font-mono">
                            {h.assistant_accounts_officers.length} Allocated
                          </span>
                        )}
                      </div>
                      <p className="text-xs font-medium text-slate-100 pl-5">
                        {h?.assistant_accounts_officers && h.assistant_accounts_officers.length > 0
                          ? h.assistant_accounts_officers.join(", ")
                          : "Unassigned"}
                      </p>
                    </div>
                  </div>
                </div>

                {/* Section Metrics Footer */}
                <div className="grid grid-cols-4 gap-2 pt-3 border-t border-[#1E293B] text-center text-xs">
                  <div>
                    <span className="text-slate-400 text-[10px]">Staff</span>
                    <p className="font-bold font-mono text-slate-200">{sec.total}</p>
                  </div>
                  <div>
                    <span className="text-emerald-400 text-[10px]">Present</span>
                    <p className="font-bold font-mono text-emerald-400">{sec.present}</p>
                  </div>
                  <div>
                    <span className="text-amber-400 text-[10px]">Late</span>
                    <p className="font-bold font-mono text-amber-400">{sec.late}</p>
                  </div>
                  <div>
                    <span className="text-rose-400 text-[10px]">Absent</span>
                    <p className="font-bold font-mono text-rose-400">{sec.absent}</p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Allocation Management Modal */}
      {modalOpen && activeSection && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
          <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl w-full max-w-2xl shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
            {/* Modal Header */}
            <div className="p-4 border-b border-[#1E293B] flex items-center justify-between bg-[#0B0F17]">
              <div>
                <h2 className="text-lg font-bold text-slate-100 flex items-center gap-2">
                  <ShieldCheck className="h-5 w-5 text-indigo-400" />
                  <span>Manage Officers - {activeSection.section_name}</span>
                </h2>
                <p className="text-xs text-slate-400">
                  Allocate Senior Accounts Officers (Sr. AO / BO) and Assistant Accounts Officers (AAO)
                </p>
              </div>
              <button
                onClick={() => setModalOpen(false)}
                className="text-slate-400 hover:text-slate-100 transition p-1 rounded-lg hover:bg-slate-800"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Role Tabs */}
            <div className="flex border-b border-[#1E293B] bg-[#0F172A] px-4 pt-2 gap-2">
              <button
                onClick={() => setActiveTab("BRANCH_OFFICER")}
                className={`pb-2.5 px-4 text-xs font-bold transition border-b-2 flex items-center gap-2 ${
                  activeTab === "BRANCH_OFFICER"
                    ? "border-indigo-500 text-indigo-400"
                    : "border-transparent text-slate-400 hover:text-slate-200"
                }`}
              >
                <UserCheck className="h-4 w-4" />
                <span>Senior AO (Branch Officer)</span>
                <span className="ml-1 px-1.5 py-0.5 rounded-full bg-indigo-500/20 text-indigo-300 font-mono text-[10px]">
                  {selectedBoIds.length}
                </span>
              </button>
              <button
                onClick={() => setActiveTab("SECTION_OFFICER")}
                className={`pb-2.5 px-4 text-xs font-bold transition border-b-2 flex items-center gap-2 ${
                  activeTab === "SECTION_OFFICER"
                    ? "border-purple-500 text-purple-400"
                    : "border-transparent text-slate-400 hover:text-slate-200"
                }`}
              >
                <UserCheck className="h-4 w-4" />
                <span>AAO (Section Officer)</span>
                <span className="ml-1 px-1.5 py-0.5 rounded-full bg-purple-500/20 text-purple-300 font-mono text-[10px]">
                  {selectedAaoIds.length}
                </span>
              </button>
            </div>

            {/* Search & Content */}
            <div className="p-4 space-y-3 flex-1 overflow-y-auto">
              <div className="relative">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search officers by name, code or designation..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 bg-[#0B0F17] border border-[#1E293B] rounded-lg text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-indigo-500"
                />
              </div>

              {modalLoading ? (
                <div className="flex h-40 items-center justify-center text-slate-400 text-xs gap-2">
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
                  <span>Loading candidate officers...</span>
                </div>
              ) : filteredCandidates.length === 0 ? (
                <div className="p-8 text-center text-slate-400 text-xs">
                  No candidate {activeTab === "BRANCH_OFFICER" ? "Senior AOs (Branch Officers)" : "Assistant Accounts Officers (AAOs)"} found matching your query.
                </div>
              ) : (
                <div className="space-y-2">
                  {filteredCandidates.map((c) => {
                    const isSelected =
                      activeTab === "BRANCH_OFFICER"
                        ? selectedBoIds.includes(c.id)
                        : selectedAaoIds.includes(c.id);

                    return (
                      <div
                        key={c.id}
                        onClick={() => toggleOfficerSelection(c.id, activeTab)}
                        className={`p-3 rounded-lg border transition cursor-pointer flex items-center justify-between ${
                          isSelected
                            ? "bg-indigo-950/40 border-indigo-500/60 text-slate-100"
                            : "bg-[#0B0F17] border-[#1E293B] text-slate-300 hover:border-slate-700"
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <div
                            className={`h-5 w-5 rounded border flex items-center justify-center transition ${
                              isSelected
                                ? "bg-indigo-600 border-indigo-500 text-white"
                                : "border-slate-700 bg-slate-900"
                            }`}
                          >
                            {isSelected && <Check className="h-3.5 w-3.5" />}
                          </div>
                          <div>
                            <p className="text-xs font-bold text-slate-100">{c.employee_name}</p>
                            <div className="flex items-center gap-2 text-[10px] text-slate-400">
                              <span className="font-mono text-indigo-400">{c.employee_code}</span>
                              <span>•</span>
                              <span>{c.designation_title}</span>
                            </div>
                          </div>
                        </div>

                        {isSelected && (
                          <span className="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-indigo-500/20 text-indigo-300 border border-indigo-500/30">
                            Allocated
                          </span>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Modal Footer */}
            <div className="p-4 border-t border-[#1E293B] bg-[#0B0F17] flex items-center justify-between">
              <span className="text-xs text-slate-400 font-mono">
                {activeTab === "BRANCH_OFFICER" ? selectedBoIds.length : selectedAaoIds.length} officer(s) selected
              </span>
              <div className="flex items-center gap-3">
                <button
                  onClick={() => setModalOpen(false)}
                  className="px-4 py-1.5 text-xs font-medium text-slate-400 hover:text-slate-200 transition"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSaveAllocation}
                  disabled={saving}
                  className="px-4 py-1.5 text-xs font-semibold rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white transition disabled:opacity-50 flex items-center gap-2"
                >
                  {saving && <div className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white border-t-transparent" />}
                  <span>Save Allocations</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
