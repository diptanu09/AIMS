"use client";

import React, { useState } from "react";
import { Users, ShieldCheck, Key, LogOut } from "lucide-react";

export default function UsersPage() {
  const [users] = useState([
    {
      id: "u1",
      username: "admin",
      roles: ["SUPER_ADMIN"],
      status: "ACTIVE",
      sections: ["All Sections"],
      lastLogin: "22-Aug-2026 14:58",
    },
    {
      id: "u2",
      username: "bo_accounts",
      roles: ["BO"],
      status: "ACTIVE",
      sections: ["Accounts Section"],
      lastLogin: "22-Aug-2026 13:42",
    },
    {
      id: "u3",
      username: "aao_pension",
      roles: ["AAO"],
      status: "ACTIVE",
      sections: ["Pension Section"],
      lastLogin: "21-Aug-2026 16:10",
    },
  ]);

  const handleRevokeSession = (username: string) => {
    alert(`Session for operator '${username}' revoked successfully.`);
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="pb-2 border-b border-[#1E293B]">
        <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
          <Users className="h-6 w-6 text-indigo-400" />
          <span>User & Session Management</span>
        </h1>
        <p className="text-xs text-slate-400">
          Operator accounts, RBAC roles, section scope permissions & active session revocation
        </p>
      </div>

      {/* Users Table */}
      <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl overflow-hidden shadow-lg">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#1E293B]/60 text-slate-400 uppercase font-semibold text-[10px]">
              <tr>
                <th className="p-3">Operator Username</th>
                <th className="p-3">Assigned Roles</th>
                <th className="p-3">Section Scope</th>
                <th className="p-3">Last Login</th>
                <th className="p-3 text-center">Status</th>
                <th className="p-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1E293B] text-slate-200">
              {users.map((u) => (
                <tr key={u.id} className="hover:bg-[#1E293B]/30 transition-colors">
                  <td className="p-3 font-semibold text-slate-100">{u.username}</td>
                  <td className="p-3 font-mono font-bold text-indigo-400">
                    {u.roles.join(", ")}
                  </td>
                  <td className="p-3 text-slate-300">{u.sections.join(", ")}</td>
                  <td className="p-3 font-mono text-slate-400">{u.lastLogin}</td>
                  <td className="p-3 text-center">
                    <span className="px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 font-mono text-[10px] font-bold">
                      {u.status}
                    </span>
                  </td>
                  <td className="p-3 text-right">
                    <button
                      onClick={() => handleRevokeSession(u.username)}
                      className="px-2.5 py-1 rounded bg-rose-600/20 text-rose-400 hover:bg-rose-600/30 border border-rose-500/30 font-semibold text-[11px] transition-colors inline-flex items-center gap-1"
                    >
                      <LogOut className="h-3 w-3" />
                      <span>Revoke Session</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
