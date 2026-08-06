import { Controller, Get, Param, Query, UseGuards, NotFoundException, ForbiddenException, Res } from '@nestjs/common';
import type { Response } from 'express';
import * as fs from 'fs';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';
import { StatutBail } from '@prisma/client';
import { genererBailPdf, estZoneCommonLaw } from './bail-pdf.util';

/// 🧮 Calcul fiscal partagé (loyer brut / précompte 10% / net bailleur) — logique
/// unique réutilisée par toutes les vues de bail (locataire, bailleur, admin) pour
/// ne jamais désynchroniser le calcul entre elles.
export function formatBail(bail: any) {
  const loyerBrutXAF = Number(bail.loyerMensuel);
  const precompteXAF = bail.precompteApplicable ? Math.round(loyerBrutXAF * (bail.tauxPrecompte / 100)) : 0;
  return {
    id: bail.id,
    reference: bail.reference,
    statut: bail.statut,
    dateDebut: bail.dateDebut,
    dateFin: bail.dateFin,
    dureeMois: bail.dureeMois,
    loyerMensuelXAF: loyerBrutXAF,
    chargesMensuellesXAF: Number(bail.chargesMensuelles),
    avanceMontantXAF: Number(bail.avanceMontant),
    cautionMontantXAF: Number(bail.cautionMontant),
    fiscal: {
      loyerBrutXAF,
      tauxPrecompte: bail.tauxPrecompte,
      precompteXAF,
      netBailleurXAF: loyerBrutXAF - precompteXAF,
    },
    pdfDisponible: !!bail.pdfStorageKey,
    pdfSigneDisponible: !!bail.pdfSigneKey,
    signeLe: bail.signeLe,
    bien: bail.bien
      ? { ville: bail.bien.ville?.nom, quartier: bail.bien.quartier?.nom }
      : undefined,
  };
}

/**
 * Lecture seule : la création d'un bail se fait via
 * POST /candidatures/:id/decider (acceptation par le bailleur), pas ici.
 */
@Controller('baux')
export class BauxController {
  constructor(private prisma: PrismaService) {}

  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async getBail(@CurrentUser() user: any, @Param('id') id: string) {
    const bail = await this.prisma.bail.findUnique({
      where: { id },
      include: { bien: { include: { ville: true, quartier: true } } },
    });
    if (!bail) {
      throw new NotFoundException(`Bail introuvable pour l'ID : ${id}`);
    }
    const estStaff = user.roles?.includes('STAFF') || user.roles?.includes('ADMIN');
    if (bail.locataireId !== user.id && bail.bailleurId !== user.id && !estStaff) {
      throw new ForbiddenException('Ce bail ne vous appartient pas.');
    }
    return formatBail(bail);
  }

  // 📄 Génère (une fois, puis met en cache sur disque) et sert le PDF du contrat —
  // gabarit civil law (FR) par défaut, common law (EN) si la région du bien est
  // anglophone (Nord-Ouest / Sud-Ouest). Cf. packages/contracts/templates/.
  @UseGuards(JwtAuthGuard)
  @Get(':id/pdf')
  async telechargerPdf(@CurrentUser() user: any, @Param('id') id: string, @Res() res: Response) {
    const bail = await this.prisma.bail.findUnique({
      where: { id },
      include: {
        bien: { include: { ville: true, quartier: true, pointRepere: true } },
        bailleur: { select: { nomComplet: true, telephone: true } },
        locataire: { select: { nomComplet: true, telephone: true } },
      },
    });
    if (!bail) {
      throw new NotFoundException(`Bail introuvable pour l'ID : ${id}`);
    }
    const estStaff = user.roles?.includes('STAFF') || user.roles?.includes('ADMIN');
    if (bail.locataireId !== user.id && bail.bailleurId !== user.id && !estStaff) {
      throw new ForbiddenException('Ce bail ne vous appartient pas.');
    }

    let cheminPdf = bail.pdfStorageKey;
    if (!cheminPdf || !fs.existsSync(cheminPdf)) {
      // Bail ne stocke pas cautionMois directement (seulement le montant déjà calculé
      // à l'acceptation de la candidature, cf. candidatures.service.ts) — on le redérive.
      const loyer = Number(bail.loyerMensuel);
      const cautionMois = loyer > 0 ? Math.round(Number(bail.cautionMontant) / loyer) : 1;
      cheminPdf = await genererBailPdf(
        {
          reference: bail.reference,
          dateDebut: bail.dateDebut,
          bailleurNom: bail.bailleur?.nomComplet || 'Non renseigné',
          bailleurTel: bail.bailleur?.telephone || '—',
          locataireNom: bail.locataire?.nomComplet || 'Non renseigné',
          locataireTel: bail.locataire?.telephone || '—',
          typeBien: bail.bien?.type || '—',
          villeNom: bail.bien?.ville?.nom || '—',
          quartierNom: bail.bien?.quartier?.nom || '—',
          pointRepereNom: bail.bien?.pointRepere?.nom || '',
          loyerMensuel: Number(bail.loyerMensuel),
          chargesMensuelles: Number(bail.chargesMensuelles),
          avanceMois: bail.avanceMois,
          avanceMontant: Number(bail.avanceMontant),
          cautionMois,
          cautionMontant: Number(bail.cautionMontant),
          jourEcheance: bail.jourEcheance,
        },
        estZoneCommonLaw(bail.bien?.ville?.region),
      );
      await this.prisma.bail.update({ where: { id }, data: { pdfStorageKey: cheminPdf } });
    }
    res.sendFile(cheminPdf);
  }
}

