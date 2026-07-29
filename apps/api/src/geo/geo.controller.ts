import { Controller, Get, Param, Query } from '@nestjs/common';
import { GeoService } from './geo.service';
import { StatutVille } from '@prisma/client';

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
