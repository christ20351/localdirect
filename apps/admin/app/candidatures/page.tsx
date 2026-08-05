"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "@/components/sidebar";
import { Header } from "@/components/header";
import { apiRequest } from "@/lib/api";

interface Candidature {
  id: string;
  annonceId: string;
  statut: string;
  revenuDeclareXAF: number | null;
  sourceRevenu: string | null;
  nbOccupants: number | null;
  message: string | null;
  motifRefus: string | null;
  soumiseLe: string | null;
  decideeLe: string | null;
  locataire?: { nomComplet: string | null; telephone: string; statutKyc: string };
  garant?: { nomComplet: string; telephone: string; profession: string | null; lien: string | null; verifie: boolean } | null;
  annonce?: { id: string; titre: string; ville?: string; quartier?: string; loyerMensuelXAF: number };
  bailleur?: { nomComplet: string | null; telephone: string };
}

const STATUT_FILTERS = [
  { key: "", label: "Tous" },
  { key: "SOUMISE", label: "Soumises" },
  { key: "EN_EXAMEN", label: "En Examen" },
  { key: "ACCEPTEE", label: "Acceptées" },
  { key: "REFUSEE", label: "Refusées" },
  { key: "RETIREE", label: "Retirées" },
];

const STATUT_STYLES: Record<string, string> = {
  BROUILLON: "text-slate-400 bg-slate-500/10 border-slate-500/20",
  SOUMISE: "text-blue-400 bg-blue-500/10 border-blue-500/20",
  EN_EXAMEN: "text-amber-400 bg-amber-500/10 border-amber-500/20",
  ACCEPTEE: "text-emerald-400 bg-emerald-500/10 border-emerald-500/20",
  REFUSEE: "text-rose-400 bg-rose-500/10 border-rose-500/20",
  RETIREE: "text-slate-400 bg-slate-500/10 border-slate-500/20",
};

export default function CandidaturesPage() {
  const [statutFilter, setStatutFilter] = useState("");
  const [candidatures, setCandidatures] = useState<Candidature[]>([]);
  const [loading, setLoading] = useState(true);
  const [feedback, setFeedback] = useState<{ message: string; type: "success" | "error" } | null>(null);

  const fetchCandidatures = async (statut: string) => {
    setLoading(true);
    try {
      const qs = statut ? `?statut=${statut}` : "";
      const data = await apiRequest<Candidature[]>(`/admin/candidatures${qs}`);
      setCandidatures(data);
    } catch (err: unknown) {
      setFeedback({ message: err instanceof Error ? err.message : "Erreur de chargement des candidatures", type: "error" });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCandidatures(statutFilter);
  }, [statutFilter]);

  return (
    <div className="flex min-h-screen bg-slate-950">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header title="Supervision des Candidatures" />

        <main className="p-8 space-y-6 flex-1 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
            <h2 className="text-lg font-bold text-white">Vue d&apos;Ensemble Plateforme</h2>
            <p className="text-xs text-slate-400 mt-1 max-w-2xl">
              Visibilité en lecture seule sur l&apos;ensemble des dossiers de candidature soumis par les locataires.
              L&apos;acceptation ou le refus reste une décision du bailleur, prise depuis l&apos;application mobile —
              aucune action n&apos;est disponible ici.
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
              <span className="font-semibold text-white">{candidatures.length}</span> dossier(s) affiché(s)
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
            <div className="text-center py-20 text-slate-500 text-sm">Chargement des candidatures...</div>
          ) : candidatures.length === 0 ? (
            <div className="text-center py-20 border border-dashed border-slate-800 rounded-2xl bg-slate-900/40">
              <svg className="w-12 h-12 text-slate-600 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p className="text-slate-300 font-semibold text-base">Aucune candidature pour ce filtre.</p>
            </div>
          ) : (
            <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-300">
                  <thead className="bg-slate-950/60 text-xs uppercase tracking-wider text-slate-400 border-b border-slate-800">
                    <tr>
                      <th className="py-3 px-4">Locataire</th>
                      <th className="py-3 px-4">Bien / Annonce</th>
                      <th className="py-3 px-4">Bailleur</th>
                      <th className="py-3 px-4">Statut</th>
                      <th className="py-3 px-4">Date</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {candidatures.map((c) => (
                      <tr key={c.id} className="hover:bg-slate-800/40 transition-colors">
                        <td className="py-3.5 px-4">
                          <p className="font-semibold text-white text-xs">{c.locataire?.nomComplet || "—"}</p>
                          <p className="text-[11px] font-mono text-slate-500">{c.locataire?.telephone}</p>
                        </td>
                        <td className="py-3.5 px-4">
                          <p className="text-xs text-slate-200 font-medium truncate max-w-[220px]">{c.annonce?.titre || "—"}</p>
                          <p className="text-[11px] text-slate-500">{c.annonce?.ville} — {c.annonce?.quartier}</p>
                        </td>
                        <td className="py-3.5 px-4">
                          <p className="text-xs text-slate-300">{c.bailleur?.nomComplet || "—"}</p>
                          <p className="text-[11px] font-mono text-slate-500">{c.bailleur?.telephone}</p>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-lg border ${STATUT_STYLES[c.statut] || STATUT_STYLES.BROUILLON}`}>
                            {c.statut}
                          </span>
                          {c.statut === "REFUSEE" && c.motifRefus && (
                            <p className="text-[11px] text-rose-300 mt-1 max-w-[200px]">{c.motifRefus}</p>
                          )}
                        </td>
                        <td className="py-3.5 px-4 text-xs text-slate-400 whitespace-nowrap">
                          {c.soumiseLe ? new Date(c.soumiseLe).toLocaleDateString("fr-FR") : "—"}
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
