/// Types de documents acceptés, tels que définis par le "faisceau d'indices" de
/// preuve de propriété (README_1.md §11 : au moins 2 des 4) et le KYC agent
/// (docs/roles_et_fonctionnalites.md §2.A : CNI + Selfie + numéro MoMo).
export const TYPES_PREUVE_PROPRIETE = [
  'FACTURE_ENEO_CAMWATER',
  'CNI_SELFIE_BAILLEUR',
  'TITRE_PROPRIETE',
  'BAIL_OU_QUITTANCE',
] as const;

export const SEUIL_PREUVE_PROPRIETE = 2;

export const TYPES_KYC_AGENT = ['CNI_AGENT_RECTO', 'CNI_AGENT_VERSO', 'SELFIE_AGENT'] as const;

export const TOUS_TYPES_DOCUMENTS = [...TYPES_PREUVE_PROPRIETE, ...TYPES_KYC_AGENT] as const;

export type TypeDocument = (typeof TOUS_TYPES_DOCUMENTS)[number];
