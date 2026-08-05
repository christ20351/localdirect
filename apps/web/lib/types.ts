// Shapes returned by the public LocaDirect CM API (apps/api).
// Mirrored by hand from apps/api/src/geo/geo.service.ts and
// apps/api/src/annonces/annonces.service.ts#formatAnnonceResponse.
// Keep these in sync if the API response shape changes.

export type StatutVille = "OUVERTE" | "FERMEE" | "BIENTOT";

export type Ville = {
  id: string;
  nom: string;
  region: string;
  slug: string;
  statut: StatutVille;
  latitude: number | null;
  longitude: number | null;
  parametres?: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
};

export type Repere = {
  id: string;
  quartierId: string;
  nom: string;
  latitude: number | null;
  longitude: number | null;
};

export type Quartier = {
  id: string;
  villeId: string;
  nom: string;
  slug: string;
  aliases: string[];
  latitude: number | null;
  longitude: number | null;
  actif: boolean;
  reperes: Repere[];
};

export type TypeBien =
  | "CHAMBRE_SIMPLE"
  | "CHAMBRE_MODERNE"
  | "STUDIO"
  | "APPARTEMENT"
  | "DUPLEX"
  | "MAISON"
  | "VILLA"
  | "BOUTIQUE"
  | "BUREAU"
  | "TERRAIN";

export type StatutBien =
  | "BROUILLON"
  | "EN_VERIFICATION"
  | "DISPONIBLE"
  | "LOUE"
  | "REJETE"
  | string;

export type AnnonceFinances = {
  loyerMensuelXAF: number;
  chargesMensuellesXAF: number;
  chargesIncluses: boolean;
  avanceMois: number;
  montantAvanceXAF: number;
  cautionMois: number;
  montantCautionXAF: number;
  totalInitialEntreeXAF: number;
};

export type AnnonceBien = {
  id: string;
  reference: string;
  type: TypeBien;
  statut: StatutBien;
  meuble: boolean;
  equipements: string[];
  // Display names only (not slugs) — the search API returns human-readable
  // ville/quartier names here, never slugs.
  ville: string | null;
  quartier: string | null;
  pointRepere: string | null;
  latitudeFloue: number | null;
  longitudeFloue: number | null;
  photos: string[];
  bailleurTel: string | null;
  bailleurWhatsapp: string | null;
};

export type Annonce = {
  id: string;
  titre: string;
  description: string;
  finances: AnnonceFinances;
  bien: AnnonceBien;
  nbVues: number;
  createdAt: string;
};

export type AnnoncesSearchResult = {
  data: Annonce[];
  meta: {
    total: number;
    page: number;
    limit: number;
    pagesTotal: number;
  };
};

export type AnnonceSearchFilters = {
  ville?: string;
  quartier?: string;
  type?: TypeBien;
  loyerMin?: string;
  loyerMax?: string;
  avanceMax?: string;
  meuble?: "true" | "false";
  nbPieces?: string;
  page?: string;
  limit?: string;
};
