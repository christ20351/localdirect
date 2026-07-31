import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StatutBien, StatutVisite, StatutPaiement } from '@prisma/client';
import { CreerVisiteDto } from './dtos/creer-visite.dto';
import { PayerVisiteDto } from './dtos/payer-visite.dto';
import { ContesterVisiteDto } from './dtos/contester-visite.dto';
import type { IPaymentProvider } from '../paiements/providers/payment-provider.interface';
import { PAYMENT_PROVIDER_TOKEN } from '../paiements/providers/payment-provider.interface';

const VISITE_EN_COURS: StatutVisite[] = ['DEMANDEE', 'PAYEE', 'PLANIFIEE', 'CHECK_IN'];
const VISITE_TERMINABLE: StatutVisite[] = ['PAYEE', 'PLANIFIEE', 'CHECK_IN', 'REALISEE'];
const FRAIS_VISITE_DEFAUT_XAF = 2000;

@Injectable()
export class VisitesService {
  private readonly logger = new Logger(VisitesService.name);

  constructor(
    private prisma: PrismaService,
    @Inject(PAYMENT_PROVIDER_TOKEN) private paymentProvider: IPaymentProvider,
  ) {}

  /// 📅 Demander une visite sur une annonce (locataire)
  async demanderVisite(locataireId: string, annonceId: string, dto: CreerVisiteDto) {
    const annonce = await this.prisma.annonce.findUnique({
      where: { id: annonceId },
      include: { bien: { include: { ville: true } } },
    });
    if (!annonce) {
      throw new NotFoundException(`Annonce introuvable pour l'ID : ${annonceId}`);
    }
    if (annonce.bien.statut !== StatutBien.DISPONIBLE) {
      throw new BadRequestException('Ce bien n\'est plus disponible à la visite.');
    }

    const dejaEnCours = await this.prisma.visite.findFirst({
      where: { annonceId, locataireId, statut: { in: VISITE_EN_COURS } },
    });
    if (dejaEnCours) {
      throw new ConflictException('Vous avez déjà une visite en cours pour cette annonce.');
    }

    const parametres = (annonce.bien.ville.parametres as Record<string, unknown>) ?? {};
    const fraisVisite = Number(parametres.fraisVisite ?? FRAIS_VISITE_DEFAUT_XAF);

    const visite = await this.prisma.visite.create({
      data: {
        annonceId,
        locataireId,
        statut: StatutVisite.DEMANDEE,
        frais: BigInt(fraisVisite),
        creneauDebut: dto.creneauSouhaite ? new Date(dto.creneauSouhaite) : null,
      },
    });

    return this.formatVisite(visite);
  }

  /// 💳 Payer les frais de visite (Mobile Money, via PaymentProvider interchangeable)
  async payerVisite(locataireId: string, visiteId: string, dto: PayerVisiteDto) {
    const visite = await this.getVisiteOuEchoue(visiteId);
    if (visite.locataireId !== locataireId) {
      throw new ForbiddenException('Cette visite ne vous appartient pas.');
    }
    if (visite.statut !== StatutVisite.DEMANDEE) {
      throw new BadRequestException('Cette visite a déjà été payée ou n\'est plus payable.');
    }

    const reference = `VIS-${visite.id.slice(0, 8).toUpperCase()}-${Date.now()}`;
    const paiement = await this.prisma.paiement.create({
      data: {
        reference,
        payeurId: locataireId,
        type: 'FRAIS_VISITE',
        statut: StatutPaiement.INITIE,
        methode: dto.methode,
        montant: visite.frais,
        visiteId: visite.id,
        idempotencyKey: reference,
      },
    });

    const resultat = await this.paymentProvider.initierPaiement({
      montant: Number(visite.frais),
      methode: dto.methode,
      numero: dto.numero,
      reference,
    });

    if (resultat.statut === 'REUSSI') {
      // Code remis par le locataire à l'agent une fois sur place, pour valider la visite.
      const codeConfirmation = Math.floor(1000 + Math.random() * 9000).toString();

      await this.prisma.$transaction([
        this.prisma.paiement.update({
          where: { id: paiement.id },
          data: { statut: StatutPaiement.REUSSI, regleLe: new Date() },
        }),
        this.prisma.visite.update({
          where: { id: visite.id },
          data: { statut: StatutVisite.PAYEE, paiementId: paiement.id, codeConfirmation },
        }),
        this.prisma.annonce.update({
          where: { id: visite.annonceId },
          data: { nbDemandesVisite: { increment: 1 } },
        }),
        this.prisma.ecriture.createMany({
          data: [
            { paiementId: paiement.id, compte: `CLIENT:${locataireId}`, sens: 'D', montant: visite.frais, libelle: 'Frais de visite' },
            { paiementId: paiement.id, compte: 'PLATEFORME', sens: 'C', montant: visite.frais, libelle: 'Frais de visite' },
          ],
        }),
      ]);
    } else {
      await this.prisma.paiement.update({
        where: { id: paiement.id },
        data: { statut: StatutPaiement.ECHOUE },
      });
    }

    const visiteActualisee = await this.getVisiteOuEchoue(visite.id);
    return {
      paiementId: paiement.id,
      statutPaiement: resultat.statut,
      visite: this.formatVisite(visiteActualisee),
    };
  }

