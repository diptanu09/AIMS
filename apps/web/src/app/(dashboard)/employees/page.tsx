"use client";

import React, { useEffect, useState } from "react";
import { Users, Plus, Search, Filter, RefreshCw, UserCheck, UserX, ArrowRightLeft } from "lucide-react";
import { api } from "../../../lib/api";
import { Employee, SectionSummary, AttendanceRule } from "../../../types/api";

export default function EmployeesPage() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [sectionsList, setSectionsList] = useState<Array<{ id: string; code: string; name: string }>>([]);
  const [rules, setRules] = useState<AttendanceRule[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  // Filters
  const [search, setSearch] = useState("");
  const [sectionFilter, setSectionFilter] = useState("");

  // Modals
  const [showAddModal, setShowAddModal] = useState(false);
  const [showTransferModal, setShowTransferModal] = useState<Employee | null>(null);

  // Form State
  const [empCode, setEmpCode] = useState("");
  const [deviceId, setDeviceId] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [selectedSection, setSelectedSection] = useState("");
  const [selectedDesignation, setSelectedDesignation] = useState("");
  const [selectedRule, setSelectedRule] = useState("");
  const [newSectionId, setNewSectionId] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const loadData = async () => {
    setLoading(true);
    try {
      const [empRes, secList, ruleRes] = await Promise.all([
        api.listEmployees({ search: search || undefined, section_id: sectionFilter || undefined, page_size: 200 }),
        api.listSections().catch(() => []),
        api.listRules().catch(() => []),
      ]);
      setEmployees(empRes.items);
      setTotal(empRes.total);
      setSectionsList(secList);
      setRules(ruleRes);

      if (secList.length > 0) {
        setSelectedSection(secList[0].id);
        setNewSectionId(secList[0].id);
      }
      if (ruleRes.length > 0) {
        setSelectedRule(ruleRes[0].id);
      }
    } catch (err) {
      console.error("Failed to load employee master:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [search, sectionFilter]);

  const handleCreateEmployee = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await api.createEmployee({
        employee_code: empCode,
        attendance_device_user_id: deviceId,
        first_name: firstName,
        last_name: lastName || undefined,
        section_id: selectedSection,
        designation_id: selectedDesignation || "00000000-0000-0000-0000-000000000000",
        attendance_rule_id: selectedRule,
      });
      setShowAddModal(false);
      setEmpCode("");
      setDeviceId("");
      setFirstName("");
      setLastName("");
      await loadData();
    } catch (err: any) {
      alert(err.message || "Failed to create employee");
    } finally {
      setSubmitting(false);
    }
  };

  const handleTransfer = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!showTransferModal) return;

    setSubmitting(true);
    try {
      await api.transferEmployee(showTransferModal.id, newSectionId);
      setShowTransferModal(null);
      await loadData();
    } catch (err: any) {
      alert(err.message || "Failed to transfer employee section");
    } finally {
      setSubmitting(false);
    }
  };

  const openTransferModal = (emp: Employee) => {
    setShowTransferModal(emp);
    setNewSectionId(emp.section_id);
  };

  const handleToggleStatus = async (emp: Employee) => {
    try {
      if (emp.is_active) {
        await api.deactivateEmployee(emp.id);
      } else {
        await api.activateEmployee(emp.id);
      }
      await loadData();
    } catch (err: any) {
      alert(err.message || "Failed to toggle status");
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#1E293B]">
        <div>
          <h1 className="text-2xl font-bold text-slate-100 tracking-tight flex items-center gap-2">
            <Users className="h-6 w-6 text-indigo-400" />
            <span>Employee Master Administration</span>
          </h1>
          <p className="text-xs text-slate-400">
            Manage employee profiles, section assignments, biometric device IDs & shift rules ({total} Total Employees)
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs px-4 py-2.5 rounded-lg transition-colors shadow-lg shadow-indigo-600/30 flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          <span>Add Employee</span>
        </button>
      </div>

      {/* Filter Controls */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-[#151D2A] border border-[#1E293B] p-4 rounded-xl">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search employee name or code..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg pl-9 pr-4 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500"
          />
        </div>

        <div className="flex items-center gap-3 w-full sm:w-auto">
          <div className="flex items-center gap-2 text-xs text-slate-400">
            <Filter className="h-4 w-4" />
            <span>Section:</span>
          </div>
          <select
            value={sectionFilter}
            onChange={(e) => setSectionFilter(e.target.value)}
            className="bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-indigo-500"
          >
            <option value="">All Sections ({sectionsList.length})</option>
            {sectionsList.map((sec) => (
              <option key={sec.id} value={sec.id}>
                {sec.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Employee List Table */}
      <div className="bg-[#151D2A] border border-[#1E293B] rounded-xl overflow-hidden shadow-lg">
        {loading ? (
          <div className="flex h-64 items-center justify-center text-slate-400 text-xs">
            <div className="flex items-center gap-2">
              <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
              <span>Querying Employee Master...</span>
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#1E293B]/60 text-slate-400 uppercase font-semibold text-[10px]">
                <tr>
                  <th className="p-3 text-center w-12">#</th>
                  <th className="p-3">Employee</th>
                  <th className="p-3 text-center">Attendance Device ID</th>
                  <th className="p-3">Section</th>
                  <th className="p-3">Designation</th>
                  <th className="p-3 text-center">Status</th>
                  <th className="p-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1E293B] text-slate-200">
                {employees.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="p-8 text-center text-slate-500">
                      No employee records found matching query.
                    </td>
                  </tr>
                ) : (
                  employees.map((emp, index) => (
                    <tr key={emp.id} className="hover:bg-[#1E293B]/30 transition-colors">
                      <td className="p-3 text-center font-mono text-slate-500 text-[11px] font-semibold">
                        {index + 1}
                      </td>
                      <td className="p-3">
                        <div className="font-semibold text-slate-100">
                          {emp.first_name} {emp.last_name || ""}
                        </div>
                        <div className="text-[10px] font-mono text-indigo-400">{emp.employee_code}</div>
                      </td>
                      <td className="p-3 text-center font-mono font-bold text-cyan-400">
                        {emp.attendance_device_user_id}
                      </td>
                      <td className="p-3 text-slate-300 font-medium">{emp.section_name || "Assigned Section"}</td>
                      <td className="p-3 text-slate-400">{emp.designation_name || "Staff"}</td>
                      <td className="p-3 text-center">
                        {emp.is_active ? (
                          <span className="px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 font-mono text-[10px] font-bold">
                            ACTIVE
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded bg-rose-500/20 text-rose-400 border border-rose-500/30 font-mono text-[10px] font-bold">
                            INACTIVE
                          </span>
                        )}
                      </td>
                      <td className="p-3 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => openTransferModal(emp)}
                            className="p-1.5 rounded bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-300 border border-indigo-500/30 transition-colors flex items-center gap-1 text-[11px] px-2"
                            title="Update Section Assignment"
                          >
                            <ArrowRightLeft className="h-3.5 w-3.5" />
                            <span>Update Section</span>
                          </button>
                          <button
                            onClick={() => handleToggleStatus(emp)}
                            className={`p-1.5 rounded transition-colors border ${
                              emp.is_active
                                ? "bg-rose-500/10 text-rose-400 border-rose-500/30 hover:bg-rose-500/20"
                                : "bg-emerald-500/10 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/20"
                            }`}
                            title={emp.is_active ? "Deactivate Account" : "Activate Account"}
                          >
                            {emp.is_active ? (
                              <UserX className="h-3.5 w-3.5" />
                            ) : (
                              <UserCheck className="h-3.5 w-3.5" />
                            )}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Add Employee Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center p-4 z-50">
          <div className="bg-[#151D2A] border border-[#1E293B] rounded-2xl p-6 w-full max-w-md space-y-4 shadow-2xl">
            <h2 className="text-lg font-bold text-slate-100">Add New Employee Profile</h2>

            <form onSubmit={handleCreateEmployee} className="space-y-3">
              <div>
                <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Employee Code
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. EMP00123"
                  value={empCode}
                  onChange={(e) => setEmpCode(e.target.value)}
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 focus:outline-none focus:border-indigo-500 font-mono"
                />
              </div>

              <div>
                <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Biometric Attendance Device User ID
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. 1001"
                  value={deviceId}
                  onChange={(e) => setDeviceId(e.target.value)}
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 focus:outline-none focus:border-indigo-500 font-mono text-cyan-400 font-bold"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    First Name
                  </label>
                  <input
                    type="text"
                    required
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                    Last Name
                  </label>
                  <input
                    type="text"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-100 focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Section Assignment
                </label>
                <select
                  value={selectedSection}
                  onChange={(e) => setSelectedSection(e.target.value)}
                  required
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none"
                >
                  {sectionsList.map((sec) => (
                    <option key={sec.id} value={sec.id}>
                      {sec.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">
                  Shift Attendance Rule
                </label>
                <select
                  value={selectedRule}
                  onChange={(e) => setSelectedRule(e.target.value)}
                  required
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none"
                >
                  {rules.map((r) => (
                    <option key={r.id} value={r.id}>
                      {r.name} ({r.shift_start} - {r.shift_end})
                    </option>
                  ))}
                </select>
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
                  disabled={submitting}
                  className="bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs px-4 py-2 rounded-lg transition-colors shadow-lg shadow-indigo-600/30"
                >
                  {submitting ? "Saving..." : "Save Employee"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Transfer Section Modal */}
      {showTransferModal && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center p-4 z-50">
          <div className="bg-[#151D2A] border border-[#1E293B] rounded-2xl p-6 w-full max-w-sm space-y-4 shadow-2xl">
            <h2 className="text-sm font-bold text-slate-100">
              Update Section: {showTransferModal.first_name} {showTransferModal.last_name || ""} ({showTransferModal.employee_code})
            </h2>

            <form onSubmit={handleTransfer} className="space-y-4">
              <div>
                <label className="block text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-2">
                  Select New Section
                </label>
                <select
                  value={newSectionId}
                  onChange={(e) => setNewSectionId(e.target.value)}
                  required
                  className="w-full bg-[#0B0F17] border border-[#1E293B] rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none"
                >
                  {sectionsList.map((sec) => (
                    <option key={sec.id} value={sec.id}>
                      {sec.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowTransferModal(null)}
                  className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-400 hover:text-slate-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs px-4 py-2 rounded-lg transition-colors shadow-lg shadow-indigo-600/30"
                >
                  {submitting ? "Transferring..." : "Confirm Transfer"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
