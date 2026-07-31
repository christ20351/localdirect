import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PaiementsController } from './paiements.controller';
import { PAYMENT_PROVIDER_TOKEN } from './providers/payment-provider.interface';
import { SandboxPaymentProvider } from './providers/sandbox-payment.provider';

@Module({
  controllers: [PaiementsController],
  providers: [
    SandboxPaymentProvider,
    {
      provide: PAYMENT_PROVIDER_TOKEN,
      // PSP_PROVIDER=campay|fapshi|monetbil basculera vers une vraie implémentation
      // le jour où des identifiants d'agrégateur seront disponibles. En attendant,
      // seul "sandbox" existe : on y retombe toujours pour ne jamais bloquer le flux.
      useFactory: (configService: ConfigService, sandboxProvider: SandboxPaymentProvider) => {
        const provider = configService.get<string>('PSP_PROVIDER') || 'sandbox';
        if (provider !== 'sandbox') {
          // eslint-disable-next-line no-console
          console.warn(`PSP_PROVIDER="${provider}" non implémenté pour le moment : utilisation du sandbox.`);
        }
        return sandboxProvider;
      },
      inject: [ConfigService, SandboxPaymentProvider],
    },
  ],
  exports: [PAYMENT_PROVIDER_TOKEN],
})
export class PaiementsModule {}
