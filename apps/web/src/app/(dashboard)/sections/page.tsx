"use client";

import React, { useEffect, useState } from "react";
import { Building2, Users, UserCheck } from "lucide-react";
import { api } from "../../../lib/api";
import { SectionHierarchy, SectionSummary } from "../../../types/api";

export default function SectionsPage() {
  const [sections, setSections] = useState<SectionSummary[]>([]);
  const [hierarchies, setHierarchies] = useState<Record<string, SectionHierarchy>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
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
    }
    loadData();
  }, []);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="pb-2 border-b border-[#1E293B]">
        <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
          <Building2 className="h-6 w-6 text-purple-400" />
          <span>Sections & Officer Hierarchy</span>
        </h1>
        <p className="text-xs text-slate-400">
          Organizational section structure, Branch Officers (BO / Sr. AO) & AAO supervisory assignments
        </p>
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
                    <div className="text-right">
                      <span className="text-sm font-bold font-mono text-emerald-400">
                        {sec.attendance_rate.toFixed(1)}%
                      </span>
                      <p className="text-[10px] text-slate-400">Attendance Rate</p>
                    </div>
                  </div>

                  {/* Supervisory Officers Hierarchy */}
                  <div className="mt-4 space-y-3">
                    <div className="p-3 rounded-lg bg-[#0B0F17] border border-[#1E293B]">
                      <div className="flex items-center gap-2 text-xs font-semibold text-slate-300 mb-1">
                        <UserCheck className="h-3.5 w-3.5 text-indigo-400" />
                        <span>Branch Officer (BO / Sr. AO):</span>
                      </div>
                      <p className="text-xs font-medium text-slate-100 pl-5">
                        {h?.branch_officers && h.branch_officers.length > 0
                          ? h.branch_officers.join(", ")
                          : "Unassigned"}
                      </p>
                    </div>

                    <div className="p-3 rounded-lg bg-[#0B0F17] border border-[#1E293B]">
                      <div className="flex items-center gap-2 text-xs font-semibold text-slate-300 mb-1">
                        <UserCheck className="h-3.5 w-3.5 text-purple-400" />
                        <span>Assistant Accounts Officer (AAO):</span>
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
    </div>
  );
}
