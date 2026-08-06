"use client";

import React, { useEffect, useState } from "react";
import { Sidebar } from "@/components/sidebar";
import { Header } from "@/components/header";
import { apiRequest, getDocumentUrl } from "@/lib/api";

interface UserDocGroup {
  user: {
    id: string;
    nomComplet?: string | null;
    email?: string | null;
    telephone: string;
  };
  docs: any[];
}

export default function ModerationDocumentsPage() {
  const [statutFilter, setStatutFilter] = useState("EN_ATTENTE");
  const [documents, setDocuments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedUsers, setExpandedUsers] = useState<Record<string, boolean>>({});
  const [selectedDoc, setSelectedDoc] = useState<any | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [motifRejet, setMotifRejet] = useState("Document illisible ou flou");
  const [rejectingDoc, setRejectingDoc] = useState<any | null>(null);
  const [feedback, setFeedback] = useState<{ message: string; type: "success" | "error" } | null>(null);

  const fetchDocuments = async (statut: string) => {
    setLoading(true);
    try {
      const data = await apiRequest<any[]>(`/admin/documents?statut=${statut}`);
      setDocuments(data);

      // Ouvrir par défaut le premier utilisateur s'il existe
      if (data && data.length > 0) {
        const firstUserId = data[0]?.utilisateur?.id || data[0]?.utilisateur?.telephone;
        if (firstUserId) {
          setExpandedUsers({ [firstUserId]: true });
        }
      }
    } catch (err: any) {
      setFeedback({ message: err.message || "Erreur de chargement des documents", type: "error" });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDocuments(statutFilter);
  }, [statutFilter]);

  // Regroupement des documents par utilisateur
  const userGroups: UserDocGroup[] = React.useMemo(() => {
    const map = new Map<string, UserDocGroup>();

    documents.forEach((doc) => {
      const user = doc.utilisateur || {
        id: doc.utilisateurId || "inconnu",
        nomComplet: "Utilisateur Inconnu",
        email: "Non renseigné",
        telephone: "Non renseigné",
      };

      const key = user.id || user.telephone || "inconnu";
      if (!map.has(key)) {
        map.set(key, {
          user: {
            id: key,
            nomComplet: user.nomComplet,
            email: user.email,
            telephone: user.telephone,
          },
          docs: [],
        });
      }
      map.get(key)!.docs.push(doc);
    });

    return Array.from(map.values());
  }, [documents]);

  const toggleUserExpanded = (userId: string) => {
    setExpandedUsers((prev) => ({
      ...prev,
      [userId]: !prev[userId],
    }));
  };

  const handleValider = async (docId: string) => {
    setSubmitting(true);
    setFeedback(null);
    try {
      await apiRequest(`/admin/documents/${docId}/valider`, { method: "POST" });
      setFeedback({ message: "Document validé avec succès !", type: "success" });
      setSelectedDoc(null);
      fetchDocuments(statutFilter);
    } catch (err: any) {
      setFeedback({ message: err.message || "Erreur lors de la validation", type: "error" });
    } finally {
      setSubmitting(false);
    }
  };

  const handleRejeterSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!rejectingDoc) return;

    setSubmitting(true);
    setFeedback(null);
    try {
      await apiRequest(`/admin/documents/${rejectingDoc.id}/rejeter`, {
        method: "POST",
        body: JSON.stringify({ motif: motifRejet }),
      });
      setFeedback({ message: "Document rejeté avec motif.", type: "success" });
      setRejectingDoc(null);
      setSelectedDoc(null);
      fetchDocuments(statutFilter);
    } catch (err: any) {
      setFeedback({ message: err.message || "Erreur lors du rejet du document", type: "error" });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-950">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header title="File de Modération KYC & Preuves de Propriété" />

        <main className="p-8 space-y-6 flex-1 overflow-y-auto">
          {/* Filters Bar */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-4 rounded-2xl">
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider mr-2">
                Filtrer par statut :
              </span>
              {[
                { key: "EN_ATTENTE", label: "En Attente de Validation" },
                { key: "VALIDE", label: "Validés" },
                { key: "REJETE", label: "Rejetés" },
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
              <span className="font-semibold text-white">{userGroups.length}</span> utilisateur(s) •{" "}
              <span className="font-semibold text-white">{documents.length}</span> document(s)
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

          {/* User Accordions */}
          {loading ? (
            <div className="text-center py-20 text-slate-500 text-sm">Chargement des dossiers d&apos;utilisateurs...</div>
          ) : userGroups.length === 0 ? (
            <div className="text-center py-20 border border-dashed border-slate-800 rounded-2xl bg-slate-900/40">
              <svg className="w-12 h-12 text-slate-600 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p className="text-slate-300 font-semibold text-base">Aucun dossier trouvé pour le statut ({statutFilter})</p>
            </div>
          ) : (
            <div className="space-y-4">
              {userGroups.map((group) => {
                const isExpanded = !!expandedUsers[group.user.id];
                return (
                  <div
                    key={group.user.id}
                    className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden transition-all"
                  >
                    {/* User Header Accordion Banner */}
                    <div
                      onClick={() => toggleUserExpanded(group.user.id)}
                      className="p-5 flex items-center justify-between cursor-pointer hover:bg-slate-800/60 transition-colors select-none"
                    >
                      <div className="flex items-center gap-4">
                        <div className="w-11 h-11 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-base text-emerald-400 shrink-0 shadow-md">
                          {group.user.nomComplet ? group.user.nomComplet.charAt(0).toUpperCase() : "U"}
                        </div>
                        <div>
                          <div className="flex items-center gap-3">
                            <h3 className="font-bold text-white text-base">
                              {group.user.nomComplet || "Utilisateur"}
                            </h3>
                            <span className="text-xs font-semibold text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-2.5 py-0.5 rounded-full">
                              {group.docs.length} document(s)
                            </span>
                          </div>

                          <div className="flex items-center gap-4 text-xs text-slate-400 mt-1">
                            <span className="flex items-center gap-1">
                              ✉️ {group.user.email || "Email non renseigné"}
                            </span>
                            <span className="flex items-center gap-1 font-mono">
                              📞 {group.user.telephone}
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* Chevron Icon */}
                      <div className="p-2 text-slate-400 hover:text-white rounded-lg transition-transform duration-200">
                        <svg
                          className={`w-6 h-6 transform transition-transform duration-200 ${isExpanded ? "rotate-180 text-emerald-400" : ""}`}
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
                        </svg>
                      </div>
                    </div>

                    {/* Accordion Content : Documents List */}
                    {isExpanded && (
                      <div className="p-5 border-t border-slate-800 bg-slate-950/40">
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                          {group.docs.map((doc) => (
                            <div
                              key={doc.id}
                              className="bg-slate-900 border border-slate-800 hover:border-slate-700 p-4 rounded-xl flex flex-col justify-between space-y-3"
                            >
                              <div className="space-y-2">
                                <div className="flex items-center justify-between">
                                  <span className="font-mono text-xs font-bold text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-2.5 py-1 rounded-lg">
                                    {doc.type}
                                  </span>
                                  <span className="text-[10px] text-slate-400">
                                    {doc.createdAt ? new Date(doc.createdAt).toLocaleDateString("fr-FR") : "—"}
                                  </span>
                                </div>

                                {doc.bien ? (
                                  <p className="text-xs text-slate-300">
                                    🏠 Bien rattaché : <span className="font-mono font-semibold text-white">{doc.bien.reference}</span> ({doc.bien.titre || doc.bien.ville})
                                  </p>
                                ) : (
                                  <p className="text-xs text-slate-500">
                                    🪪 Justificatif de compte (Global KYC)
                                  </p>
                                )}
                              </div>

                              <div className="pt-2 border-t border-slate-800 flex items-center justify-between">
                                <button
                                  onClick={() => setSelectedDoc(doc)}
                                  className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold rounded-lg transition-colors flex items-center gap-1"
                                >
                                  <span>👁️ Examiner</span>
                                </button>

                                <div className="flex items-center gap-1.5">
                                  <button
                                    onClick={() => setRejectingDoc(doc)}
                                    className="px-2.5 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 text-xs font-medium rounded-lg border border-rose-500/20"
                                  >
                                    Rejeter
                                  </button>
                                  <button
                                    onClick={() => handleValider(doc.id)}
                                    className="px-3 py-1.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 text-xs font-bold rounded-lg shadow-sm"
                                  >
                                    Valider
                                  </button>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </main>
      </div>

      {/* Modal Visualiseur de Document */}
      {selectedDoc && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl max-w-2xl w-full flex flex-col shadow-2xl overflow-hidden max-h-[90vh]">
            <div className="p-6 border-b border-slate-800 flex items-center justify-between">
              <div>
                <span className="text-xs font-mono text-emerald-400">{selectedDoc.type}</span>
                <h3 className="text-lg font-bold text-white mt-0.5">
                  Document de {selectedDoc.utilisateur?.nomComplet || selectedDoc.utilisateur?.telephone}
                </h3>
              </div>
              <button
                onClick={() => setSelectedDoc(null)}
                className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl"
              >
                ✕
              </button>
            </div>

            <div className="p-6 overflow-y-auto space-y-4 flex-1">
              <div className="bg-slate-950 p-4 rounded-2xl border border-slate-800 flex items-center justify-between text-xs">
                <div>
                  <span className="text-slate-500 block">Identifiant unique du document</span>
                  <span className="font-mono text-slate-300">{selectedDoc.id}</span>
                </div>
                <a
                  href={getDocumentUrl(selectedDoc.id)}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold rounded-lg transition-colors flex items-center gap-1.5"
                >
                  <span>Télécharger Fichier</span>
                  <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                </a>
              </div>

              {/* Document Image Preview */}
              <div className="bg-slate-950 rounded-2xl border border-slate-800 p-2 flex items-center justify-center min-h-[300px]">
                <img
                  src={getDocumentUrl(selectedDoc.id)}
                  alt="Aperçu du document"
                  className="max-h-[400px] w-auto object-contain rounded-xl"
                  onError={(e) => {
                    (e.target as HTMLElement).style.display = "none";
                  }}
                />
              </div>
            </div>

            <div className="p-6 border-t border-slate-800 bg-slate-950 flex items-center justify-end gap-3">
              <button
                onClick={() => setRejectingDoc(selectedDoc)}
                disabled={submitting}
                className="px-4 py-2.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 font-semibold rounded-xl text-xs"
              >
                Rejeter Document
              </button>
              <button
                onClick={() => handleValider(selectedDoc.id)}
                disabled={submitting}
                className="px-5 py-2.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold rounded-xl text-xs shadow-lg shadow-emerald-500/20"
              >
                {submitting ? "Validation..." : "Valider le Document"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Motif Rejet Document */}
      {rejectingDoc && (
        <div className="fixed inset-0 bg-slate-950/90 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <h3 className="text-lg font-bold text-white">Motif du Rejet du Document</h3>
            <p className="text-xs text-slate-400">Précisez la raison pour laquelle la pièce est refusée :</p>

            <form onSubmit={handleRejeterSubmit} className="space-y-4">
              <div className="space-y-2">
                {[
                  "Document illisible ou flou",
                  "Document périmé ou expiré",
                  "Ne correspond pas au titulaire du compte",
                  "Type de pièce non conforme",
                ].map((option) => (
                  <label key={option} className="flex items-center gap-3 p-3 bg-slate-950 border border-slate-800 rounded-xl cursor-pointer hover:border-slate-700">
                    <input
                      type="radio"
                      name="motifDoc"
                      value={option}
                      checked={motifRejet === option}
                      onChange={(e) => setMotifRejet(e.target.value)}
                      className="text-emerald-500"
                    />
                    <span className="text-xs text-slate-200 font-medium">{option}</span>
                  </label>
                ))}
              </div>

              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setRejectingDoc(null)}
                  className="px-4 py-2 bg-slate-800 text-slate-300 text-xs font-semibold rounded-xl"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-4 py-2 bg-rose-500 hover:bg-rose-400 text-white text-xs font-bold rounded-xl"
                >
                  {submitting ? "Traitement..." : "Confirmer le Rejet"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
