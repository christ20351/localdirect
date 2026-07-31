import { Controller, Get, Param, UseGuards, NotFoundException, ForbiddenException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';

@Controller('paiements')
export class PaiementsController {
  constructor(private prisma: PrismaService) {}

  // 💳 Route protégée : GET /api/v1/paiements/:id
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async getPaiement(@CurrentUser() user: any, @Param('id') id: string) {
    const paiement = await this.prisma.paiement.findUnique({ where: { id } });
    if (!paiement) {
      throw new NotFoundException(`Paiement introuvable pour l'ID : ${id}`);
    }
    if (paiement.payeurId !== user.id && paiement.beneficiaireId !== user.id) {
      throw new ForbiddenException('Ce paiement ne vous appartient pas.');
    }

    return {
      id: paiement.id,
      reference: paiement.reference,
      type: paiement.type,
      statut: paiement.statut,
      methode: paiement.methode,
      montantXAF: Number(paiement.montant),
      devise: paiement.devise,
      createdAt: paiement.createdAt,
      regleLe: paiement.regleLe,
    };
  }
}
