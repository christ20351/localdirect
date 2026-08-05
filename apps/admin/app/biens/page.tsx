"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "@/components/sidebar";
import { Header } from "@/components/header";
import { apiRequest } from "@/lib/api";
import Image from "next/image";

export default function ModerationBiensPage() {
  const [statutFilter, setStatutFilter] = useState("EN_VERIFICATION");
  const [biens, setBiens] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedBien, setSelectedBien] = useState<any | null>(null);
  const [rejectingBien, setRejectingBien] = useState<any | null>(null);
  const [motifRejet, setMotifRejet] = useState("Photos floues ou incomplètes");
  const [motifCustom, setMotifCustom] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [feedback, setFeedback] = useState<{ message: string; type: "success" | "error" } | null>(null);

  const fetchBiens = async (statut: string) => {
    setLoading(true);
    try {
      const data = await apiRequest<any[]>(`/admin/biens?statut=${statut}`);
      setBiens(data);
    } catch (err: any) {
      setFeedback({ message: err.message || "Erreur de chargement des biens", type: "error" });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBiens(statutFilter);
  }, [statutFilter]);

  const handleValider = async (bienId: string) => {
    setSubmitting(true);
    setFeedback(null);
    try {
      await apiRequest(`/admin/biens/${bienId}/valider`, { method: "POST" });
      setFeedback({ message: "Bien validé et publié avec succès !", type: "success" });
      setSelectedBien(null);
      fetchBiens(statutFilter);
    } catch (err: any) {
      setFeedback({ message: err.message || "Erreur lors de la validation du bien", type: "error" });
    } finally {
      setSubmitting(false);
    }
  };

  const handleRejeterSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!rejectingBien) return;

    const motifFinal = motifRejet === "Autre" ? motifCustom : motifRejet;
    if (!motifFinal) return;

    setSubmitting(true);
    setFeedback(null);
    try {
      await apiRequest(`/admin/biens/${rejectingBien.id}/rejeter`, {
        method: "POST",
        body: JSON.stringify({ motif: motifFinal }),
      });
      setFeedback({ message: "Bien rejeté avec motif.", type: "success" });
      setRejectingBien(null);
      setSelectedBien(null);
      fetchBiens(statutFilter);
    } catch (err: any) {
      setFeedback({ message: err.message || "Erreur lors du rejet du bien", type: "error" });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-950">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header title="File de Modération des Biens & Annonces" />

        <main className="p-8 space-y-6 flex-1 overflow-y-auto">
          {/* Top Bar / Filters */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-4 rounded-2xl">
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider mr-2">
                Filtrer par statut :
              </span>
              {[
                { key: "EN_VERIFICATION", label: "En Attente de Vérification" },
                { key: "DISPONIBLE", label: "Publiés / Disponibles" },
                { key: "REJETE", label: "Rejetés" },
                { key: "LOUE", label: "Loués" },
              ].map((filter) => (
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
              <span className="font-semibold text-white">{biens.length}</span> bien(s) affiché(s)
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

          {/* Biens List */}
          {loading ? (
            <div className="text-center py-20 text-slate-500 text-sm">Chargement de la file de modération...</div>
          ) : biens.length === 0 ? (
            <div className="text-center py-20 border border-dashed border-slate-800 rounded-2xl bg-slate-900/40">
              <svg className="w-12 h-12 text-slate-600 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <p className="text-slate-300 font-semibold text-base">Aucun bien pour ce statut ({statutFilter})</p>
              <p className="text-xs text-slate-500 mt-1">Sélectionnez un autre filtre ou revenez plus tard.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {biens.map((bien) => (
                <div
                  key={bien.id}
                  className="bg-slate-900 border border-slate-800 hover:border-slate-700 rounded-2xl overflow-hidden flex flex-col transition-all group"
                >
                  {/* Photo Preview */}
                  <div className="relative h-48 bg-slate-950 overflow-hidden">
                    {bien.photos && bien.photos.length > 0 ? (
                      <img
                        src={bien.photos[0]}
                        alt={bien.titre || "Photo du bien"}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-slate-600 text-xs">
                        Aucune photo fournie
                      </div>
                    )}
                    <div className="absolute top-3 left-3 bg-slate-950/80 backdrop-blur-md px-2.5 py-1 rounded-lg text-[11px] font-mono font-bold text-emerald-400 border border-slate-800">
                      {bien.reference}
                    </div>
                    <div className="absolute top-3 right-3 bg-emerald-500 text-slate-950 px-2.5 py-1 rounded-lg text-[11px] font-bold shadow-md">
                      {bien.type}
                    </div>
                  </div>

                  {/* Body */}
                  <div className="p-5 flex-1 flex flex-col justify-between space-y-4">
                    <div>
                      <h3 className="font-bold text-white text-base leading-snug line-clamp-2">
                        {bien.titre || "Studio / Logement à louer"}
                      </h3>
                      <p className="text-xs text-slate-400 mt-1 flex items-center gap-1">
                        <svg className="w-3.5 h-3.5 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        </svg>
                        <span>{bien.ville} — {bien.quartier}</span>
                      </p>
                    </div>

                    <div className="pt-3 border-t border-slate-800/80 flex items-center justify-between">
                      <div>
                        <span className="text-[10px] text-slate-400 uppercase tracking-wider block">Loyer Mensuel</span>
                        <span className="text-base font-extrabold text-white">
                          {bien.loyerMensuelXAF ? `${bien.loyerMensuelXAF.toLocaleString()} XAF` : "—"}
                        </span>
                      </div>

                      <button
                        onClick={() => setSelectedBien(bien)}
                        className="px-3.5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 hover:text-white rounded-xl text-xs font-semibold transition-colors flex items-center gap-1.5"
                      >
                        <span>Inspecter</span>
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </main>
      </div>

      {/* Modal Détails & Inspection */}
      {selectedBien && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl max-w-3xl w-full max-h-[90vh] flex flex-col shadow-2xl overflow-hidden">
            {/* Modal Header */}
            <div className="p-6 border-b border-slate-800 flex items-center justify-between">
              <div>
                <span className="text-xs font-mono font-bold text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-2.5 py-0.5 rounded-full">
                  {selectedBien.reference}
                </span>
                <h3 className="text-xl font-bold text-white mt-1">{selectedBien.titre || "Détails du bien"}</h3>
              </div>
              <button
                onClick={() => setSelectedBien(null)}
                className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-colors"
              >
                ✕
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto space-y-6 flex-1 text-sm text-slate-300">
              {/* Photos Gallery */}
              {selectedBien.photos && selectedBien.photos.length > 0 && (
                <div>
                  <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Photos du bien ({selectedBien.photos.length})</h4>
                  <div className="grid grid-cols-3 gap-3">
                    {selectedBien.photos.map((url: string, idx: number) => (
                      <img
                        key={idx}
                        src={url}
                        alt={`Photo ${idx + 1}`}
                        className="w-full h-32 object-cover rounded-xl border border-slate-800"
                      />
                    ))}
                  </div>
                </div>
              )}

              {/* Infos Clés */}
              <div className="grid grid-cols-2 gap-4 bg-slate-950 p-4 rounded-2xl border border-slate-800">
                <div>
                  <span className="text-xs text-slate-400 block">Type de bien</span>
                  <span className="font-semibold text-white">{selectedBien.type}</span>
                </div>
                <div>
                  <span className="text-xs text-slate-400 block">Meublé ?</span>
                  <span className="font-semibold text-white">{selectedBien.meuble ? "Oui" : "Non"}</span>
                </div>
                <div>
                  <span className="text-xs text-slate-400 block">Ville & Quartier</span>
                  <span className="font-semibold text-white">{selectedBien.ville} — {selectedBien.quartier}</span>
                </div>
                <div>
                  <span className="text-xs text-slate-400 block">Loyer Mensuel</span>
                  <span className="font-bold text-emerald-400 text-base">
                    {selectedBien.loyerMensuelXAF ? `${selectedBien.loyerMensuelXAF.toLocaleString()} XAF` : "—"}
                  </span>
                </div>
              </div>

              {/* Contact Bailleur */}
              {(selectedBien.bailleurTel || selectedBien.bailleurWhatsapp || selectedBien.bailleur) && (
                <div className="bg-slate-950/60 p-4 rounded-2xl border border-slate-800 space-y-2">
                  <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Contact du Bailleur / Propriétaire</h4>
                  <div className="flex items-center gap-6 text-sm">
                    {selectedBien.bailleur?.nomComplet && (
                      <div>
                        <span className="text-xs text-slate-500 block">Nom</span>
                        <span className="font-semibold text-white">{selectedBien.bailleur.nomComplet}</span>
                      </div>
                    )}
                    {selectedBien.bailleurTel && (
                      <div>
                        <span className="text-xs text-slate-500 block">Téléphone</span>
                        <span className="font-mono text-emerald-400">{selectedBien.bailleurTel}</span>
                      </div>
                    )}
                    {selectedBien.bailleurWhatsapp && (
                      <div>
                        <span className="text-xs text-slate-500 block">WhatsApp</span>
                        <span className="font-mono text-emerald-400">{selectedBien.bailleurWhatsapp}</span>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Modal Actions */}
            <div className="p-6 border-t border-slate-800 bg-slate-950 flex items-center justify-end gap-3">
              <button
                onClick={() => setRejectingBien(selectedBien)}
                disabled={submitting}
                className="px-4 py-2.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 font-semibold rounded-xl text-xs transition-colors"
              >
                Rejeter l&apos;Annonce
              </button>
              <button
                onClick={() => handleValider(selectedBien.id)}
                disabled={submitting}
                className="px-5 py-2.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold rounded-xl text-xs transition-colors shadow-lg shadow-emerald-500/20"
              >
                {submitting ? "Validation..." : "Valider & Publier l'Annonce"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Motif de Rejet */}
      {rejectingBien && (
        <div className="fixed inset-0 bg-slate-950/90 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <h3 className="text-lg font-bold text-white">Motif du Rejet de l&apos;Annonce</h3>
            <p className="text-xs text-slate-400">Sélectionnez le motif principal du rejet qui sera notifié au bailleur :</p>

            <form onSubmit={handleRejeterSubmit} className="space-y-4">
              <div className="space-y-2">
                {[
                  "Photos floues ou incomplètes",
                  "Prix suspect par rapport à la médiane du quartier",
                  "Indications d'accès insuffisantes",
                  "Document de preuve de propriété manquant",
                  "Autre",
                ].map((option) => (
                  <label key={option} className="flex items-center gap-3 p-3 bg-slate-950 border border-slate-800 rounded-xl cursor-pointer hover:border-slate-700">
                    <input
                      type="radio"
                      name="motif"
                      value={option}
                      checked={motifRejet === option}
                      onChange={(e) => setMotifRejet(e.target.value)}
                      className="text-emerald-500 focus:ring-emerald-500"
                    />
                    <span className="text-xs text-slate-200 font-medium">{option}</span>
                  </label>
                ))}
              </div>

              {motifRejet === "Autre" && (
                <textarea
                  value={motifCustom}
                  onChange={(e) => setMotifCustom(e.target.value)}
                  placeholder="Précisez le motif..."
                  className="w-full p-3 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                  rows={3}
                  required
                />
              )}

              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setRejectingBien(null)}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold rounded-xl"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-4 py-2 bg-rose-500 hover:bg-rose-400 text-white text-xs font-bold rounded-xl shadow-lg shadow-rose-500/20"
                >
                  {submitting ? "Envoi..." : "Confirmer le Rejet"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
