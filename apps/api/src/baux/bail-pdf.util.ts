import * as fs from 'fs';
import * as path from 'path';
import PDFDocument from 'pdfkit';
import { BAUX_DIR } from '../uploads/storage.util';

const TEMPLATES_DIR = path.join(process.cwd(), '..', '..', 'packages', 'contracts', 'templates');
const REGIONS_COMMON_LAW = ['nord-ouest', 'sud-ouest', 'north-west', 'south-west', 'nw', 'sw'];

/// Régions anglophones (droit commun) vs le reste (droit civil francophone) —
/// cf. README_1.md §10 ("Gabarits séparés pour le droit civil et la common law").
export function estZoneCommonLaw(region: string | undefined | null): boolean {
  if (!region) return false;
  return REGIONS_COMMON_LAW.includes(region.trim().toLowerCase());
}

function formatMontant(montant: number): string {
  return new Intl.NumberFormat('fr-FR').format(montant);
}

function formatDate(date: Date | string | null | undefined): string {
  if (!date) return '—';
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' });
}

interface DonneesBailPdf {
  reference: string;
  dateDebut: Date | string | null;
  bailleurNom: string;
  bailleurTel: string;
  locataireNom: string;
  locataireTel: string;
  typeBien: string;
  villeNom: string;
  quartierNom: string;
  pointRepereNom: string;
  loyerMensuel: number;
  chargesMensuelles: number;
  avanceMois: number;
  avanceMontant: number;
  cautionMois: number;
  cautionMontant: number;
  jourEcheance: number;
}

/// Remplit le gabarit markdown ({{JETON}}) avec les données réelles du bail —
/// on ne stocke pas de numéro de CNI en clair sur le compte utilisateur (seules
/// les images de documents KYC existent), donc ces deux champs restent "voir
/// dossier vérifié par le Staff" plutôt qu'une valeur inventée.
function remplirGabarit(gabarit: string, d: DonneesBailPdf): string {
  const jetons: Record<string, string> = {
    BAIL_REFERENCE: d.reference,
    DATE_SIGNATURE: formatDate(new Date()),
    VILLE_NOM: d.villeNom,
    BAILLEUR_NOM: d.bailleurNom,
    BAILLEUR_TEL: d.bailleurTel,
    BAILLEUR_CNI: 'Voir dossier vérifié par le Staff LocaDirect CM',
    LOCATAIRE_NOM: d.locataireNom,
    LOCATAIRE_TEL: d.locataireTel,
    LOCATAIRE_CNI: 'Voir dossier vérifié par le Staff LocaDirect CM',
    TYPE_BIEN: d.typeBien,
    QUARTIER_NOM: d.quartierNom,
    POINT_REPERE_NOM: d.pointRepereNom || 'Non renseigné',
    LOYER_MENSUEL: formatMontant(d.loyerMensuel),
    CHARGES_MENSUELLES: formatMontant(d.chargesMensuelles),
    AVANCE_MOIS: String(d.avanceMois),
    AVANCE_MONTANT: formatMontant(d.avanceMontant),
    CAUTION_MOIS: String(d.cautionMois),
    CAUTION_MONTANT: formatMontant(d.cautionMontant),
    JOUR_ECHEANCE: String(d.jourEcheance),
  };
  return gabarit.replace(/{{(\w+)}}/g, (match, jeton) => jetons[jeton] ?? match);
}

/// Rendu texte minimal du markdown du gabarit en PDF : suffisant pour un
/// contrat lisible (titres, listes, séparateurs) sans dépendance lourde
/// (pas de Chromium headless nécessaire sur le VPS).
function ecrireMarkdownDansPdf(doc: PDFKit.PDFDocument, markdown: string) {
  const lignes = markdown.split('\n');
  for (const ligneBrute of lignes) {
    const ligne = ligneBrute.trim();
    if (!ligne) {
      doc.moveDown(0.5);
      continue;
    }
    if (ligne === '---') {
      doc.moveDown(0.3);
      continue;
    }
    if (ligne.startsWith('### ')) {
      doc.moveDown(0.5).font('Helvetica-Bold').fontSize(12).text(ligne.replace(/^###\s+/, ''));
      doc.font('Helvetica').fontSize(10);
      continue;
    }
    if (ligne.startsWith('# ')) {
      doc.font('Helvetica-Bold').fontSize(16).text(ligne.replace(/^#\s+/, ''), { align: 'center' });
      doc.font('Helvetica').fontSize(10);
      continue;
    }
    const texteSansMarkdown = ligne.replace(/\*\*(.*?)\*\*/g, '$1').replace(/^\*\s+/, '• ');
    doc.text(texteSansMarkdown);
  }
}

/// Génère (ou régénère) le PDF du bail sur disque et renvoie le chemin absolu.
export async function genererBailPdf(donnees: DonneesBailPdf, communLaw: boolean): Promise<string> {
  const nomFichier = TEMPLATES_DIR;
  const gabaritPath = path.join(nomFichier, communLaw ? 'lease_common_law_en.md' : 'lease_civil_law_fr.md');
  const gabarit = fs.readFileSync(gabaritPath, 'utf-8');
  const contenu = remplirGabarit(gabarit, donnees);

  fs.mkdirSync(BAUX_DIR, { recursive: true });
  const cheminSortie = path.join(BAUX_DIR, `${donnees.reference}.pdf`);

  await new Promise<void>((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 50 });
    const stream = fs.createWriteStream(cheminSortie);
    doc.pipe(stream);
    doc.font('Helvetica').fontSize(10);
    ecrireMarkdownDansPdf(doc, contenu);
    doc.end();
    stream.on('finish', () => resolve());
    stream.on('error', reject);
  });

  return cheminSortie;
}
