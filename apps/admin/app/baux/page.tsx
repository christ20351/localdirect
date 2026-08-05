"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "@/components/sidebar";
import { Header } from "@/components/header";
import { apiRequest, getBailPdfUrl } from "@/lib/api";

interface Bail {
  id: string;
  reference: string;
  statut: string;
  dateDebut: string | null;
  dateFin: string | null;
  dureeMois: number | null;
  loyerMensuelXAF: number;
  chargesMensuellesXAF: number;
  avanceMontantXAF: number;
  cautionMontantXAF: number;
  fiscal: {
    loyerBrutXAF: number;
    tauxPrecompte: number;
    precompteXAF: number;
    netBailleurXAF: number;
  };
  pdfDisponible: boolean;
  pdfSigneDisponible: boolean;
  bien?: { ville?: string; quartier?: string };
  bailleur?: { nomComplet: string | null; telephone: string };
  locataire?: { nomComplet: string | null; telephone: string };
}

const STATUT_FILTERS = [
  { key: "", label: "Tous" },
  { key: "PROJET", label: "Projet" },
  { key: "A_SIGNER", label: "À Signer" },
  { key: "ACTIF", label: "Actifs" },
  { key: "PREAVIS", label: "Préavis" },
  { key: "TERMINE", label: "Terminés" },
  { key: "RESILIE", label: "Résiliés" },
  { key: "LITIGE", label: "Litige" },
];

const STATUT_STYLES: Record<string, string> = {
  PROJET: "text-slate-400 bg-slate-500/10 border-slate-500/20",
  A_SIGNER: "text-amber-400 bg-amber-500/10 border-amber-500/20",
  ACTIF: "text-emerald-400 bg-emerald-500/10 border-emerald-500/20",
  PREAVIS: "text-amber-400 bg-amber-500/10 border-amber-500/20",
  TERMINE: "text-slate-400 bg-slate-500/10 border-slate-500/20",
  RESILIE: "text-rose-400 bg-rose-500/10 border-rose-500/20",
  LITIGE: "text-rose-400 bg-rose-500/10 border-rose-500/20",
};

function formatXAF(montant: number): string {
  return new Intl.NumberFormat("fr-FR").format(montant) + " FCFA";
}