@Controller('bailleur/baux')
export class BailleurBauxController {
  constructor(private prisma: PrismaService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  async mesBauxBailleur(@CurrentUser() user: any) {
    const baux = await this.prisma.bail.findMany({
      where: { bailleurId: user.id },
      orderBy: { createdAt: 'desc' },
      include: { bien: { include: { ville: true, quartier: true } } },
    });
    return baux.map((bail) => {
      const loyerBrutXAF = Number(bail.loyerMensuel);
      const precompteXAF = bail.precompteApplicable ? Math.round(loyerBrutXAF * (bail.tauxPrecompte / 100)) : 0;
      return {
        id: bail.id,
        reference: bail.reference,
        statut: bail.statut,
        dateDebut: bail.dateDebut,
        fiscal: {
          loyerBrutXAF,
          tauxPrecompte: bail.tauxPrecompte,
          precompteXAF,
          netBailleurXAF: loyerBrutXAF - precompteXAF,
        },
        bien: bail.bien ? { ville: bail.bien.ville?.nom, quartier: bail.bien.quartier?.nom } : undefined,
      };
    });
  }
}

@Controller('moi/baux')
export class MoiBauxController {
  constructor(private prisma: PrismaService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  async mesBaux(@CurrentUser() user: any) {
    const baux = await this.prisma.bail.findMany({
      where: { locataireId: user.id },
      orderBy: { createdAt: 'desc' },
      include: { bien: { include: { ville: true, quartier: true } } },
    });
    return baux.map((bail) => ({
      id: bail.id,
      reference: bail.reference,
      statut: bail.statut,
      loyerMensuelXAF: Number(bail.loyerMensuel),
      dateDebut: bail.dateDebut,
      bien: bail.bien ? { ville: bail.bien.ville?.nom, quartier: bail.bien.quartier?.nom } : undefined,
    }));
  }
}

// 🛡️ GET /api/v1/admin/baux — vue d'ensemble plateforme, lecture seule (Staff/Admin).
// Les décisions (résiliation, etc.) restent du ressort du bailleur via les routes existantes.
@Controller('admin/baux')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminBauxController {
  constructor(private prisma: PrismaService) {}

  @Roles('STAFF', 'ADMIN')
  @Get()
  async tousLesBaux(@Query('statut') statut?: string) {
    const baux = await this.prisma.bail.findMany({
      where: statut ? { statut: statut as StatutBail } : {},
      orderBy: { createdAt: 'desc' },
      include: {
        bien: { include: { ville: true, quartier: true } },
        bailleur: { select: { nomComplet: true, telephone: true } },
        locataire: { select: { nomComplet: true, telephone: true } },
      },
    });

    return baux.map((bail) => ({
      ...formatBail(bail),
      bailleur: bail.bailleur ? { nomComplet: bail.bailleur.nomComplet, telephone: bail.bailleur.telephone } : undefined,
      locataire: bail.locataire ? { nomComplet: bail.locataire.nomComplet, telephone: bail.locataire.telephone } : undefined,
    }));
  }
}
