"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "@/components/sidebar";
import { Header } from "@/components/header";
import { apiRequest } from "@/lib/api";
import Link from "next/link";

interface DashboardStats {
  biensEnAttente: number;
  documentsEnAttente: number;
  totalAnnonces: number;
  villesOuvertes: number;
}

const STATUTS_CATALOGUE = ["EN_VERIFICATION", "DISPONIBLE", "RESERVE", "LOUE", "SUSPENDU", "REJETE"] as const;
type StatutCatalogue = (typeof STATUTS_CATALOGUE)[number];

const STATUT_STYLES: Record<StatutCatalogue, { label: string; text: string; bg: string; border: string }> = {
  EN_VERIFICATION: { label: "À Vérifier", text: "text-amber-400", bg: "bg-amber-500/10", border: "border-amber-500/20" },
  DISPONIBLE: { label: "Disponible", text: "text-emerald-400", bg: "bg-emerald-500/10", border: "border-emerald-500/20" },
  RESERVE: { label: "Réservé", text: "text-blue-400", bg: "bg-blue-500/10", border: "border-blue-500/20" },
  LOUE: { label: "Loué", text: "text-teal-400", bg: "bg-teal-500/10", border: "border-teal-500/20" },
  SUSPENDU: { label: "Suspendu (litige)", text: "text-rose-400", bg: "bg-rose-500/10", border: "border-rose-500/20" },
  REJETE: { label: "Rejeté", text: "text-slate-400", bg: "bg-slate-500/10", border: "border-slate-500/20" },
};

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>({
    biensEnAttente: 0,
    documentsEnAttente: 0,
    totalAnnonces: 0,
    villesOuvertes: 0,
  });
  const [recentBiens, setRecentBiens] = useState<any[]>([]);
  const [biensParStatut, setBiensParStatut] = useState<Record<StatutCatalogue, number> | null>(null);
  const [visitesSignalees, setVisitesSignalees] = useState<number>(0);
  const [anciennete, setAnciennete] = useState<{ moyenneJours: number; maxJours: number } | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadDashboardData() {
      try {
        const [
          biensModeration,
          documentsModeration,
          annoncesResp,
          villesResp,
          disponibleResp,
          reserveResp,
          loueResp,
          suspenduResp,
          rejeteResp,
          visitesResp,
        ] = await Promise.allSettled([
          apiRequest<any[]>("/admin/biens?statut=EN_VERIFICATION"),
          apiRequest<any[]>("/admin/documents?statut=EN_ATTENTE"),
          apiRequest<{ data: any[]; meta: any }>("/annonces"),
          apiRequest<any[]>("/villes"),
          apiRequest<any[]>("/admin/biens?statut=DISPONIBLE"),
          apiRequest<any[]>("/admin/biens?statut=RESERVE"),
          apiRequest<any[]>("/admin/biens?statut=LOUE"),
          apiRequest<any[]>("/admin/biens?statut=SUSPENDU"),
          apiRequest<any[]>("/admin/biens?statut=REJETE"),
          apiRequest<any[]>("/admin/visites"),
        ]);

        const biens = biensModeration.status === "fulfilled" ? biensModeration.value : [];
        const docs = documentsModeration.status === "fulfilled" ? documentsModeration.value : [];
        const annonces = annoncesResp.status === "fulfilled" ? annoncesResp.value.meta?.total || 0 : 0;
        const villes = villesResp.status === "fulfilled" ? villesResp.value.length : 0;

        setStats({
          biensEnAttente: biens.length,
          documentsEnAttente: docs.length,
          totalAnnonces: annonces,
          villesOuvertes: villes,
        });

        setRecentBiens(biens.slice(0, 5));

        setBiensParStatut({
          EN_VERIFICATION: biens.length,
          DISPONIBLE: disponibleResp.status === "fulfilled" ? disponibleResp.value.length : 0,
          RESERVE: reserveResp.status === "fulfilled" ? reserveResp.value.length : 0,
          LOUE: loueResp.status === "fulfilled" ? loueResp.value.length : 0,
          SUSPENDU: suspenduResp.status === "fulfilled" ? suspenduResp.value.length : 0,
          REJETE: rejeteResp.status === "fulfilled" ? rejeteResp.value.length : 0,
        });

        setVisitesSignalees(visitesResp.status === "fulfilled" ? visitesResp.value.length : 0);

        // Ancienneté (en jours) des biens actuellement en file de modération —
        // signal opérationnel réel calculé à partir des vraies dates de soumission,
        // pas une métrique inventée.
        if (biens.length > 0) {
          const now = Date.now();
          const joursDepuis = biens
            .map((b) => (b.createdAt ? (now - new Date(b.createdAt).getTime()) / 86_400_000 : null))
            .filter((j): j is number => j !== null);
          if (joursDepuis.length > 0) {
            setAnciennete({
              moyenneJours: joursDepuis.reduce((a, b) => a + b, 0) / joursDepuis.length,
              maxJours: Math.max(...joursDepuis),
            });
          }
        } else {
          setAnciennete(null);
        }
      } catch (err) {
        console.error("Erreur lors du chargement du tableau de bord", err);
      } finally {
        setLoading(false);
      }
    }

    loadDashboardData();
  }, []);

  return (
    <div className="flex min-h-screen bg-slate-950">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header title="Tableau de Bord Backoffice" />

        <main className="p-8 space-y-8 flex-1 overflow-y-auto">
          {/* Welcome Banner */}
          <div className="relative overflow-hidden bg-gradient-to-r from-emerald-950/80 via-slate-900 to-slate-900 border border-emerald-500/20 rounded-3xl p-8 shadow-xl">
            <div className="relative z-10 max-w-2xl">
              <span className="text-xs font-bold text-emerald-400 uppercase tracking-widest bg-emerald-500/10 px-3 py-1 rounded-full border border-emerald-500/20">
                Périmètre Opérationnel — Cameroun
              </span>
              <h1 className="text-3xl font-bold text-white tracking-tight mt-3 mb-2">
                Bienvenue sur le Portail de Modération LocaDirect
              </h1>
              <p className="text-slate-300 text-sm leading-relaxed">
                Suivez en temps réel la fraîcheur du stock immobilier, validez les preuves de propriété des bailleurs et garantissez des visites 100% fiables à Douala et Yaoundé.
              </p>
            </div>
            <div className="absolute right-0 top-0 bottom-0 w-1/3 bg-gradient-to-l from-emerald-500/10 to-transparent pointer-events-none" />
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
            {/* Biens à modérer */}
            <Link
              href="/biens"
              className="bg-slate-900 border border-slate-800 hover:border-amber-500/50 p-6 rounded-2xl transition-all duration-200 group relative overflow-hidden"
            >
              <div className="flex items-center justify-between mb-4">
                <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Biens à Vérifier
                </span>
                <div className="w-10 h-10 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center group-hover:scale-110 transition-transform">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
              </div>
              <div className="text-3xl font-bold text-white tracking-tight">
                {loading ? "..." : stats.biensEnAttente}
              </div>
              <p className="text-xs text-amber-400 font-medium mt-2 flex items-center gap-1">
                <span>En attente de revue Staff</span> →
              </p>
            </Link>

            {/* Documents KYC */}
            <Link
              href="/documents"
              className="bg-slate-900 border border-slate-800 hover:border-blue-500/50 p-6 rounded-2xl transition-all duration-200 group relative overflow-hidden"
            >
              <div className="flex items-center justify-between mb-4">
                <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Documents KYC / Preuves
                </span>
                <div className="w-10 h-10 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center group-hover:scale-110 transition-transform">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
              </div>
              <div className="text-3xl font-bold text-white tracking-tight">
                {loading ? "..." : stats.documentsEnAttente}
              </div>
              <p className="text-xs text-blue-400 font-medium mt-2 flex items-center gap-1">
                <span>Pièces d&apos;identité & titres</span> →
              </p>
            </Link>

            {/* Total Annonces Actives */}
            <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
              <div className="flex items-center justify-between mb-4">
                <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Annonces Publiques
                </span>
                <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                </div>
              </div>
              <div className="text-3xl font-bold text-white tracking-tight">
                {loading ? "..." : stats.totalAnnonces}
              </div>
              <p className="text-xs text-slate-400 font-medium mt-2">
                Biens vérifiés et visibles
              </p>
            </div>

            {/* Villes Ouvertes */}
            <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
              <div className="flex items-center justify-between mb-4">
                <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Villes Couvertes
                </span>
                <div className="w-10 h-10 rounded-xl bg-teal-500/10 text-teal-400 flex items-center justify-center">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  </svg>
                </div>
              </div>
              <div className="text-3xl font-bold text-white tracking-tight">
                {loading ? "..." : stats.villesOuvertes}
              </div>
              <p className="text-xs text-slate-400 font-medium mt-2">
                Douala, Yaoundé & extensions
              </p>
            </div>
          </div>

          {/* Signaux opérationnels supplémentaires */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {/* Ancienneté de la file de modération */}
            <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
              <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                Ancienneté de la File de Modération
              </span>
              {loading ? (
                <div className="text-slate-500 text-sm mt-4">...</div>
              ) : anciennete ? (
                <div className="flex items-end gap-6 mt-3">
                  <div>
                    <div className="text-2xl font-bold text-white tracking-tight">
                      {anciennete.moyenneJours < 1
                        ? "< 1 j"
                        : `${anciennete.moyenneJours.toFixed(1)} j`}
                    </div>
                    <p className="text-[11px] text-slate-400 mt-1">Attente moyenne</p>
                  </div>
                  <div>
                    <div className={`text-2xl font-bold tracking-tight ${anciennete.maxJours > 2 ? "text-amber-400" : "text-white"}`}>
                      {anciennete.maxJours < 1 ? "< 1 j" : `${anciennete.maxJours.toFixed(1)} j`}
                    </div>
                    <p className="text-[11px] text-slate-400 mt-1">Bien le plus ancien</p>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-emerald-400 font-medium mt-3">File vide — rien en attente.</p>
              )}
              <p className="text-[11px] text-slate-500 mt-3">
                Calculé sur les {stats.biensEnAttente} bien(s) actuellement EN_VERIFICATION.
              </p>
            </div>

            {/* Visites signalées en attente */}
            <Link
              href="/visites"
              className="bg-slate-900 border border-slate-800 hover:border-rose-500/50 p-6 rounded-2xl transition-all duration-200 group"
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Visites Signalées en Quarantaine
                </span>
                <div className="w-10 h-10 rounded-xl bg-rose-500/10 text-rose-400 flex items-center justify-center group-hover:scale-110 transition-transform">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                </div>
              </div>
              <div className="text-3xl font-bold text-white tracking-tight">
                {loading ? "..." : visitesSignalees}
              </div>
              <p className="text-xs text-rose-400 font-medium mt-2 flex items-center gap-1">
                <span>Biens masqués suite à contestation</span> →
              </p>
            </Link>
          </div>

          {/* Répartition du catalogue par statut — taux de fraîcheur du stock */}
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
            <div className="mb-5">
              <h3 className="text-lg font-bold text-white">Répartition du Catalogue par Statut</h3>
              <p className="text-xs text-slate-400 mt-0.5">
                Photographie en temps réel de l&apos;état du stock immobilier — pilier du suivi de fraîcheur du
                catalogue.
              </p>
            </div>
            {loading ? (
              <div className="text-center py-8 text-slate-500 text-sm">Chargement de la répartition...</div>
            ) : biensParStatut ? (
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
                {STATUTS_CATALOGUE.map((statut) => {
                  const style = STATUT_STYLES[statut];
                  return (
                    <div key={statut} className={`p-4 rounded-xl border ${style.bg} ${style.border}`}>
                      <div className={`text-2xl font-bold ${style.text}`}>{biensParStatut[statut]}</div>
                      <p className="text-[11px] text-slate-400 mt-1 font-medium">{style.label}</p>
                    </div>
                  );
                })}
              </div>
            ) : (
              <p className="text-sm text-slate-500 text-center py-8">Répartition indisponible pour le moment.</p>
            )}
          </div>

          {/* Biens récents en attente de modération */}
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-lg font-bold text-white">Derniers Biens Soumis en Attente de Modération</h3>
                <p className="text-xs text-slate-400 mt-0.5">Biens avec le statut EN_VERIFICATION nécessitant une validation Staff</p>
              </div>
              <Link
                href="/biens"
                className="text-xs font-semibold text-emerald-400 hover:text-emerald-300 bg-emerald-500/10 border border-emerald-500/20 px-3 py-1.5 rounded-lg transition-colors"
              >
                Voir toute la file ({stats.biensEnAttente})
              </Link>
            </div>

            {loading ? (
              <div className="text-center py-12 text-slate-500 text-sm">Chargement des biens...</div>
            ) : recentBiens.length === 0 ? (
              <div className="text-center py-12 border border-dashed border-slate-800 rounded-xl">
                <svg className="w-12 h-12 text-slate-600 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <p className="text-slate-400 font-medium text-sm">Aucun bien en attente de modération pour le moment !</p>
                <p className="text-xs text-slate-500 mt-1">Tous les biens soumis ont déjà été traités par l&apos;équipe.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-300">
                  <thead className="bg-slate-950/60 text-xs uppercase tracking-wider text-slate-400 border-b border-slate-800">
                    <tr>
                      <th className="py-3 px-4">Référence</th>
                      <th className="py-3 px-4">Titre / Type</th>
                      <th className="py-3 px-4">Localisation</th>
                      <th className="py-3 px-4">Loyer Mensuel</th>
                      <th className="py-3 px-4 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {recentBiens.map((bien) => (
                      <tr key={bien.id} className="hover:bg-slate-800/40 transition-colors">
                        <td className="py-3.5 px-4 font-mono text-xs font-semibold text-emerald-400">
                          {bien.reference}
                        </td>
                        <td className="py-3.5 px-4">
                          <p className="font-semibold text-white truncate max-w-xs">{bien.titre || "Sans titre"}</p>
                          <span className="text-xs text-slate-400">{bien.type}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <p className="text-slate-200">{bien.ville || "—"}</p>
                          <p className="text-xs text-slate-400">{bien.quartier || "—"}</p>
                        </td>
                        <td className="py-3.5 px-4 font-semibold text-white">
                          {bien.loyerMensuelXAF ? `${bien.loyerMensuelXAF.toLocaleString()} XAF` : "—"}
                        </td>
                        <td className="py-3.5 px-4 text-right">
                          <Link
                            href={`/biens?id=${bien.id}`}
                            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-semibold text-xs rounded-lg transition-colors"
                          >
                            <span>Examiner</span>
                          </Link>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}
