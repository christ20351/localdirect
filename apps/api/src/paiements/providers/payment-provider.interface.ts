import { MethodePaiement } from '@prisma/client';

export interface InitierPaiementOptions {
  montant: number; // XAF, entier
  methode: MethodePaiement;
  numero: string; // numéro Mobile Money du payeur
  reference: string; // référence interne du paiement (traçabilité PSP)
}

export interface PaiementProviderResult {
  statut: 'REUSSI' | 'ECHOUE' | 'EN_ATTENTE';
  pspReference?: string;
  erreur?: string;
}

/**
 * Interface interchangeable pour l'agrégateur de paiement Mobile Money
 * (CamPay, Fapshi, Monetbil...), sur le même principe que IOtpProvider :
 * une variable d'environnement (PSP_PROVIDER) sélectionne l'implémentation
 * réelle sans changer le code appelant.
 */
export interface IPaymentProvider {
  initierPaiement(options: InitierPaiementOptions): Promise<PaiementProviderResult>;
}

export const PAYMENT_PROVIDER_TOKEN = Symbol('PAYMENT_PROVIDER_TOKEN');
