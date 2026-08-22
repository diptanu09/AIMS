import "@/styles/globals.css";
import React from "react";
import { AuthProvider } from "../lib/auth-context";

export const metadata = {
  title: "AIMS — Attendance Intelligence & Management System",
  description: "Enterprise Attendance Processing, Employee Tracking & Management Dashboard",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased bg-[#0B0F17] text-slate-100 min-h-screen">
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
