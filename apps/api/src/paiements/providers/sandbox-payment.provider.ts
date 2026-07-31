import { Injectable, Logger } from '@nestjs/common';
import { IPaymentProvider, InitierPaiementOptions, PaiementProviderResult } from './payment-provider.interface';

/**
 * Implémentation de secours utilisée tant qu'aucun agrégateur MoMo réel
 * (CamPay/Fapshi/Monetbil) n'est configuré. Simule un paiement Mobile Money
 * réussi après un court délai (comme le ferait un vrai PSP avant son webhook),
 * pour que tout le cycle de vie de la visite soit testable de bout en bout.
 */
@Injectable()
export class SandboxPaymentProvider implements IPaymentProvider {
  private readonly logger = new Logger(SandboxPaymentProvider.name);

  async initierPaiement(options: InitierPaiementOptions): Promise<PaiementProviderResult> {
    this.logger.log(
      `💳 [SANDBOX MoMo] Simulation d'un paiement de ${options.montant} XAF via ${options.methode} (${options.numero}) — réf ${options.reference}`,
    );

    await new Promise((resolve) => setTimeout(resolve, 1500));

    return {
      statut: 'REUSSI',
      pspReference: `sandbox-${Date.now()}`,
    };
  }
}
