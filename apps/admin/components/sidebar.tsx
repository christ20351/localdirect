"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "./auth-context";
import { apiRequest } from "@/lib/api";

const NAV_ITEMS = [
  {
    name: "Tableau de Bord",
    href: "/",
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
      </svg>
    ),
  },
  {
    name: "Modération Biens",
    href: "/biens",
    badgeKey: "biens",
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
      </svg>
    ),
  },
  {
    name: "Documents & KYC",
    href: "/documents",
    badgeKey: "documents",
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
      </svg>
    ),
  },
  {
    name: "Visites Signalées",
    href: "/visites",
    badgeKey: "visites",
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>
    ),
  },
  {
    name: "Villes & Quartiers",
    href: "/villes",
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
      </svg>
    ),
  },
  {
    name: "Candidatures",
    href: "/candidatures",
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
      </svg>
    ),
  },
  {
    name: "Baux",
    href: "/baux",
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 17v-2a4 4 0 014-4h4m0 0l-3-3m3 3l-3 3M4 5h11a2 2 0 012 2v10a2 2 0 01-2 2H4a2 2 0 01-2-2V7a2 2 0 012-2z" />
      </svg>
    ),
  },
  {
    name: "Journal d'Audit",
    href: "/audit",
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  },
];

const BADGES_SEEN_STORAGE_KEY = "locadirect_admin_badges_seen";

export function Sidebar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();
  const [badges, setBadges] = useState<Record<string, number>>({});
  // Compte "vu" par section : tant que le compte réel ne dépasse pas cette valeur,
  // le badge reste masqué — visiter l'onglet marque ses éléments actuels comme vus.
  const [seen, setSeen] = useState<Record<string, number>>({});

  useEffect(() => {
    try {
      const stored = localStorage.getItem(BADGES_SEEN_STORAGE_KEY);
      if (stored) setSeen(JSON.parse(stored));
    } catch {
      // localStorage indisponible ou contenu corrompu : on repart d'un compteur vide.
    }
  }, []);

  useEffect(() => {
    if (!user) return;

    let cancelled = false;
    async function loadBadges() {
      const [biens, documents, visites] = await Promise.allSettled([
        apiRequest<unknown[]>("/admin/biens?statut=EN_VERIFICATION"),
        apiRequest<unknown[]>("/admin/documents?statut=EN_ATTENTE"),
        apiRequest<unknown[]>("/admin/visites"),
      ]);
      if (cancelled) return;
      setBadges({
        biens: biens.status === "fulfilled" ? biens.value.length : 0,
        documents: documents.status === "fulfilled" ? documents.value.length : 0,
        visites: visites.status === "fulfilled" ? visites.value.length : 0,
      });
    }

    loadBadges();
    const interval = setInterval(loadBadges, 60_000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [user]);

  // Dès qu'on est sur la page d'une section à badge, on marque son compte courant
  // comme "vu" — le badge disparaît immédiatement et ne réapparaît que si de
  // nouveaux éléments arrivent après la visite.
  useEffect(() => {
    const current = NAV_ITEMS.find((item) => item.href === pathname);
    if (!current?.badgeKey) return;
    const count = badges[current.badgeKey];
    if (count === undefined) return;

    setSeen((prev) => {
      if (prev[current.badgeKey!] === count) return prev;
      const next = { ...prev, [current.badgeKey!]: count };
      try {
        localStorage.setItem(BADGES_SEEN_STORAGE_KEY, JSON.stringify(next));
      } catch {
        // Pas grave si la persistance échoue : le masquage reste valable pour la session.
      }
      return next;
    });
  }, [pathname, badges]);

  if (!user) return null;

  return (
    <aside className="w-64 bg-slate-900 text-slate-100 flex flex-col min-h-screen border-r border-slate-800 shrink-0">
      {/* Brand Header */}
      <div className="p-6 border-b border-slate-800 flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-500 to-teal-400 flex items-center justify-center font-bold text-slate-950 text-xl shadow-lg shadow-emerald-500/20">
          LD
        </div>
        <div>
          <h1 className="font-bold text-lg leading-tight tracking-tight text-white">LocaDirect CM</h1>
          <span className="text-xs font-semibold text-emerald-400 uppercase tracking-widest bg-emerald-500/10 px-2 py-0.5 rounded-full inline-block mt-0.5">
            Backoffice Admin
          </span>
        </div>
      </div>

      {/* Navigation Links */}
      <nav className="flex-1 p-4 space-y-1.5 overflow-y-auto">
        <div className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider px-3 mb-2">
          Menu Principal
        </div>
        {NAV_ITEMS.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 ${
                isActive
                  ? "bg-emerald-500 text-slate-950 font-semibold shadow-md shadow-emerald-500/20"
                  : "text-slate-300 hover:bg-slate-800/80 hover:text-white"
              }`}
            >
              <span className={isActive ? "text-slate-950" : "text-slate-400"}>
                {item.icon}
              </span>
              <span className="flex-1">{item.name}</span>
              {item.badgeKey && (badges[item.badgeKey] ?? 0) > (seen[item.badgeKey] ?? 0) && (
                <span
                  className={`text-[11px] font-bold px-2 py-0.5 rounded-full ${
                    isActive ? "bg-slate-950 text-emerald-400" : "bg-rose-500/20 text-rose-400"
                  }`}
                >
                  {badges[item.badgeKey]}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      {/* User Info & Logout */}
      <div className="p-4 border-t border-slate-800 bg-slate-950/40">
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-9 h-9 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center font-semibold text-sm text-emerald-400 shrink-0">
              {user.nomComplet ? user.nomComplet.charAt(0).toUpperCase() : "A"}
            </div>
            <div className="min-w-0">
              <p className="text-sm font-medium text-white truncate">
                {user.nomComplet || user.telephone}
              </p>
              <p className="text-xs text-slate-400 truncate">
                {user.roles.join(" · ")}
              </p>
            </div>
          </div>
          <button
            onClick={logout}
            title="Se déconnecter"
            className="p-2 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
          </button>
        </div>
      </div>
    </aside>
  );
}
