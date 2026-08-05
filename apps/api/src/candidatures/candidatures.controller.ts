import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { CandidaturesService } from './candidatures.service';
import { CreerCandidatureDto } from './dtos/creer-candidature.dto';
import { DeciderCandidatureDto } from './dtos/decider-candidature.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('annonces/:annonceId/candidatures')
export class AnnonceCandidaturesController {
  constructor(private candidaturesService: CandidaturesService) {}

  // 📋 Route protégée : POST /api/v1/annonces/:annonceId/candidatures
  @UseGuards(JwtAuthGuard)
  @Post()
  async soumettreCandidature(
    @CurrentUser() user: any,
    @Param('annonceId') annonceId: string,
    @Body() dto: CreerCandidatureDto,
  ) {
    return this.candidaturesService.soumettreCandidature(user.id, annonceId, dto);
  }
}

@Controller('candidatures')
export class CandidaturesController {
  constructor(private candidaturesService: CandidaturesService) {}

  // 🔍 Route protégée : GET /api/v1/candidatures/:id
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async getCandidature(@CurrentUser() user: any, @Param('id') id: string) {
    return this.candidaturesService.getCandidature(user.id, id);
  }

  // ⚖️ Route protégée : POST /api/v1/candidatures/:id/decider (Bailleur)
  @UseGuards(JwtAuthGuard)
  @Post(':id/decider')
  async deciderCandidature(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: DeciderCandidatureDto) {
    return this.candidaturesService.deciderCandidature(user.id, id, dto);
  }
}

// 👤 GET /api/v1/moi/candidatures
@Controller('moi/candidatures')
export class MoiCandidaturesController {
  constructor(private candidaturesService: CandidaturesService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  async mesCandidatures(@CurrentUser() user: any) {
    return this.candidaturesService.getMesCandidatures(user.id);
  }
}

// 🏘️ GET /api/v1/bailleur/candidatures
@Controller('bailleur/candidatures')
export class BailleurCandidaturesController {
  constructor(private candidaturesService: CandidaturesService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  async candidaturesRecues(@CurrentUser() user: any) {
    return this.candidaturesService.getCandidaturesBailleur(user.id);
  }
}

// 🛡️ GET /api/v1/admin/candidatures — vue d'ensemble plateforme, lecture seule (Staff/Admin)
@Controller('admin/candidatures')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminCandidaturesController {
  constructor(private candidaturesService: CandidaturesService) {}

  @Roles('STAFF', 'ADMIN')
  @Get()
  async toutesLesCandidatures(@Query('statut') statut?: string) {
    return this.candidaturesService.getToutesLesCandidatures(statut);
  }
}
