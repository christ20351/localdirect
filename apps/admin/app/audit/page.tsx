"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "@/components/sidebar";
import { Header } from "@/components/header";
import { apiRequest } from "@/lib/api";

interface AuditActeur {
  id: string;
  nomComplet: string | null;
  telephone: string;
  roles: string[];
}

interface AuditEntry {
  id: string;
  acteur: AuditActeur | null;
  action: string;
  entite: string;
  entiteId: string | null;
  avant: unknown;
  apres: unknown;
  ip: string | null;
  createdAt: string;
}

interface AuditResponse {
  data: AuditEntry[];
  meta: { total: number; page: number; limit: number; pagesTotal: number };
}

const LIMIT = 25;

export default function AuditPage() {
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [meta, setMeta] = useState<AuditResponse["meta"] | null>(null);
  const [page, setPage] = useState(1);
  const [entiteFilter, setEntiteFilter] = useState("");
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});
  const [feedback, setFeedback] = useState<{ message: string; type: "success" | "error" } | null>(null);

  const fetchEntries = async (targetPage: number, entite: string) => {
    setLoading(true);
    try {
      const qs = new URLSearchParams({ page: String(targetPage), limit: String(LIMIT) });
      if (entite) qs.set("entite", entite);
      const data = await apiRequest<AuditResponse>(`/admin/audit?${qs.toString()}`);
      setEntries(data.data);
      setMeta(data.meta);
    } catch (err: unknown) {
      setFeedback({ message: err instanceof Error ? err.message : "Erreur de chargement du journal d'audit", type: "error" });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEntries(page, entiteFilter);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page]);

  const applyFilter = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    fetchEntries(1, entiteFilter);
  };

  const toggleExpanded = (id: string) => {
    setExpanded((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  const actionColor = (action: string) => {
    const a = action.toLowerCase();
    if (a.includes("rejet") || a.includes("suppr") || a.includes("retir")) return "text-rose-400 bg-rose-500/10 border-rose-500/20";
    if (a.includes("valid") || a.includes("cre") || a.includes("ouvr")) return "text-emerald-400 bg-emerald-500/10 border-emerald-500/20";
    return "text-amber-400 bg-amber-500/10 border-amber-500/20";
  };

  return (
    <div className="flex min-h-screen bg-slate-950">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header title="Journal d'Audit Système" />

        <main className="p-8 space-y-6 flex-1 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
            <h2 className="text-lg font-bold text-white">Traçabilité des Actions Sensibles</h2>
            <p className="text-xs text-slate-400 mt-1 max-w-2xl">
              Historique chronologique des actions administratives (validations, rejets, changements de statut de
              ville, décisions de bail, etc.). Chaque entrée conserve l&apos;acteur, l&apos;entité concernée et,
              lorsque disponible, l&apos;état avant/après.
            </p>
          </div>

          <form onSubmit={applyFilter} className="flex flex-col sm:flex-row sm:items-center gap-3 bg-slate-900 border border-slate-800 p-4 rounded-2xl">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Filtrer par entité :</span>
            <input
              type="text"
              value={entiteFilter}
              onChange={(e) => setEntiteFilter(e.target.value)}
              placeholder="ex: Bien, Document, Ville, Candidature..."
              className="flex-1 max-w-xs px-3 py-1.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
            />
            <button
              type="submit"
              className="px-3.5 py-1.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 text-xs font-semibold rounded-xl transition-colors"
            >
              Appliquer
            </button>
            {entiteFilter && (
              <button
                type="button"
                onClick={() => {
                  setEntiteFilter("");
                  setPage(1);
                  fetchEntries(1, "");
                }}
                className="px-3.5 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold rounded-xl transition-colors"
              >
                Réinitialiser
              </button>
            )}
            {meta && <span className="text-xs text-slate-500 sm:ml-auto">{meta.total} entrée(s) au total</span>}
          </form>

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
            <div className="text-center py-20 text-slate-500 text-sm">Chargement du journal d&apos;audit...</div>
          ) : entries.length === 0 ? (
            <div className="text-center py-20 border border-dashed border-slate-800 rounded-2xl bg-slate-900/40">
              <svg className="w-12 h-12 text-slate-600 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p className="text-slate-300 font-semibold text-base">Aucune entrée d&apos;audit pour le moment.</p>
              <p className="text-xs text-slate-500 mt-1">
                {entiteFilter ? "Aucun résultat pour ce filtre." : "Les actions sensibles apparaîtront ici au fur et à mesure."}
              </p>
            </div>
          ) : (
            <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-300">
                  <thead className="bg-slate-950/60 text-xs uppercase tracking-wider text-slate-400 border-b border-slate-800">
                    <tr>
                      <th className="py-3 px-4">Horodatage</th>
                      <th className="py-3 px-4">Acteur</th>
                      <th className="py-3 px-4">Action</th>
                      <th className="py-3 px-4">Entité</th>
                      <th className="py-3 px-4 text-right">Détails</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {entries.map((entry) => {
                      const hasDiff = entry.avant !== null || entry.apres !== null;
                      const isOpen = !!expanded[entry.id];
                      return (
                        <React.Fragment key={entry.id}>
                          <tr className="hover:bg-slate-800/40 transition-colors">
                            <td className="py-3.5 px-4 text-xs text-slate-400 whitespace-nowrap">
                              {new Date(entry.createdAt).toLocaleString("fr-FR")}
                            </td>
                            <td className="py-3.5 px-4">
                              {entry.acteur ? (
                                <div>
                                  <p className="font-semibold text-white text-xs">
                                    {entry.acteur.nomComplet || entry.acteur.telephone}
                                  </p>
                                  <p className="text-[11px] text-slate-500">{entry.acteur.roles.join(" · ")}</p>
                                </div>
                              ) : (
                                <span className="text-xs text-slate-500 italic">Système</span>
                              )}
                            </td>
                            <td className="py-3.5 px-4">
                              <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-lg border ${actionColor(entry.action)}`}>
                                {entry.action}
                              </span>
                            </td>
                            <td className="py-3.5 px-4">
                              <p className="text-xs text-slate-200 font-medium">{entry.entite}</p>
                              {entry.entiteId && (
                                <p className="text-[11px] font-mono text-slate-500 truncate max-w-[180px]">{entry.entiteId}</p>
                              )}
                            </td>
                            <td className="py-3.5 px-4 text-right">
                              {hasDiff ? (
                                <button
                                  onClick={() => toggleExpanded(entry.id)}
                                  className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold rounded-lg transition-colors"
                                >
                                  {isOpen ? "Masquer" : "Voir diff"}
                                </button>
                              ) : (
                                <span className="text-[11px] text-slate-600">—</span>
                              )}
                            </td>
                          </tr>
                          {isOpen && hasDiff && (
                            <tr className="bg-slate-950/60">
                              <td colSpan={5} className="p-4">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                  <div>
                                    <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block mb-1.5">
                                      Avant
                                    </span>
                                    <pre className="text-[11px] text-rose-300 bg-slate-950 border border-rose-500/10 rounded-xl p-3 overflow-x-auto whitespace-pre-wrap">
                                      {entry.avant ? JSON.stringify(entry.avant, null, 2) : "—"}
                                    </pre>
                                  </div>
                                  <div>
                                    <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block mb-1.5">
                                      Après
                                    </span>
                                    <pre className="text-[11px] text-emerald-300 bg-slate-950 border border-emerald-500/10 rounded-xl p-3 overflow-x-auto whitespace-pre-wrap">
                                      {entry.apres ? JSON.stringify(entry.apres, null, 2) : "—"}
                                    </pre>
                                  </div>
                                </div>
                              </td>
                            </tr>
                          )}
                        </React.Fragment>
                      );
                    })}
                  </tbody>
                </table>
              </div>

              {meta && meta.pagesTotal > 1 && (
                <div className="flex items-center justify-between p-4 border-t border-slate-800 bg-slate-950/40">
                  <span className="text-xs text-slate-500">
                    Page {meta.page} / {meta.pagesTotal}
                  </span>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => setPage((p) => Math.max(1, p - 1))}
                      disabled={page <= 1}
                      className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed text-slate-300 text-xs font-semibold rounded-lg transition-colors"
                    >
                      Précédent
                    </button>
                    <button
                      onClick={() => setPage((p) => Math.min(meta.pagesTotal, p + 1))}
                      disabled={page >= meta.pagesTotal}
                      className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed text-slate-300 text-xs font-semibold rounded-lg transition-colors"
                    >
                      Suivant
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
