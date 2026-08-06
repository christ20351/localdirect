import { Injectable, NotFoundException, ForbiddenException, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StatutKyc, StatutVisite } from '@prisma/client';
import { DevenirAgentDto } from './dtos/devenir-agent.dto';
import { CheckinVisiteDto } from './dtos/checkin-visite.dto';
import { TYPES_KYC_AGENT } from '../documents/types-documents';

const CODE_AGENT_DEFAUT = { commissionAgentVisite: 1400, commissionPlateformeVisite: 600 };

@Injectable()
export class AgentService {
  constructor(private prisma: PrismaService) {}

  /// 🪪 Onboarding Agent : KYC complet (CNI + Selfie validés) + numéro MoMo + charte signée.
  /// Exclusif du rôle BAILLEUR (conflit d'intérêt : l'agent représente les bailleurs).
  async devenirAgent(utilisateurId: string, roles: string[], dto: DevenirAgentDto) {
    if (roles.includes('AGENT')) {
      throw new ConflictException('Ce compte est déjà enregistré comme Agent.');
    }
    if (roles.includes('BAILLEUR')) {
      throw new ConflictException('Un compte Bailleur ne peut pas devenir Agent (conflit d\'intérêt).');
    }
    if (!dto.charteAcceptee) {
      throw new BadRequestException('La signature de la charte de bonne conduite est obligatoire.');
    }

    const documentsValides = await this.prisma.documentVerification.findMany({
      where: { utilisateurId, bienId: null, statut: StatutKyc.VALIDE, type: { in: [...TYPES_KYC_AGENT] } },
      select: { type: true },
    });
    const typesValides = new Set(documentsValides.map((d) => d.type));
    const manquants = TYPES_KYC_AGENT.filter((t) => !typesValides.has(t));
    if (manquants.length > 0) {
      throw new BadRequestException(
        `KYC incomplet. Documents encore requis (soumis via POST /moi/documents puis validés par le Staff) : ${manquants.join(', ')}.`,
      );
    }

    const ville = await this.prisma.ville.findUnique({ where: { id: dto.villeId } });
    if (!ville) {
      throw new BadRequestException('Ville invalide.');
    }

    const codeAgent = `AGT-${ville.slug.toUpperCase().slice(0, 3)}-${Date.now().toString(36).toUpperCase()}`;

    const [, utilisateur] = await this.prisma.$transaction([
      this.prisma.agent.create({
        data: {
          utilisateurId,
          codeAgent,
          villeId: dto.villeId,
          quartiersCouverts: dto.quartiersCouverts || [],
          numeroMomo: dto.numeroMomo,
          charteSigneeLe: new Date(),
        },
      }),
      this.prisma.utilisateur.update({
        where: { id: utilisateurId },
        data: { roles: { push: 'AGENT' } },
      }),
    ]);

    const { motDePasseHash, ...safe } = utilisateur as any;
    return safe;
  }

  /// 📋 Mandats de l'agent connecté
  async getMesMandats(utilisateurId: string) {
    const agent = await this.getAgentOuEchoue(utilisateurId);
    const mandats = await this.prisma.mandat.findMany({
      where: { agentId: agent.id },
      orderBy: { debut: 'desc' },
      include: { bien: { include: { ville: true, quartier: true, annonces: { take: 1, orderBy: { createdAt: 'desc' } } } } },
    });
    return mandats.map((m) => ({
      id: m.id,
      type: m.type,
      actif: m.actif,
      debut: m.debut,
      bien: m.bien
        ? {
            id: m.bien.id,
            statut: m.bien.statut,
            titre: m.bien.annonces[0]?.titre,
            ville: m.bien.ville?.nom,
            quartier: m.bien.quartier?.nom,
          }
        : undefined,
    }));
  }

