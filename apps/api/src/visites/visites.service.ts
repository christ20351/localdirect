import { Injectable, NotFoundException, BadRequestException, ConflictException, ForbiddenException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StatutBien, StatutVisite } from '@prisma/client';
import { CreerVisiteDto } from './dtos/creer-visite.dto';
import { ContesterVisiteDto } from './dtos/contester-visite.dto';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';

/// Locataire ↔ Bailleur en contact direct (WhatsApp/appel affichés sur l'annonce, plus
/// d'agent intermédiaire, plus de frais de visite à payer). La `Visite` sert uniquement
/// à déclarer qu'on a visité un bien et à donner un signal de conformité au catalogue.
@Injectable()
export class VisitesService {
  private readonly logger = new Logger(VisitesService.name);

  constructor(
    private prisma: PrismaService,
    private auditService: AuditService,
    private notificationsService: NotificationsService,
  ) {}

  /// 📅 Déclarer l'intention/le fait d'avoir visité un bien (locataire)
  /// Réservé au locataire dont le dossier de candidature a été accepté par le
  /// bailleur : c'est cette acceptation qui déclenche le passage du bien en
  /// `RESERVE`, donc on ne peut plus se fier à `bien.statut === DISPONIBLE`
  /// à ce stade — la légitimité vient de la candidature acceptée.
  async demanderVisite(locataireId: string, annonceId: string, dto: CreerVisiteDto) {
    const annonce = await this.prisma.annonce.findUnique({
      where: { id: annonceId },
      include: { bien: true },
    });
    if (!annonce) {
      throw new NotFoundException(`Annonce introuvable pour l'ID : ${annonceId}`);
    }

    const candidatureAcceptee = await this.prisma.candidature.findFirst({
      where: { annonceId, locataireId, statut: 'ACCEPTEE' },
    });
    if (!candidatureAcceptee) {
      throw new ForbiddenException(
        "Votre dossier de candidature doit être accepté par le bailleur avant de pouvoir signaler une visite sur ce bien.",
      );
    }

    const dejaEnCours = await this.prisma.visite.findFirst({
      where: { annonceId, locataireId, statut: StatutVisite.DEMANDEE },
    });
    if (dejaEnCours) {
      throw new ConflictException('Vous avez déjà une visite en cours pour cette annonce.');
    }

    const visite = await this.prisma.visite.create({
      data: {
        annonceId,
        locataireId,
        statut: StatutVisite.DEMANDEE,
        frais: BigInt(0),
        creneauDebut: dto.creneauSouhaite ? new Date(dto.creneauSouhaite) : null,
      },
    });

    await this.prisma.annonce.update({
      where: { id: annonceId },
      data: { nbDemandesVisite: { increment: 1 } },
    });

    return this.formatVisite(visite);
  }

  /// 🔍 Détail d'une visite (propriétaire uniquement)
  async getVisite(userId: string, visiteId: string) {
    const visite = await this.getVisiteOuEchoue(visiteId);
    if (visite.locataireId !== userId) {
      throw new ForbiddenException('Cette visite ne vous appartient pas.');
    }
    return this.formatVisite(visite);
  }

