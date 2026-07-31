import { Controller, Get, Param, UseGuards, NotFoundException, ForbiddenException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';

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
    if (bail.locataireId !== user.id && bail.bailleurId !== user.id) {
      throw new ForbiddenException('Ce bail ne vous appartient pas.');
    }
    return this.formatBail(bail);
  }

  private formatBail(bail: any) {
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
