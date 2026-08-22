"use client";

import React, { useEffect, useState } from "react";
import { CheckSquare, CheckCircle2, XCircle, AlertTriangle, UserCheck } from "lucide-react";
import { api } from "../../../lib/api";
import { useAuth } from "../../../lib/auth-context";
import { AttendanceCorrectionRow } from "../../../types/api";

export default function CorrectionsPage() {
  const { user } = useAuth();
  const [corrections, setCorrections] = useState<AttendanceCorrectionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const loadCorrections = async () => {
    setLoading(true);
    try {
      const data = await api.listCorrections(statusFilter || undefined);
      setCorrections(data);
    } catch (err) {
      console.error("Failed to load corrections:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCorrections();
  }, [statusFilter]);

  const handleApprove = async (id: string, requesterId: string) => {
    if (user?.user_id === requesterId) {
      alert("Self-approval prohibited: You cannot approve a correction request created by yourself.");
      return;
    }

    setActionLoading(id);
    try {
      await api.approveCorrection(id);
      await loadCorrections();
    } catch (err: any) {
      alert(err.message || "Failed to approve correction");
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async (id: string) => {
    const reason = prompt("Enter rejection reason:");
    if (!reason) return;

    setActionLoading(id);
    try {
      await api.rejectCorrection(id, reason);
      await loadCorrections();
    } catch (err: any) {
      alert(err.message || "Failed to reject correction");
    } finally {
      setActionLoading(null);
    }
  };

  const formatTime = (ts: string | null) => {
    if (!ts) return "MISSING";
    return new Date(ts).toLocaleTimeString("en-IN", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#1E293B]">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
            <CheckSquare className="h-6 w-6 text-emerald-400" />
            <span>Attendance Correction & Approval Workflow</span>
          </h1>
          <p className="text-xs text-slate-400">
            Review punch corrections, missing log resolutions & supervisor approvals
          </p>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2">
        <button
          onClick={() => setStatusFilter("")}
          className={`px-4 py-2 rounded-lg text-xs font-semibold transition-colors ${
            statusFilter === ""
              ? "bg-indigo-600 text-white shadow-lg shadow-indigo-600/30"
              : "bg-[#151D2A] border border-[#1E293B] text-slate-400 hover:text-slate-200"
          }`}
        >
          All Requests
        </button>

        <button
          onClick={() => setStatusFilter("PENDING")}
          className={`px-4 py-2 rounded-lg text-xs font-semibold transition-colors ${
            statusFilter === "PENDING"
              ? "bg-amber-600 text-white shadow-lg shadow-amber-600/30"
              : "bg-[#151D2A] border border-[#1E293B] text-amber-400 hover:bg-[#1E293B]"
          }`}
        >
          Pending Approval
        </button>

        <button
          onClick={() => setStatusFilter("APPROVED")}
          className={`px-4 py-2 rounded-lg text-xs font-semibold transition-colors ${
            statusFilter === "APPROVED"
              ? "bg-emerald-600 text-white shadow-lg shadow-emerald-600/30"
              : "bg-[#151D2A] border border-[#1E293B] text-emerald-400 hover:bg-[#1E293B]"
          }`}
        >
          Approved
        </button>

        <button
          onClick={() => setStatusFilter("REJECTED")}
          className={`px-4 py-2 rounded-lg text-xs font-semibold transition-colors ${
            statusFilter === "REJECTED"
              ? "bg-rose-600 text-white shadow-lg shadow-rose-600/30"
              : "bg-[#151D2A] border border-[#1E293B] text-rose-400 hover:bg-[#1E293B]"
          }`}
        >
          Rejected
        </button>
      </div>

      {/* Corrections List */}
      <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl overflow-hidden shadow-lg">
        {loading ? (
          <div className="flex h-64 items-center justify-center text-slate-400 text-xs">
            <div className="flex items-center gap-2">
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
              <span>Querying Correction Requests...</span>
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#1E293B]/60 text-slate-400 uppercase font-semibold text-[10px]">
                <tr>
                  <th className="p-3">Date</th>
                  <th className="p-3">Employee</th>
                  <th className="p-3">Requester</th>
                  <th className="p-3 text-center">Original Log</th>
                  <th className="p-3 text-center">Corrected Log</th>
                  <th className="p-3">Reason</th>
                  <th className="p-3 text-center">Status</th>
                  <th className="p-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1E293B] text-slate-200">
                {corrections.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="p-8 text-center text-slate-500">
                      No correction requests found matching filter.
                    </td>
                  </tr>
                ) : (
                  corrections.map((row) => {
                    const isSelf = user?.user_id === row.requested_by;
                    return (
                      <tr key={row.id} className="hover:bg-[#1E293B]/30 transition-colors">
                        <td className="p-3 font-mono text-slate-300">{row.attendance_date}</td>
                        <td className="p-3">
                          <div className="font-semibold text-slate-100">{row.employee_name}</div>
                          <div className="text-[10px] font-mono text-indigo-400">{row.employee_code}</div>
                        </td>
                        <td className="p-3">
                          <div className="text-slate-300 flex items-center gap-1">
                            <UserCheck className="h-3 w-3 text-indigo-400" />
                            <span>{row.requester_name}</span>
                          </div>
                          {isSelf && (
                            <span className="text-[9px] text-amber-400 font-mono font-bold">
                              (Self-Requested)
                            </span>
                          )}
                        </td>
                        <td className="p-3 text-center font-mono text-rose-400/80">
                          {formatTime(row.original_first_in)} → {formatTime(row.original_last_out)}
                        </td>
                        <td className="p-3 text-center font-mono text-emerald-400 font-bold">
                          {formatTime(row.corrected_first_in)} → {formatTime(row.corrected_last_out)}
                        </td>
                        <td className="p-3 text-slate-300 max-w-xs truncate">{row.reason}</td>
                        <td className="p-3 text-center">
                          {row.status === "PENDING" && (
                            <span className="px-2 py-0.5 rounded bg-amber-500/20 text-amber-400 border border-amber-500/30 font-mono text-[10px] font-bold">
                              PENDING
                            </span>
                          )}
                          {row.status === "APPROVED" && (
                            <span className="px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 font-mono text-[10px] font-bold">
                              APPROVED
                            </span>
                          )}
                          {row.status === "REJECTED" && (
                            <span className="px-2 py-0.5 rounded bg-rose-500/20 text-rose-400 border border-rose-500/30 font-mono text-[10px] font-bold">
                              REJECTED
                            </span>
                          )}
                        </td>
                        <td className="p-3 text-right">
                          {row.status === "PENDING" ? (
                            <div className="flex items-center justify-end gap-2">
                              <button
                                onClick={() => handleApprove(row.id, row.requested_by)}
                                disabled={actionLoading === row.id || isSelf}
                                title={isSelf ? "Self-approval prohibited" : "Approve Correction"}
                                className="px-2.5 py-1 rounded bg-emerald-600 hover:bg-emerald-500 disabled:opacity-30 text-white font-semibold text-[11px] transition-colors flex items-center gap-1"
                              >
                                <CheckCircle2 className="h-3 w-3" />
                                <span>Approve</span>
                              </button>

                              <button
                                onClick={() => handleReject(row.id)}
                                disabled={actionLoading === row.id}
                                className="px-2.5 py-1 rounded bg-rose-600 hover:bg-rose-500 disabled:opacity-30 text-white font-semibold text-[11px] transition-colors flex items-center gap-1"
                              >
                                <XCircle className="h-3 w-3" />
                                <span>Reject</span>
                              </button>
                            </div>
                          ) : (
                            <div className="text-[10px] text-slate-500 font-mono">
                              {row.approver_name ? `By ${row.approver_name}` : "--"}
                            </div>
                          )}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="p-4 rounded-xl bg-[#151D2A] border border-[#1E293B] flex items-center gap-3 text-xs text-amber-400/90">
        <AlertTriangle className="h-5 w-5 shrink-0 text-amber-400" />
        <span>
          <strong>Security Notice:</strong> Correction approvals trigger automatic recalculation of daily attendance records and session hours. Raw biometric events are preserved permanently in compliance with CAG audit policy. Requester cannot approve their own correction.
        </span>
      </div>
    </div>
  );
}
