"use client";

import React, { useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  Building2,
  UploadCloud,
  AlertTriangle,
  FileText,
  ShieldCheck,
  Settings,
  LogOut,
  ChevronLeft,
  ChevronRight,
  Clock,
  CheckSquare,
  Calendar,
  UserCheck,
  Sliders,
  FileSpreadsheet,
  Layers,
  Sparkles,
  Activity,
  Bell,
  Search,
} from "lucide-react";
import { useAuth } from "../../lib/auth-context";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, loading, logout, hasPermission } = useAuth();
  const [collapsed, setCollapsed] = useState(false);

  if (loading) {
    return (
      <div className="flex h-screen w-screen items-center justify-center bg-[#0B0F17] text-slate-300 text-xs">
        <div className="flex flex-col items-center gap-3">
          <div className="h-9 w-9 animate-spin rounded-full border-3 border-indigo-500 border-t-transparent shadow-lg shadow-indigo-500/30" />
          <span className="font-mono text-slate-400">Verifying AIMS Security Tokens...</span>
        </div>
      </div>
    );
  }

  if (!user) {
    if (typeof window !== "undefined") {
      router.push("/login");
    }
    return null;
  }

  const handleLogout = async () => {
    await logout();
    router.push("/login");
  };

  const navItems = [
    {
      label: "Overview",
      href: "/",
      icon: LayoutDashboard,
      color: "text-indigo-400",
      show: true,
    },
    {
      label: "Today's Attendance",
      href: "/attendance",
      icon: Clock,
      color: "text-emerald-400",
      show: true,
    },
    {
      label: "Employees",
      href: "/employees",
      icon: Users,
      color: "text-sky-400",
      show: hasPermission("employee.view") || hasPermission("attendance.view.section"),
    },
    {
      label: "Sections & Hierarchy",
      href: "/sections",
      icon: Building2,
      color: "text-purple-400",
      show: hasPermission("section.manage") || hasPermission("attendance.view.all"),
    },
    {
      label: "Exception Center",
      href: "/exceptions",
      icon: AlertTriangle,
      color: "text-amber-400",
      show: true,
    },
    {
      label: "Corrections Workflow",
      href: "/corrections",
      icon: CheckSquare,
      color: "text-emerald-400",
      show: true,
    },
    {
      label: "Report Engine",
      href: "/reports",
      icon: FileSpreadsheet,
      color: "text-blue-400",
      show: hasPermission("report.generate"),
    },
    {
      label: "Pilot Validation",
      href: "/pilot",
      icon: Layers,
      color: "text-cyan-400",
      show: true,
    },
    {
      label: "Scheduled Reports",
      href: "/admin/scheduled-reports",
      icon: Calendar,
      color: "text-indigo-400",
      show: hasPermission("report.generate") || hasPermission("user.manage"),
    },
    {
      label: "Biometric Ingestion",
      href: "/import",
      icon: UploadCloud,
      color: "text-cyan-400",
      show: hasPermission("import.execute"),
    },
  ];

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-[#0B0F17] text-slate-100 font-sans">
      {/* Sidebar Navigation */}
      <aside
        className={`${
          collapsed ? "w-20" : "w-64"
        } border-r border-slate-800/80 bg-[#151D2A] flex flex-col justify-between p-3.5 shrink-0 transition-all duration-300 relative z-20 shadow-2xl`}
      >
        <div className="overflow-y-auto">
          {/* Logo / Header */}
          <div className="flex items-center justify-between px-2 py-3 mb-4 border-b border-slate-800/80">
            <div className="flex items-center gap-3 overflow-hidden">
              <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-indigo-500 via-indigo-600 to-purple-600 flex items-center justify-center font-extrabold text-white text-lg shadow-lg shadow-indigo-500/30 shrink-0">
                A
              </div>
              {!collapsed && (
                <div className="truncate">
                  <div className="flex items-center gap-1.5">
                    <h1 className="font-bold tracking-wide text-sm text-white">AIMS</h1>
                    <span className="px-1.5 py-0.5 rounded bg-indigo-500/20 text-indigo-300 font-mono text-[9px] font-semibold border border-indigo-500/30">
                      v1.0
                    </span>
                  </div>
                  <p className="text-[10px] text-slate-400 font-medium tracking-wider truncate uppercase">
                    ATTENDANCE SYSTEM
                  </p>
                </div>
              )}
            </div>
            <button
              onClick={() => setCollapsed(!collapsed)}
              className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-800 hover:text-slate-200 transition-colors"
              title={collapsed ? "Expand sidebar" : "Collapse sidebar"}
            >
              {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
            </button>
          </div>

          {/* Operations Navigation Links */}
          <div className="space-y-1">
            {!collapsed && (
              <div className="px-3 py-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                Operations
              </div>
            )}
            <nav className="space-y-1">
              {navItems
                .filter((item) => item.show)
                .map((item) => {
                  const Icon = item.icon;
                  const active = pathname === item.href;
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all duration-150 relative ${
                        active
                          ? "bg-gradient-to-r from-indigo-600/30 to-purple-600/20 text-indigo-200 border border-indigo-500/40 shadow-sm"
                          : "text-slate-400 hover:bg-slate-800/60 hover:text-slate-200"
                      }`}
                    >
                      {active && (
                        <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-5 bg-indigo-500 rounded-r-full shadow-glow" />
                      )}
                      <Icon className={`h-4 w-4 shrink-0 ${item.color}`} />
                      {!collapsed && <span className="truncate">{item.label}</span>}
                    </Link>
                  );
                })}
            </nav>
          </div>
        </div>

        {/* Administration Links */}
        <div className="pt-3 border-t border-slate-800/80 space-y-1">
          {!collapsed && (
            <div className="px-3 pb-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-widest">
              Governance
            </div>
          )}
          <Link
            href="/admin/rules"
            className="flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-medium text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 transition-colors"
          >
            <Settings className="h-4 w-4 text-indigo-400 shrink-0" />
            {!collapsed && <span>Shift Rules</span>}
          </Link>

          <Link
            href="/admin/holidays"
            className="flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-medium text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 transition-colors"
          >
            <Calendar className="h-4 w-4 text-purple-400 shrink-0" />
            {!collapsed && <span>Holidays</span>}
          </Link>

          <Link
            href="/admin/leave"
            className="flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-medium text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 transition-colors"
          >
            <Clock className="h-4 w-4 text-sky-400 shrink-0" />
            {!collapsed && <span>Leave Module</span>}
          </Link>

          <Link
            href="/admin/users"
            className="flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-medium text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 transition-colors"
          >
            <UserCheck className="h-4 w-4 text-cyan-400 shrink-0" />
            {!collapsed && <span>Users & Roles</span>}
          </Link>

          <Link
            href="/admin/audit"
            className="flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-medium text-slate-400 hover:bg-slate-800/60 hover:text-slate-200 transition-colors"
          >
            <ShieldCheck className="h-4 w-4 text-emerald-400 shrink-0" />
            {!collapsed && <span>Audit Trail</span>}
          </Link>

          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-semibold text-rose-400 hover:bg-rose-500/10 transition-colors mt-2"
          >
            <LogOut className="h-4 w-4 shrink-0" />
            {!collapsed && <span>Sign Out</span>}
          </button>
        </div>
      </aside>

      {/* Main Viewport */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Top App Header */}
        <header className="h-16 border-b border-slate-800/80 bg-[#151D2A]/80 backdrop-blur-md px-6 flex items-center justify-between shrink-0 z-10">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-[11px] font-mono text-emerald-400 font-medium uppercase tracking-wider">
                LIVE PRODUCTION
              </span>
            </div>
            <div className="h-4 w-px bg-slate-800" />
            <h2 className="text-sm font-semibold text-slate-200 hidden md:block">
              CAG Central Attendance Authority
            </h2>
          </div>

          <div className="flex items-center gap-4">
            {/* Status Pills */}
            <div className="hidden sm:flex items-center gap-2 px-3 py-1 rounded-full bg-slate-900/80 border border-slate-800 text-xs">
              <Activity className="h-3.5 w-3.5 text-indigo-400" />
              <span className="text-[11px] text-slate-300 font-mono">Engine: Operational</span>
            </div>

            {/* Profile Avatar */}
            <div className="flex items-center gap-3 pl-2 border-l border-slate-800">
              <div className="text-right hidden sm:block">
                <p className="text-xs font-semibold text-slate-100">{user.username}</p>
                <p className="text-[10px] text-indigo-400 font-mono font-medium">
                  {user.roles.join(" • ") || "SUPER_ADMIN"}
                </p>
              </div>
              <div className="h-9 w-9 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 p-0.5 shadow-md shadow-indigo-500/20">
                <div className="h-full w-full rounded-full bg-[#151D2A] flex items-center justify-center font-bold text-xs text-indigo-300">
                  {user.username.substring(0, 2).toUpperCase()}
                </div>
              </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-y-auto p-6 bg-[#0B0F17]">{children}</main>
      </div>
    </div>
  );
}