  /// 🛡️ File des visites signalées non conformes — réservé au Staff/Admin
  /// (contrôle qualité du catalogue : plus de remboursement automatique à
  /// déclencher puisqu'aucun paiement n'est collecté, juste un signal à instruire).
  /// Par défaut (pas de `statut` explicite) : uniquement les biens encore en
  /// quarantaine (`SUSPENDU`) — dès que le staff tranche (valide → à nouveau
  /// disponible, ou rejette → retiré), le dossier sort naturellement de la file.
  async getVisitesEnLitige(statut?: string) {
    const visites = await this.prisma.visite.findMany({
      where: {
        statut: (statut as StatutVisite) || StatutVisite.CONTESTEE,
        ...(statut ? {} : { annonce: { bien: { statut: StatutBien.SUSPENDU } } }),
      },
      orderBy: { createdAt: 'desc' },
      include: {
        locataire: { select: { id: true, nomComplet: true, telephone: true } },
        annonce: {
          include: {
            bien: { include: { ville: true, quartier: true, medias: true } },
          },
        },
      },
    });

    return visites.map((v) => ({
      ...this.formatVisite(v),
      locataire: v.locataire,
      bienId: v.annonce?.bienId,
      bienReference: v.annonce?.bien?.reference,
      bienStatut: v.annonce?.bien?.statut,
    }));
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

  /// ✅ Le locataire confirme que le bien visité correspond à l'annonce.
  async confirmerVisite(locataireId: string, visiteId: string) {
    const visite = await this.getVisiteOuEchoue(visiteId);
    if (visite.locataireId !== locataireId) {
      throw new ForbiddenException('Cette visite ne vous appartient pas.');
    }
    if (visite.statut === StatutVisite.CONFIRMEE) {
      return this.formatVisite(visite);
    }
    if (visite.statut !== StatutVisite.DEMANDEE) {
      throw new BadRequestException('Cette visite ne peut pas être confirmée dans son état actuel.');
    }

    await this.prisma.visite.update({
      where: { id: visiteId },
      data: { statut: StatutVisite.CONFIRMEE, confirmeeLe: new Date() },
    });

    const updated = await this.getVisiteOuEchoue(visiteId);
    return this.formatVisite(updated);
  }

  /// ⚠️ Le locataire signale un problème (bien indisponible, non conforme, injoignable...) —
  /// le bien est immédiatement mis en quarantaine (`SUSPENDU`, masqué du catalogue public)
  /// le temps que le Staff instruise et tranche : `valider` (signalement infondé → à nouveau
  /// disponible) ou `rejeter` (signalement confirmé → retiré définitivement).
  async contesterVisite(locataireId: string, visiteId: string, dto: ContesterVisiteDto) {
    const visite = await this.getVisiteOuEchoue(visiteId);
    if (visite.locataireId !== locataireId) {
      throw new ForbiddenException('Cette visite ne vous appartient pas.');
    }
    if (visite.statut !== StatutVisite.DEMANDEE) {
      throw new BadRequestException('Cette visite ne peut pas être contestée dans son état actuel.');
    }

    await this.prisma.$transaction([
      this.prisma.visite.update({
        where: { id: visiteId },
        data: {
          statut: StatutVisite.CONTESTEE,
          motifContestation: dto.details ? `${dto.motif} — ${dto.details}` : dto.motif,
        },
      }),
      this.prisma.bien.update({
        where: { id: visite.annonce.bienId },
        data: { statut: StatutBien.SUSPENDU },
      }),
    ]);

    this.logger.log(`Visite ${visiteId} signalée non conforme (${dto.motif}) — bien ${visite.annonce.bienId} mis en quarantaine.`);

    await this.auditService.log(
      locataireId,
      'VISITE_CONTESTEE',
      'Bien',
      visite.annonce.bienId,
      { statut: visite.annonce.bien?.statut },
      { statut: StatutBien.SUSPENDU, motif: dto.motif, visiteId },
    );

    const bailleurId = (visite.annonce.bien as any)?.bailleurId;
    if (bailleurId) {
      await this.notificationsService.creer(bailleurId, 'VISITE_SIGNALEE', {
        bienId: visite.annonce.bienId,
        bienReference: visite.annonce.bien?.reference,
        motif: dto.motif,
      });
    }

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
      creneauDebut: visite.creneauDebut,
      motifContestation: visite.motifContestation,
      confirmeeLe: visite.confirmeeLe,
      createdAt: visite.createdAt,
      annonce: visite.annonce
        ? {
            id: visite.annonce.id,
            titre: visite.annonce.titre,
            ville: visite.annonce.bien?.ville?.nom,
            quartier: visite.annonce.bien?.quartier?.nom,
            photo: visite.annonce.bien?.medias?.[0]?.storageKey,
            bailleurTel: visite.annonce.bien?.bailleurTel,
            bailleurWhatsapp: visite.annonce.bien?.bailleurWhatsapp,
          }
        : undefined,
    };
  }
}
