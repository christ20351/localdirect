import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AnnoncesService } from './annonces.service';
import { FiltreAnnonceDto } from './dtos/filtre-annonce.dto';
import { CreerBienDto } from './dtos/creer-bien.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('annonces')
export class AnnoncesController {
  constructor(private annoncesService: AnnoncesService) {}

  // 🔍 Route publique : GET /api/v1/annonces (Catalogue avec recherche & filtres)
  @Get()
  async getAnnonces(@Query() query: FiltreAnnonceDto) {
    return this.annoncesService.getAnnonces(query);
  }

  // 🏠 Route publique : GET /api/v1/annonces/:id (Détail d'une annonce)
  @Get(':id')
  async getAnnonceById(@Param('id') id: string) {
    return this.annoncesService.getAnnonceById(id);
  }
}

@Controller('biens')
export class BiensController {
  constructor(private annoncesService: AnnoncesService) {}

  // ➕ Route protégée : POST /api/v1/biens (Création de bien par Agent ou Bailleur)
  @UseGuards(JwtAuthGuard)
  @Post()
  async creerBien(@CurrentUser() user: any, @Body() dto: CreerBienDto) {
    return this.annoncesService.creerBienEtAnnonce(user.id, dto);
  }
}
