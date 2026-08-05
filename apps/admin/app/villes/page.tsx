"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "@/components/sidebar";
import { Header } from "@/components/header";
import { apiRequest } from "@/lib/api";

export default function VillesPage() {
  const [villes, setVilles] = useState<any[]>([]);
  const [selectedVille, setSelectedVille] = useState<any | null>(null);
  const [quartiers, setQuartiers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingQuartiers, setLoadingQuartiers] = useState(false);

  useEffect(() => {
    async function loadVilles() {
      try {
        const data = await apiRequest<any[]>("/villes");
        setVilles(data);
        if (data.length > 0) {
          setSelectedVille(data[0]);
        }
      } catch (err) {
        console.error("Erreur de chargement des villes", err);
      } finally {
        setLoading(false);
      }
    }

    loadVilles();
  }, []);

  useEffect(() => {
    if (!selectedVille) return;
    async function loadQuartiers() {
      setLoadingQuartiers(true);
      try {
        const data = await apiRequest<any[]>(`/villes/${selectedVille.slug}/quartiers`);
        setQuartiers(data);
      } catch (err) {
        console.error("Erreur de chargement des quartiers", err);
      } finally {
        setLoadingQuartiers(false);
      }
    }

    loadQuartiers();
  }, [selectedVille]);

  return (
    <div className="flex min-h-screen bg-slate-950">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header title="Gestion Géographique (Villes & Quartiers)" />

        <main className="p-8 space-y-6 flex-1 overflow-y-auto">
          {/* Header Banner */}
          <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
            <h2 className="text-lg font-bold text-white">Référentiel des Villes & Quartiers</h2>
            <p className="text-xs text-slate-400 mt-1">
              Configuration du déploiement séquentiel par ville et gestion des points de repère réels (Bonamoussadi, Biyem-Assi, Bastos, etc.).
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Villes Cards */}
            <div className="space-y-4">
              <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Villes ({villes.length})</h3>
              {loading ? (
                <div className="text-center py-8 text-slate-500 text-sm">Chargement...</div>
              ) : (
                villes.map((v) => (
                  <div
                    key={v.id}
                    onClick={() => setSelectedVille(v)}
                    className={`p-5 rounded-2xl border cursor-pointer transition-all ${
                      selectedVille?.id === v.id
                        ? "bg-emerald-500/10 border-emerald-500/50 text-white shadow-lg shadow-emerald-500/10"
                        : "bg-slate-900 border-slate-800 hover:border-slate-700 text-slate-300"
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <h4 className="font-bold text-base">{v.nom}</h4>
                      <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                        {v.statut}
                      </span>
                    </div>
                    <p className="text-xs text-slate-400 mt-1">Région : {v.region}</p>
                  </div>
                ))
              )}
            </div>

            {/* Quartiers Details */}
            <div className="lg:col-span-2 space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Quartiers de {selectedVille?.nom || "la ville"} ({quartiers.length})
                </h3>
              </div>

              {loadingQuartiers ? (
                <div className="text-center py-12 text-slate-500 text-sm">Chargement des quartiers...</div>
              ) : quartiers.length === 0 ? (
                <div className="text-center py-12 border border-dashed border-slate-800 rounded-2xl bg-slate-900/40 text-slate-400 text-sm">
                  Aucun quartier répertorié pour cette ville.
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {quartiers.map((q) => (
                    <div key={q.id} className="bg-slate-900 border border-slate-800 p-4 rounded-2xl space-y-3">
                      <div className="flex items-center justify-between">
                        <h4 className="font-bold text-white text-sm">{q.nom}</h4>
                        <span className="text-[10px] text-slate-400 font-mono">/{q.slug}</span>
                      </div>

                      {q.reperes && q.reperes.length > 0 && (
                        <div>
                          <span className="text-[10px] text-slate-500 uppercase tracking-wider block mb-1">
                            Points de Repère
                          </span>
                          <div className="flex flex-wrap gap-1.5">
                            {q.reperes.map((rep: any) => (
                              <span
                                key={rep.id}
                                className="text-[11px] bg-slate-950 border border-slate-800 text-slate-300 px-2 py-0.5 rounded-lg"
                              >
                                📍 {rep.nom}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
