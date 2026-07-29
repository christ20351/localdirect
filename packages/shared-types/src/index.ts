export enum RoleUtilisateur {
  LOCATAIRE = 'LOCATAIRE',
  BAILLEUR = 'BAILLEUR',
  AGENT = 'AGENT',
  STAFF = 'STAFF',
  ADMIN = 'ADMIN',
}

export enum StatutKyc {
  NON_SOUMIS = 'NON_SOUMIS',
  EN_ATTENTE = 'EN_ATTENTE',
  VALIDE = 'VALIDE',
  REJETE = 'REJETE',
  EXPIRE = 'EXPIRE',
}

export enum StatutVille {
  FERMEE = 'FERMEE',
  PRE_LANCEMENT = 'PRE_LANCEMENT',
  OUVERTE = 'OUVERTE',
}

export enum TypeBien {
  CHAMBRE_SIMPLE = 'CHAMBRE_SIMPLE',
  CHAMBRE_MODERNE = 'CHAMBRE_MODERNE',
  STUDIO = 'STUDIO',
  APPARTEMENT = 'APPARTEMENT',
  DUPLEX = 'DUPLEX',
  MAISON = 'MAISON',
  VILLA = 'VILLA',
  BOUTIQUE = 'BOUTIQUE',
  BUREAU = 'BUREAU',
  TERRAIN = 'TERRAIN',
}

export enum StatutBien {
  BROUILLON = 'BROUILLON',
  EN_VERIFICATION = 'EN_VERIFICATION',
  DISPONIBLE = 'DISPONIBLE',
  RESERVE = 'RESERVE',
  LOUE = 'LOUE',
  SUSPENDU = 'SUSPENDU',
  EXPIRE = 'EXPIRE',
  REJETE = 'REJETE',
}

export enum StatutVisite {
  DEMANDEE = 'DEMANDEE',
  PAYEE = 'PAYEE',
  PLANIFIEE = 'PLANIFIEE',
  CHECK_IN = 'CHECK_IN',
  REALISEE = 'REALISEE',
  CONFIRMEE = 'CONFIRMEE',
  CONTESTEE = 'CONTESTEE',
  ANNULEE = 'ANNULEE',
  REMBOURSEE = 'REMBOURSEE',
  NO_SHOW = 'NO_SHOW',
}

export enum StatutPaiement {
  INITIE = 'INITIE',
  EN_ATTENTE = 'EN_ATTENTE',
  REUSSI = 'REUSSI',
  ECHOUE = 'ECHOUE',
  ANNULE = 'ANNULE',
  REMBOURSE = 'REMBOURSE',
}

export enum MethodePaiement {
  MTN_MOMO = 'MTN_MOMO',
  ORANGE_MONEY = 'ORANGE_MONEY',
  CARTE = 'CARTE',
  VIREMENT = 'VIREMENT',
  ESPECES = 'ESPECES',
}

export interface VilleDto {
  id: string;
  nom: string;
  region: string;
  slug: string;
  statut: StatutVille;
}

export interface QuartierDto {
  id: string;
  villeId: string;
  nom: string;
  slug: string;
  aliases: string[];
}

export interface AnnonceDto {
  id: string;
  titre: string;
  description?: string;
  loyerMensuel: number; // En XAF (BIGINT entiers)
  chargesMensuelles: number;
  avanceMois: number;
  cautionMois: number;
  typeBien: TypeBien;
  quartierNom: string;
  villeNom: string;
  medias: string[];
  disponibleLe?: string;
  scoreFraicheur?: number;
}
