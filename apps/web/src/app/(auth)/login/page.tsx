"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { Lock, User as UserIcon, ShieldCheck, AlertCircle, Eye, EyeOff, Sparkles, Building2 } from "lucide-react";
import { useAuth } from "../../../lib/auth-context";

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuth();
  const [username, setUsername] = useState("admin");
  const [password, setPassword] = useState("Admin@Aims123!");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      await login(username, password);
      router.push("/");
    } catch (err: any) {
      setError(err.message || "Failed to authenticate");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative flex min-h-screen items-center justify-center bg-[#0B0F17] overflow-hidden p-4">
      {/* Dynamic Background Glow Orbs */}
      <div className="absolute top-1/4 left-1/3 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-indigo-600/15 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/3 translate-x-1/2 translate-y-1/2 w-96 h-96 bg-purple-600/10 rounded-full blur-3xl pointer-events-none" />

      {/* Main Glass Login Card */}
      <div className="relative w-full max-w-md bg-[#151D2A]/90 backdrop-blur-xl border border-slate-800/80 rounded-2xl p-8 shadow-2xl shadow-indigo-950/50">
        
        {/* Brand Header */}
        <div className="flex flex-col items-center text-center mb-8">
          <div className="relative mb-4">
            <div className="h-14 w-14 rounded-2xl bg-gradient-to-br from-indigo-500 via-indigo-600 to-purple-600 flex items-center justify-center font-extrabold text-white text-2xl shadow-lg shadow-indigo-500/30">
              A
            </div>
            <div className="absolute -bottom-1 -right-1 h-5 w-5 bg-emerald-500 rounded-full border-2 border-[#151D2A] flex items-center justify-center">
              <Sparkles className="h-3 w-3 text-white" />
            </div>
          </div>

          <h1 className="text-2xl font-bold tracking-tight text-white">
            AIMS <span className="text-indigo-400 font-normal">Central Sign In</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
            <Building2 className="h-3.5 w-3.5 text-indigo-400" />
            Attendance Intelligence & Management System
          </p>
        </div>

        {/* Error Alert */}
        {error && (
          <div className="mb-6 p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/30 flex items-start gap-3 text-rose-300 text-xs shadow-sm">
            <AlertCircle className="h-4 w-4 text-rose-400 shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="font-semibold">Authentication Error</p>
              <p className="text-[11px] text-rose-400/90 mt-0.5">{error}</p>
            </div>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
              Username / Operator ID
            </label>
            <div className="relative">
              <UserIcon className="absolute left-3.5 top-3.5 h-4 w-4 text-slate-400" />
              <input
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="w-full bg-[#0B0F17]/90 border border-slate-800 rounded-xl pl-10 pr-4 py-3 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/20 transition-all font-mono"
                placeholder="Enter username"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
              Password
            </label>
            <div className="relative">
              <Lock className="absolute left-3.5 top-3.5 h-4 w-4 text-slate-400" />
              <input
                type={showPassword ? "text" : "password"}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-[#0B0F17]/90 border border-slate-800 rounded-xl pl-10 pr-10 py-3 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/20 transition-all font-mono"
                placeholder="Enter password"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3.5 top-3.5 text-slate-400 hover:text-slate-200 transition-colors"
              >
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-gradient-to-r from-indigo-600 via-indigo-500 to-purple-600 hover:from-indigo-500 hover:to-purple-500 disabled:opacity-50 text-white font-semibold text-xs py-3.5 rounded-xl transition-all shadow-lg shadow-indigo-600/30 flex items-center justify-center gap-2 mt-6 active:scale-[0.99]"
          >
            {loading ? (
              <div className="flex items-center gap-2">
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                <span>Authenticating...</span>
              </div>
            ) : (
              <>
                <ShieldCheck className="h-4 w-4 text-emerald-300" />
                <span>Sign In to Dashboard</span>
              </>
            )}
          </button>
        </form>

        {/* Security Footer */}
        <div className="mt-8 pt-5 border-t border-slate-800/80 text-center">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-900/60 border border-slate-800 text-[10px] text-slate-400 font-mono">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />
            Argon2id + SHA-256 Revocable Session Auth
          </div>
        </div>
      </div>
    </div>
  );
}
