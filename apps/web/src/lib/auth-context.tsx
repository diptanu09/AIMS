"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { User } from "../types/api";
import { api } from "./api";

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (username: string, password_hash: string) => Promise<void>;
  logout: () => Promise<void>;
  hasPermission: (permission: string) => boolean;
  canAccessSection: (sectionId: string) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    api
      .getMe()
      .then((u) => setUser(u))
      .catch(() => setUser(null))
      .finally(() => setLoading(false));
  }, []);

  const login = async (username: string, password_hash: string) => {
    const res = await api.login({ username, password_hash });
    setUser(res.user);
  };

  const logout = async () => {
    await api.logout();
    setUser(null);
  };

  const hasPermission = (permission: string) => {
    if (!user) return false;
    if (user.roles.includes("SUPER_ADMIN") || user.permissions.includes("all")) return true;
    return user.permissions.includes(permission);
  };

  const canAccessSection = (sectionId: string) => {
    if (!user) return false;
    if (user.roles.includes("SUPER_ADMIN") || user.permissions.includes("attendance.view.all"))
      return true;
    return user.section_ids.includes(sectionId);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        loading,
        login,
        logout,
        hasPermission,
        canAccessSection,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
