"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "@/components/sidebar";
import { Header } from "@/components/header";
import { apiRequest } from "@/lib/api";

interface VisiteLitige {
  id: string;
  annonceId: string;
  statut: string;
  motifContestation: string | null;
  createdAt: string;
  bienId?: string;
  bienReference?: string;
  bienStatut?: string;
  locataire?: { id: string; nomComplet: string | null; telephone: string };
  annonce?: {
    titre: string;
    ville?: string;
    quartier?: string;
    photo?: string;
    bailleurTel?: string;
    bailleurWhatsapp?: string;
  };
}

type ActionEnCours = { item: VisiteLitige; action: "retirer" | "debloquer" };

export default function VisitesLitigesPage() {
  const [visites, setVisites] = useState<VisiteLitige[]>([]);
  const [loading, setLoading] = useState(true);
  const [enCours, setEnCours] = useState<ActionEnCours | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [feedback, setFeedback] = useState<{ message: string; type: "success" | "error" } | null>(null);

  const fetchVisites = async () => {
    setLoading(true);
    try {
      // Sans `statut` explicite, l'API ne renvoie que les biens encore en
      // quarantaine (SUSPENDU) — dès qu'on tranche, l'entrée sort de la liste.
      const data = await apiRequest<VisiteLitige[]>("/admin/visites");
      setVisites(data);
    } catch (err: unknown) {
      setFeedback({ message: err instanceof Error ? err.message : "Erreur de chargement des visites signalées", type: "error" });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVisites();
  }, []);

  const handleConfirmer = async () => {
    if (!enCours?.item.bienId) return;
    setSubmitting(true);
    setFeedback(null);
    try {
      if (enCours.action === "retirer") {
        await apiRequest(`/admin/biens/${enCours.item.bienId}/rejeter`, {
          method: "POST",
          body: JSON.stringify({ motif: `Visite(s) signalée(s) non conforme(s) : ${enCours.item.motifContestation || "motif non précisé"}` }),
        });
        setFeedback({ message: "Bien retiré du catalogue suite au signalement.", type: "success" });
      } else {
        await apiRequest(`/admin/biens/${enCours.item.bienId}/valider`, { method: "POST" });
        setFeedback({ message: "Bien débloqué — signalement jugé infondé, à nouveau visible dans le catalogue.", type: "success" });
      }
      setEnCours(null);
      fetchVisites();
    } catch (err: unknown) {
      setFeedback({ message: err instanceof Error ? err.message : "Erreur lors du traitement du signalement", type: "error" });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-950">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header title="Visites Signalées Non Conformes" />

        <main className="p-8 space-y-6 flex-1 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
            <h2 className="text-lg font-bold text-white">Contrôle Qualité du Catalogue</h2>
            <p className="text-xs text-slate-400 mt-1 max-w-2xl">
              Dès qu&apos;un locataire signale qu&apos;un bien ne correspond pas à l&apos;annonce, le bien est
              automatiquement mis en quarantaine (masqué du catalogue public) le temps que vous instruisiez le
              dossier. Confirmez le signalement pour retirer définitivement le bien, ou débloquez-le si le
              signalement est infondé.
            </p>
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
            <div className="text-center py-20 text-slate-500 text-sm">Chargement des signalements...</div>
          ) : visites.length === 0 ? (
            <div className="text-center py-20 border border-dashed border-slate-800 rounded-2xl bg-slate-900/40">
              <svg className="w-12 h-12 text-slate-600 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <p className="text-slate-300 font-semibold text-base">Aucune visite signalée non conforme.</p>
              <p className="text-xs text-slate-500 mt-1">Le catalogue est propre pour le moment.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {visites.map((v) => (
                <div key={v.id} className="bg-slate-900 border border-rose-500/20 rounded-2xl p-5 flex flex-col justify-between space-y-4">
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-[11px] font-mono font-bold text-rose-400 bg-rose-500/10 border border-rose-500/20 px-2.5 py-0.5 rounded-lg">
                        {v.bienReference || "Réf. inconnue"}
                      </span>
                      <span className="text-[10px] text-slate-500">{new Date(v.createdAt).toLocaleDateString("fr-FR")}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-bold uppercase tracking-wide text-amber-400 bg-amber-500/10 border border-amber-500/20 px-2 py-0.5 rounded-lg">
                        En quarantaine
                      </span>
                    </div>
                    <h3 className="font-bold text-white text-sm leading-snug line-clamp-2">{v.annonce?.titre || "Annonce"}</h3>
                    <p className="text-xs text-slate-400">{v.annonce?.ville} — {v.annonce?.quartier}</p>
                    <p className="text-xs text-rose-300 bg-rose-500/5 border border-rose-500/10 rounded-lg p-2 mt-2">
                      {v.motifContestation || "Motif non précisé"}
                    </p>
                  </div>

                  <div className="pt-3 border-t border-slate-800 space-y-2">
                    <p className="text-[11px] text-slate-500">
                      Signalé par <span className="text-slate-300 font-medium">{v.locataire?.nomComplet || "Locataire"}</span> ({v.locataire?.telephone})
                    </p>
                    {(v.annonce?.bailleurTel || v.annonce?.bailleurWhatsapp) && (
                      <p className="text-[11px] text-slate-500">
                        Bailleur : <span className="font-mono text-slate-300">{v.annonce?.bailleurTel || v.annonce?.bailleurWhatsapp}</span>
                      </p>
                    )}
                    <div className="flex gap-2">
                      <button
                        onClick={() => setEnCours({ item: v, action: "debloquer" })}
                        className="flex-1 px-3 py-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 font-semibold rounded-xl text-xs transition-colors"
                      >
                        Débloquer
                      </button>
                      <button
                        onClick={() => setEnCours({ item: v, action: "retirer" })}
                        className="flex-1 px-3 py-2 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 font-semibold rounded-xl text-xs transition-colors"
                      >
                        Retirer du catalogue
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </main>
      </div>

      {enCours && (
        <div className="fixed inset-0 bg-slate-950/90 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <h3 className="text-lg font-bold text-white">
              {enCours.action === "retirer" ? "Retirer ce bien du catalogue ?" : "Débloquer ce bien ?"}
            </h3>
            <p className="text-xs text-slate-400">
              {enCours.action === "retirer" ? (
                <>
                  Le bien <span className="font-mono text-white">{enCours.item.bienReference}</span> repassera au
                  statut Rejeté et disparaîtra définitivement des résultats de recherche. Le motif du signalement
                  sera enregistré comme motif de rejet.
                </>
              ) : (
                <>
                  Le bien <span className="font-mono text-white">{enCours.item.bienReference}</span> sort de
                  quarantaine et redevient Disponible dans le catalogue public — à utiliser si, après instruction,
                  le signalement s&apos;avère infondé.
                </>
              )}
            </p>
            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setEnCours(null)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold rounded-xl"
              >
                Annuler
              </button>
              <button
                onClick={handleConfirmer}
                disabled={submitting}
                className={`px-4 py-2 text-white text-xs font-bold rounded-xl shadow-lg ${
                  enCours.action === "retirer"
                    ? "bg-rose-500 hover:bg-rose-400 shadow-rose-500/20"
                    : "bg-emerald-500 hover:bg-emerald-400 shadow-emerald-500/20"
                }`}
              >
                {submitting ? "Traitement..." : enCours.action === "retirer" ? "Confirmer le retrait" : "Confirmer le déblocage"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