  /// 🔍 Détail d'une visite (propriétaire uniquement)
  async getVisite(userId: string, visiteId: string) {
    const visite = await this.getVisiteOuEchoue(visiteId);
    if (visite.locataireId !== userId) {
      throw new ForbiddenException('Cette visite ne vous appartient pas.');
    }
    return this.formatVisite(visite);
  }

  /// 📋 Visites du locataire connecté
  async getMesVisites(locataireId: string) {
    const visites = await this.prisma.visite.findMany({
      where: { locataireId },
      orderBy: { createdAt: 'desc' },
      include: {
        annonce: {
          include: {
            bien: { include: { ville: true, quartier: true, medias: true } },
          },
        },
      },
    });
    return visites.map((v) => this.formatVisite(v));
  }

  /// ✅ Le locataire confirme que le bien correspond à l'annonce
  async confirmerVisite(locataireId: string, visiteId: string) {
    const visite = await this.getVisiteOuEchoue(visiteId);
    if (visite.locataireId !== locataireId) {
      throw new ForbiddenException('Cette visite ne vous appartient pas.');
    }
    if (visite.statut === StatutVisite.CONFIRMEE) {
      return this.formatVisite(visite);
    }
    if (!VISITE_TERMINABLE.includes(visite.statut)) {
      throw new BadRequestException('Cette visite ne peut pas être confirmée dans son état actuel.');
    }

    const updated = await this.prisma.visite.update({
      where: { id: visiteId },
      data: { statut: StatutVisite.CONFIRMEE, confirmeeLe: new Date() },
    });
    return this.formatVisite(updated);
  }

  /// ⚠️ Le locataire signale un problème (bien indisponible, non conforme...)
  /// Rembourse automatiquement — dans ce MVP sans réseau d'agents, il n'y a pas
  /// encore de contre-partie côté agent pour contester le signalement, donc le
  /// remboursement est immédiat plutôt que différé de 24h comme prévu à terme.
  async contesterVisite(locataireId: string, visiteId: string, dto: ContesterVisiteDto) {
    const visite = await this.getVisiteOuEchoue(visiteId);
    if (visite.locataireId !== locataireId) {
      throw new ForbiddenException('Cette visite ne vous appartient pas.');
    }
    if (!VISITE_TERMINABLE.includes(visite.statut)) {
      throw new BadRequestException('Cette visite ne peut pas être contestée dans son état actuel.');
    }

    const maintenant = new Date();
    await this.prisma.visite.update({
      where: { id: visiteId },
      data: {
        statut: StatutVisite.REMBOURSEE,
        motifContestation: dto.motif,
        rembourseLe: maintenant,
      },
    });

    if (visite.paiementId) {
      await this.prisma.$transaction([
        this.prisma.paiement.update({
          where: { id: visite.paiementId },
          data: { statut: StatutPaiement.REMBOURSE },
        }),
        this.prisma.ecriture.createMany({
          data: [
            { paiementId: visite.paiementId, compte: 'PLATEFORME', sens: 'D', montant: visite.frais, libelle: `Remboursement visite (${dto.motif})` },
            { paiementId: visite.paiementId, compte: `CLIENT:${locataireId}`, sens: 'C', montant: visite.frais, libelle: `Remboursement visite (${dto.motif})` },
          ],
        }),
      ]);
    }

    this.logger.log(`Visite ${visiteId} contestée (${dto.motif}) et remboursée automatiquement.`);

    const updated = await this.getVisiteOuEchoue(visiteId);
    return this.formatVisite(updated);
  }

  private async getVisiteOuEchoue(visiteId: string) {
    const visite = await this.prisma.visite.findUnique({
      where: { id: visiteId },
      include: {
        annonce: {
          include: {
            bien: { include: { ville: true, quartier: true, medias: true } },
          },
        },
      },
    });
    if (!visite) {
      throw new NotFoundException(`Visite introuvable pour l'ID : ${visiteId}`);
    }
    return visite;
  }

  private formatVisite(visite: any) {
    return {
      id: visite.id,
      annonceId: visite.annonceId,
      statut: visite.statut,
      fraisXAF: Number(visite.frais),
      creneauDebut: visite.creneauDebut,
      codeConfirmation: visite.codeConfirmation,
      motifContestation: visite.motifContestation,
      confirmeeLe: visite.confirmeeLe,
      rembourseLe: visite.rembourseLe,
      createdAt: visite.createdAt,
      annonce: visite.annonce
        ? {
            id: visite.annonce.id,
            titre: visite.annonce.titre,
            ville: visite.annonce.bien?.ville?.nom,
            quartier: visite.annonce.bien?.quartier?.nom,
            photo: visite.annonce.bien?.medias?.[0]?.storageKey,
          }
        : undefined,
    };
  }
}