  /// 📅 Visites assignées à l'agent connecté
  async getMesVisites(utilisateurId: string) {
    const agent = await this.getAgentOuEchoue(utilisateurId);
    const visites = await this.prisma.visite.findMany({
      where: { agentId: agent.id },
      orderBy: { createdAt: 'desc' },
      include: { annonce: { include: { bien: { include: { ville: true, quartier: true, medias: true } } } } },
    });
    return visites.map((v) => ({
      id: v.id,
      statut: v.statut,
      creneauDebut: v.creneauDebut,
      checkinLe: v.checkinLe,
      confirmeeLe: v.confirmeeLe,
      annonce: v.annonce
        ? {
            id: v.annonce.id,
            titre: v.annonce.titre,
            ville: v.annonce.bien?.ville?.nom,
            quartier: v.annonce.bien?.quartier?.nom,
            latitudeFloue: v.annonce.bien?.latitudeFloue,
            longitudeFloue: v.annonce.bien?.longitudeFloue,
          }
        : undefined,
    }));
  }

  /// 📍 Check-in GPS terrain de l'agent sur une visite
  async checkin(utilisateurId: string, visiteId: string, dto: CheckinVisiteDto) {
    const agent = await this.getAgentOuEchoue(utilisateurId);
    const visite = await this.prisma.visite.findUnique({ where: { id: visiteId } });
    if (!visite) {
      throw new NotFoundException(`Visite introuvable pour l'ID : ${visiteId}`);
    }
    if (visite.agentId !== agent.id) {
      throw new ForbiddenException('Cette visite ne vous est pas assignée.');
    }
    if (visite.codeConfirmation !== dto.codeConfirmation) {
      throw new BadRequestException('Code de confirmation incorrect.');
    }
    if (!['PAYEE', 'PLANIFIEE'].includes(visite.statut)) {
      throw new BadRequestException('Cette visite ne peut pas faire l\'objet d\'un check-in dans son état actuel.');
    }

    await this.prisma.$transaction([
      this.prisma.visite.update({
        where: { id: visiteId },
        data: {
          statut: StatutVisite.CHECK_IN,
          checkinLatitude: dto.latitude,
          checkinLongitude: dto.longitude,
          checkinLe: new Date(),
        },
      }),
      this.prisma.agent.update({
        where: { id: agent.id },
        data: { nbVisites: { increment: 1 } },
      }),
    ]);

    return { message: 'Check-in enregistré.' };
  }

  /// 💰 Gains réels de l'agent (grand livre `Ecriture`, compte AGENT:<id>)
  async getMesGains(utilisateurId: string) {
    const agent = await this.getAgentOuEchoue(utilisateurId);
    const compte = `AGENT:${agent.id}`;
    const ecritures = await this.prisma.ecriture.findMany({
      where: { compte },
      orderBy: { createdAt: 'desc' },
    });

    const totalXAF = ecritures.reduce((somme, e) => {
      const montant = Number(e.montant);
      return e.sens === 'C' ? somme + montant : somme - montant;
    }, 0);

    return {
      totalXAF,
      seuilRetraitXAF: 5000,
      retraitDisponible: false, // Pas encore de fournisseur de paiement de type "payout" intégré (voir README).
      mouvements: ecritures.map((e) => ({
        montantXAF: Number(e.montant),
        sens: e.sens,
        libelle: e.libelle,
        createdAt: e.createdAt,
      })),
    };
  }

  /// Réalloue la commission agent (PLATEFORME → AGENT) après confirmation d'une visite —
  /// appelé depuis VisitesService pour rester dans une seule transaction cohérente.
  static calculerCommissions(parametresVille: Record<string, unknown> | null | undefined) {
    const parametres = parametresVille ?? {};
    return {
      commissionAgentVisite: Number((parametres as any).commissionAgentVisite ?? CODE_AGENT_DEFAUT.commissionAgentVisite),
      commissionPlateformeVisite: Number((parametres as any).commissionPlateformeVisite ?? CODE_AGENT_DEFAUT.commissionPlateformeVisite),
    };
  }

  private async getAgentOuEchoue(utilisateurId: string) {
    const agent = await this.prisma.agent.findUnique({ where: { utilisateurId } });
    if (!agent) {
      throw new NotFoundException('Aucun profil Agent pour ce compte.');
    }
    return agent;
  }
}
