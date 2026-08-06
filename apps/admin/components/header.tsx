"use client";

import React from "react";
import { useAuth } from "./auth-context";

export function Header({ title }: { title: string }) {
  const { user } = useAuth();

  return (
    <header className="h-16 bg-slate-900/50 backdrop-blur-md border-b border-slate-800 px-8 flex items-center justify-between sticky top-0 z-10">
      <div>
        <h2 className="text-xl font-bold text-white tracking-tight">{title}</h2>
      </div>

      <div className="flex items-center gap-4">
        {/* Status Indicator */}
        <div className="flex items-center gap-2 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 px-3 py-1.5 rounded-full text-xs font-medium">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
          <span>API NestJS Connectée</span>
        </div>

        {/* User Role Badge */}
        {user && (
          <div className="text-xs font-semibold text-slate-300 bg-slate-800 border border-slate-700 px-3 py-1.5 rounded-lg">
            {user.roles.includes("ADMIN") ? "Administrateur Système" : "Modérateur Staff"}
          </div>
        )}
      </div>
    </header>
  );
}