export default function BauxPage() {
  const [statutFilter, setStatutFilter] = useState("");
  const [baux, setBaux] = useState<Bail[]>([]);
  const [loading, setLoading] = useState(true);
  const [feedback, setFeedback] = useState<{ message: string; type: "success" | "error" } | null>(null);

  const fetchBaux = async (statut: string) => {
    setLoading(true);
    try {
      const qs = statut ? `?statut=${statut}` : "";
      const data = await apiRequest<Bail[]>(`/admin/baux${qs}`);
      setBaux(data);
    } catch (err: unknown) {
      setFeedback({ message: err instanceof Error ? err.message : "Erreur de chargement des baux", type: "error" });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBaux(statutFilter);
  }, [statutFilter]);

  return (
    <div className="flex min-h-screen bg-slate-950">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header title="Supervision des Baux" />

        <main className="p-8 space-y-6 flex-1 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
            <h2 className="text-lg font-bold text-white">Vue d&apos;Ensemble Plateforme</h2>
            <p className="text-xs text-slate-400 mt-1 max-w-2xl">
              Visibilité en lecture seule sur l&apos;ensemble des baux, avec le détail fiscal (loyer brut / précompte
              10% / net bailleur) calculé pour chacun. La résiliation ou toute autre décision reste du ressort du
              bailleur — aucune action n&apos;est disponible ici.
            </p>
          </div>

          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-4 rounded-2xl">
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider mr-2">
                Filtrer par statut :
              </span>
              {STATUT_FILTERS.map((filter) => (
                <button
                  key={filter.key}
                  onClick={() => setStatutFilter(filter.key)}
                  className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all ${
                    statutFilter === filter.key
                      ? "bg-emerald-500 text-slate-950 shadow-md shadow-emerald-500/20"
                      : "bg-slate-800 text-slate-300 hover:bg-slate-700 hover:text-white"
                  }`}
                >
                  {filter.label}
                </button>
              ))}
            </div>
            <div className="text-xs text-slate-400">
              <span className="font-semibold text-white">{baux.length}</span> bail(aux) affiché(s)
            </div>
          </div>

          {feedback && (
            <div
              className={`p-4 rounded-xl text-sm flex items-center justify-between ${
                feedback.type === "success"
                  ? "bg-emerald-500/10 border border-emerald-500/20 text-emerald-400"
                  : "bg-rose-500/10 border border-rose-500/20 text-rose-400"
              }`}
            >
              <span>{feedback.message}</span>
              <button onClick={() => setFeedback(null)} className="text-xs font-bold hover:underline">
                Fermer
              </button>
            </div>
          )}

          {loading ? (
            <div className="text-center py-20 text-slate-500 text-sm">Chargement des baux...</div>
          ) : baux.length === 0 ? (
            <div className="text-center py-20 border border-dashed border-slate-800 rounded-2xl bg-slate-900/40">
              <svg className="w-12 h-12 text-slate-600 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 17v-2a4 4 0 014-4h4m0 0l-3-3m3 3l-3 3M4 5h11a2 2 0 012 2v10a2 2 0 01-2 2H4a2 2 0 01-2-2V7a2 2 0 012-2z" />
              </svg>
              <p className="text-slate-300 font-semibold text-base">Aucun bail pour ce filtre.</p>
            </div>
          ) : (
            <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-300">
                  <thead className="bg-slate-950/60 text-xs uppercase tracking-wider text-slate-400 border-b border-slate-800">
                    <tr>
                      <th className="py-3 px-4">Référence</th>
                      <th className="py-3 px-4">Bailleur</th>
                      <th className="py-3 px-4">Locataire</th>
                      <th className="py-3 px-4">Bien</th>
                      <th className="py-3 px-4">Statut</th>
                      <th className="py-3 px-4">Fiscalité (Brut / Précompte / Net)</th>
                      <th className="py-3 px-4">PDF</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {baux.map((b) => (
                      <tr key={b.id} className="hover:bg-slate-800/40 transition-colors">
                        <td className="py-3.5 px-4">
                          <p className="font-mono text-xs text-white">{b.reference}</p>
                          <p className="text-[11px] text-slate-500">
                            {b.dateDebut ? new Date(b.dateDebut).toLocaleDateString("fr-FR") : "—"}
                          </p>
                        </td>
                        <td className="py-3.5 px-4">
                          <p className="text-xs text-slate-200">{b.bailleur?.nomComplet || "—"}</p>
                          <p className="text-[11px] font-mono text-slate-500">{b.bailleur?.telephone}</p>
                        </td>
                        <td className="py-3.5 px-4">
                          <p className="text-xs text-slate-200">{b.locataire?.nomComplet || "—"}</p>
                          <p className="text-[11px] font-mono text-slate-500">{b.locataire?.telephone}</p>
                        </td>
                        <td className="py-3.5 px-4 text-[11px] text-slate-400">
                          {b.bien?.ville} — {b.bien?.quartier}
                        </td>
                        <td className="py-3.5 px-4">
                          <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-lg border ${STATUT_STYLES[b.statut] || STATUT_STYLES.PROJET}`}>
                            {b.statut}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-[11px] text-slate-400 whitespace-nowrap">
                          {formatXAF(b.fiscal.loyerBrutXAF)}
                          <span className="text-rose-400"> − {formatXAF(b.fiscal.precompteXAF)}</span>
                          <span className="text-emerald-400"> = {formatXAF(b.fiscal.netBailleurXAF)}</span>
                        </td>
                        <td className="py-3.5 px-4">
                          <a
                            href={getBailPdfUrl(b.id)}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white text-[11px] font-semibold rounded-lg transition-colors"
                          >
                            Télécharger
                          </a>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
