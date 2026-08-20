import React from "react";
import Link from "next/link";
import { 
  LayoutDashboard, 
  Users, 
  Building2, 
  UploadCloud, 
  AlertTriangle, 
  CheckSquare, 
  FileText, 
  ShieldCheck, 
  Settings 
} from "lucide-react";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex h-screen w-screen overflow-hidden bg-[#0B0F17]">
      {/* Sidebar Navigation */}
      <aside className="w-64 border-r border-[#1E293B] bg-[#151D2A] flex flex-col justify-between p-4 shrink-0">
        <div>
          {/* Logo / Header */}
          <div className="flex items-center gap-3 px-2 py-3 mb-6 border-b border-[#1E293B]">
            <div className="h-9 w-9 rounded-lg bg-indigo-600 flex items-center justify-center font-bold text-white shadow-lg shadow-indigo-600/30">
              A
            </div>
            <div>
              <h1 className="font-bold tracking-wide text-sm text-slate-100">AIMS</h1>
              <p className="text-[10px] text-slate-400 font-medium">ATTENDANCE INTELLIGENCE</p>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="space-y-1">
            <Link
              href="/"
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-200 hover:bg-[#1E293B] hover:text-white transition-colors"
            >
              <LayoutDashboard className="h-4 w-4 text-indigo-400" />
              <span>Overview</span>
            </Link>

            <Link
              href="/employees"
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
            >
              <Users className="h-4 w-4 text-slate-400" />
              <span>Employees</span>
            </Link>

            <Link
              href="/sections"
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
            >
              <Building2 className="h-4 w-4 text-slate-400" />
              <span>Sections & Officers</span>
            </Link>

            <Link
              href="/import"
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
            >
              <UploadCloud className="h-4 w-4 text-cyan-400" />
              <span>Attendance Import</span>
            </Link>

            <Link
              href="/exceptions"
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
            >
              <AlertTriangle className="h-4 w-4 text-amber-400" />
              <span>Exception Center</span>
            </Link>

            <Link
              href="/corrections"
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
            >
              <CheckSquare className="h-4 w-4 text-emerald-400" />
              <span>Corrections</span>
            </Link>

            <Link
              href="/reports"
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
            >
              <FileText className="h-4 w-4 text-purple-400" />
              <span>Report Engine</span>
            </Link>
          </nav>
        </div>

        {/* Administration Links */}
        <div className="pt-4 border-t border-[#1E293B] space-y-1">
          <div className="px-3 pb-2 text-[11px] font-semibold text-slate-500 uppercase tracking-wider">
            Administration
          </div>
          <Link
            href="/admin/audit"
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
          >
            <ShieldCheck className="h-3.5 w-3.5" />
            <span>Audit Trail</span>
          </Link>
          <Link
            href="/admin/rules"
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:bg-[#1E293B] hover:text-slate-200 transition-colors"
          >
            <Settings className="h-3.5 w-3.5" />
            <span>Shift Rules</span>
          </Link>
        </div>
      </aside>

      {/* Main Viewport */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Top App Header */}
        <header className="h-16 border-b border-[#1E293B] bg-[#151D2A] px-6 flex items-center justify-between shrink-0">
          <div>
            <span className="text-xs font-medium text-slate-400">ORGANIZATION</span>
            <h2 className="text-sm font-semibold text-slate-100">Central Attendance Authority</h2>
          </div>

          <div className="flex items-center gap-4">
            <div className="text-right">
              <p className="text-xs font-medium text-slate-200">System Admin</p>
              <p className="text-[10px] text-slate-400">ADMINISTRATOR</p>
            </div>
            <div className="h-8 w-8 rounded-full bg-slate-700 border border-slate-600 flex items-center justify-center font-bold text-xs text-slate-200">
              SA
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-y-auto p-6 bg-[#0B0F17]">
          {children}
        </main>
      </div>
    </div>
  );
}
