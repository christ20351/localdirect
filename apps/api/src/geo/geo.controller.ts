import { Controller, Get, Post, Patch, Param, Query, Body, UseGuards } from '@nestjs/common';
import { GeoService } from './geo.service';
import { StatutVille } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CreerVilleDto } from './dtos/creer-ville.dto';
import { ModifierVilleDto } from './dtos/modifier-ville.dto';
import { CreerQuartierDto } from './dtos/creer-quartier.dto';
import { ModifierQuartierDto } from './dtos/modifier-quartier.dto';

@Controller()
export class GeoController {
  constructor(private geoService: GeoService) {}

  // 🏙️ Route publique : GET /api/v1/villes (ex: Douala, Yaoundé)
  @Get('villes')
  async getVilles(@Query('statut') statut?: StatutVille) {
    return this.geoService.getVilles(statut);
  }

  // 📍 Route publique : GET /api/v1/villes/douala/quartiers
  @Get('villes/:slug/quartiers')
  async getQuartiersParVille(@Param('slug') slug: string) {
    return this.geoService.getQuartiersParVille(slug);
  }

  // 📌 Route publique : GET /api/v1/quartiers/:id/reperes
  @Get('quartiers/:id/reperes')
  async getReperesParQuartier(@Param('id') quartierId: string) {
    return this.geoService.getReperesParQuartier(quartierId);
  }
}

// 🛡️ Pilotage Multi-Villes — réservé ADMIN (ouverture/fermeture de villes, gestion des
// quartiers). Décisions stratégiques : contrairement à la modération (STAFF autorisé
// ailleurs dans l'app), ici on reste strictement ADMIN.
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminGeoController {
  constructor(private geoService: GeoService) {}

  @Roles('ADMIN')
  @Post('villes')
  async creerVille(@CurrentUser() user: any, @Body() dto: CreerVilleDto) {
    return this.geoService.creerVille(user.id, dto);
  }

  @Roles('ADMIN')
  @Patch('villes/:id')
  async modifierVille(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: ModifierVilleDto) {
    return this.geoService.modifierVille(user.id, id, dto);
  }

  @Roles('ADMIN')
  @Post('villes/:id/quartiers')
  async creerQuartier(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: CreerQuartierDto) {
    return this.geoService.creerQuartier(user.id, id, dto);
  }

  @Roles('ADMIN')
  @Patch('quartiers/:id')
  async modifierQuartier(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: ModifierQuartierDto) {
    return this.geoService.modifierQuartier(user.id, id, dto);
  }
}
