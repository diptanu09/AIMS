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
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
          <span>Verifying AIMS Authentication...</span>
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
      color: "text-slate-400",
      show: hasPermission("employee.view") || hasPermission("attendance.view.section"),
    },
    {
      label: "Sections & Officers",
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
      label: "Report Generator",
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
      label: "Attendance Rules",
      href: "/reports",
      icon: FileText,
      color: "text-sky-400",
      show: hasPermission("reports.generate") || hasPermission("attendance.view.section"),
    },
    {
      label: "Scheduled Reports",
      href: "/admin/scheduled-reports",
      icon: Calendar,
      color: "text-indigo-400",
      show: hasPermission("report.generate") || hasPermission("user.manage"),
    },
    {
      label: "Attendance Import",
      href: "/import",
      icon: UploadCloud,
      color: "text-cyan-400",
      show: hasPermission("import.execute"),
    },
  ];

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-[#0B0F17]">
      {/* Sidebar Navigation */}
      <aside
        className={`${
          collapsed ? "w-20" : "w-64"
        } border-r border-[#1E293B] bg-[#151D2A] flex flex-col justify-between p-4 shrink-0 transition-all duration-200`}
      >
        <div className="overflow-y-auto">
          {/* Logo / Header */}
          <div className="flex items-center justify-between px-2 py-3 mb-6 border-b border-[#1E293B]">
            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-lg bg-indigo-600 flex items-center justify-center font-bold text-white shadow-lg shadow-indigo-600/30 shrink-0">
                A
              </div>
              {!collapsed && (
                <div>
                  <h1 className="font-bold tracking-wide text-sm text-slate-100">AIMS</h1>
                  <p className="text-[10px] text-slate-400 font-medium">ATTENDANCE INTELLIGENCE</p>
                </div>
              )}
            </div>
            <button
              onClick={() => setCollapsed(!collapsed)}
              className="p-1 rounded text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
            >
              {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
            </button>
          </div>

          {/* Operations Navigation Links */}
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
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-xs font-medium transition-colors ${
                      active
                        ? "bg-indigo-600/20 text-indigo-300 border border-indigo-500/30"
                        : "text-slate-400 hover:bg-[#1E293B] hover:text-slate-200"
                    }`}
                  >
                    <Icon className={`h-4 w-4 shrink-0 ${item.color}`} />
                    {!collapsed && <span>{item.label}</span>}
                  </Link>
                );
              })}
          </nav>
        </div>

        {/* Administration Links */}
        <div className="pt-4 border-t border-[#1E293B] space-y-1">
          {!collapsed && (
            <div className="px-3 pb-2 text-[10px] font-semibold text-slate-500 uppercase tracking-wider">
              Administration
            </div>
          )}
          <Link
            href="/admin/rules"
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
          >
            <Settings className="h-4 w-4 text-indigo-400 shrink-0" />
            {!collapsed && <span>Shift Rules</span>}
          </Link>

          <Link
            href="/admin/holidays"
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
          >
            <Calendar className="h-4 w-4 text-purple-400 shrink-0" />
            {!collapsed && <span>Holidays</span>}
          </Link>

          <Link
            href="/admin/leave"
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
          >
            <Clock className="h-4 w-4 text-sky-400 shrink-0" />
            {!collapsed && <span>Leave Authorization</span>}
          </Link>

          <Link
            href="/admin/users"
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
          >
            <UserCheck className="h-4 w-4 text-cyan-400 shrink-0" />
            {!collapsed && <span>Users & Sessions</span>}
          </Link>

          <Link
            href="/admin/audit"
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
          >
            <ShieldCheck className="h-4 w-4 text-emerald-400 shrink-0" />
            {!collapsed && <span>Audit Trail</span>}
          </Link>

          <Link
            href="/admin/settings"
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
          >
            <Sliders className="h-4 w-4 text-slate-400 shrink-0" />
            {!collapsed && <span>System Settings</span>}
          </Link>

          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-rose-400 hover:bg-rose-500/10 transition-colors mt-2"
          >
            <LogOut className="h-4 w-4 shrink-0" />
            {!collapsed && <span>Sign Out</span>}
          </button>
        </div>
      </aside>

      {/* Main Viewport */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Top App Header */}
        <header className="h-16 border-b border-[#1E293B] bg-[#151D2A] px-6 flex items-center justify-between shrink-0">
          <div>
            <span className="text-[10px] font-semibold text-indigo-400 uppercase tracking-wider">
              ORGANIZATION
            </span>
            <h2 className="text-sm font-semibold text-slate-100">Central Attendance Authority</h2>
          </div>

          <div className="flex items-center gap-4">
            <div className="text-right hidden sm:block">
              <p className="text-xs font-medium text-slate-200">{user.username}</p>
              <p className="text-[10px] text-indigo-400 font-mono">
                {user.roles.join(" • ") || "OPERATOR"}
              </p>
            </div>
            <div className="h-8 w-8 rounded-full bg-indigo-600/30 border border-indigo-500/50 flex items-center justify-center font-bold text-xs text-indigo-300">
              {user.username.substring(0, 2).toUpperCase()}
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-y-auto p-6 bg-[#0B0F17]">{children}</main>
      </div>
    </div>
  );
}
