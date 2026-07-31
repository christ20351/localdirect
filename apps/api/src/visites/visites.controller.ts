import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { VisitesService } from './visites.service';
import { CreerVisiteDto } from './dtos/creer-visite.dto';
import { PayerVisiteDto } from './dtos/payer-visite.dto';
import { ContesterVisiteDto } from './dtos/contester-visite.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('annonces/:annonceId/visites')
export class AnnonceVisitesController {
  constructor(private visitesService: VisitesService) {}

  // 📅 Route protégée : POST /api/v1/annonces/:annonceId/visites
  @UseGuards(JwtAuthGuard)
  @Post()
  async demanderVisite(
    @CurrentUser() user: any,
    @Param('annonceId') annonceId: string,
    @Body() dto: CreerVisiteDto,
  ) {
    return this.visitesService.demanderVisite(user.id, annonceId, dto);
  }
}

@Controller('visites')
export class VisitesController {
  constructor(private visitesService: VisitesService) {}

  // 💳 Route protégée : POST /api/v1/visites/:id/payer
  @UseGuards(JwtAuthGuard)
  @Post(':id/payer')
  async payerVisite(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: PayerVisiteDto) {
    return this.visitesService.payerVisite(user.id, id, dto);
  }

  // 🔍 Route protégée : GET /api/v1/visites/:id
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async getVisite(@CurrentUser() user: any, @Param('id') id: string) {
    return this.visitesService.getVisite(user.id, id);
  }

  // ✅ Route protégée : POST /api/v1/visites/:id/confirmer
  @UseGuards(JwtAuthGuard)
  @Post(':id/confirmer')
  async confirmerVisite(@CurrentUser() user: any, @Param('id') id: string) {
    return this.visitesService.confirmerVisite(user.id, id);
  }

  // ⚠️ Route protégée : POST /api/v1/visites/:id/contester
  @UseGuards(JwtAuthGuard)
  @Post(':id/contester')
  async contesterVisite(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: ContesterVisiteDto) {
    return this.visitesService.contesterVisite(user.id, id, dto);
  }
}

// 👤 GET /api/v1/moi/visites
@Controller('moi/visites')
export class MoiVisitesController {
  constructor(private visitesService: VisitesService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  async mesVisites(@CurrentUser() user: any) {
    return this.visitesService.getMesVisites(user.id);
  }
}
