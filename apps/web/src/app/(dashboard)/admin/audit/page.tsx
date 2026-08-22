"use client";

import React, { useEffect, useState } from "react";
import { ShieldCheck, User, Terminal } from "lucide-react";
import { api } from "../../../../lib/api";
import { AuditLogRow } from "../../../../types/api";

export default function AuditPage() {
  const [logs, setLogs] = useState<AuditLogRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadLogs() {
      setLoading(true);
      try {
        const data = await api.listAuditLogs(100, 0);
        setLogs(data);
      } catch (err) {
        console.error("Failed to load audit trail:", err);
      } finally {
        setLoading(false);
      }
    }
    loadLogs();
  }, []);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="pb-2 border-b border-[#1E293B]">
        <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
          <ShieldCheck className="h-6 w-6 text-emerald-400" />
          <span>Immutable Audit Log & Compliance Trail</span>
        </h1>
        <p className="text-xs text-slate-400">
          Cryptographically chained & immutable administrative action logs for CAG compliance review
        </p>
      </div>

      {/* Audit Log Table */}
      <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl overflow-hidden shadow-lg">
        {loading ? (
          <div className="flex h-64 items-center justify-center text-slate-400 text-xs">
            <div className="flex items-center gap-2">
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
              <span>Querying Audit Trail...</span>
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#1E293B]/60 text-slate-400 uppercase font-semibold text-[10px]">
                <tr>
                  <th className="p-3">Timestamp</th>
                  <th className="p-3">Operator / User</th>
                  <th className="p-3">Action Event</th>
                  <th className="p-3">Entity Target</th>
                  <th className="p-3 font-mono">Correlation ID</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1E293B] text-slate-200">
                {logs.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="p-8 text-center text-slate-500">
                      No audit log records recorded.
                    </td>
                  </tr>
                ) : (
                  logs.map((log) => (
                    <tr key={log.id} className="hover:bg-[#1E293B]/30 transition-colors">
                      <td className="p-3 font-mono text-slate-400">
                        {new Date(log.created_at).toLocaleString("en-IN")}
                      </td>
                      <td className="p-3">
                        <div className="font-semibold text-slate-200 flex items-center gap-1.5">
                          <User className="h-3.5 w-3.5 text-indigo-400" />
                          <span>{log.username || "SYSTEM"}</span>
                        </div>
                      </td>
                      <td className="p-3">
                        <span className="px-2 py-0.5 rounded bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 font-mono text-[10px] font-bold">
                          {log.action}
                        </span>
                      </td>
                      <td className="p-3 text-slate-300 font-mono">{log.entity_name}</td>
                      <td className="p-3 font-mono text-[10px] text-slate-500">
                        {log.entity_id || log.id}
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
  );
}
