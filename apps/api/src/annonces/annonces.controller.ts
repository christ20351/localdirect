import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards, UseInterceptors, UploadedFiles, Req } from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import type { Request } from 'express';
import { AnnoncesService } from './annonces.service';
import { FiltreAnnonceDto } from './dtos/filtre-annonce.dto';
import { CreerBienDto } from './dtos/creer-bien.dto';
import { ModifierBienDto } from './dtos/modifier-bien.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { multerStorage, MEDIAS_DIR } from '../uploads/storage.util';

const MAX_TAILLE_PHOTO = 6 * 1024 * 1024; // 6 Mo

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

  // ❤️ Route protégée : POST /api/v1/annonces/:id/favori
  @UseGuards(JwtAuthGuard)
  @Post(':id/favori')
  async ajouterFavori(@CurrentUser() user: any, @Param('id') id: string) {
    return this.annoncesService.ajouterFavori(user.id, id);
  }

  // 💔 Route protégée : DELETE /api/v1/annonces/:id/favori
  @UseGuards(JwtAuthGuard)
  @Delete(':id/favori')
  async retirerFavori(@CurrentUser() user: any, @Param('id') id: string) {
    return this.annoncesService.retirerFavori(user.id, id);
  }
}

// 👤 Regroupe les routes liées à l'utilisateur connecté (préfixe /api/v1/moi)
@Controller('moi')
export class MoiController {
  constructor(private annoncesService: AnnoncesService) {}

  // 📋 Route protégée : GET /api/v1/moi/favoris
  @UseGuards(JwtAuthGuard)
  @Get('favoris')
  async mesFavoris(@CurrentUser() user: any) {
    return this.annoncesService.getMesFavoris(user.id);
  }

  // 🏘️ Route protégée : GET /api/v1/moi/biens (Espace Bailleur)
  @UseGuards(JwtAuthGuard)
  @Get('biens')
  async mesBiens(@CurrentUser() user: any) {
    return this.annoncesService.getMesBiens(user.id);
  }
}

@Controller('biens')
export class BiensController {
  constructor(private annoncesService: AnnoncesService) {}

  // ➕ Route protégée : POST /api/v1/biens (Création de bien réservée au Bailleur —
  // un simple Locataire n'ayant pas franchi la vérification KYC ne peut pas publier de bien).
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('BAILLEUR')
  @Post()
  async creerBien(@CurrentUser() user: any, @Body() dto: CreerBienDto) {
    return this.annoncesService.creerBienEtAnnonce(user.id, dto);
  }

  // ✏️ Route protégée : PATCH /api/v1/biens/:id (Édition par le bailleur propriétaire)
  @UseGuards(JwtAuthGuard)
  @Patch(':id')
  async modifierBien(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: ModifierBienDto) {
    return this.annoncesService.modifierBien(user.id, id, dto);
  }

  // ✅ Route protégée : POST /api/v1/biens/:id/marquer-loue
  @UseGuards(JwtAuthGuard)
  @Post(':id/marquer-loue')
  async marquerLoue(@CurrentUser() user: any, @Param('id') id: string) {
    return this.annoncesService.marquerBienLoue(user.id, id);
  }

  // 📸 Route protégée : POST /api/v1/biens/:id/medias (upload réel de photos, jusqu'à 6 à la fois)
  @UseGuards(JwtAuthGuard)
  @Post(':id/medias')
  @UseInterceptors(FilesInterceptor('photos', 6, { storage: multerStorage(MEDIAS_DIR), limits: { fileSize: MAX_TAILLE_PHOTO } }))
  async ajouterMedias(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @UploadedFiles() files: Express.Multer.File[],
    @Req() req: Request,
  ) {
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    return this.annoncesService.ajouterMedias(user.id, id, files, baseUrl);
  }
}

// 🛡️ Regroupe les routes de modération réservées au Staff/Admin (préfixe /api/v1/admin)
@Controller('admin/biens')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminBiensController {
  constructor(private annoncesService: AnnoncesService) {}

  @Roles('STAFF', 'ADMIN')
  @Get()
  async fileAttente(@Query('statut') statut?: string) {
    return this.annoncesService.getBiensEnAttente(statut);
  }

  @Roles('STAFF', 'ADMIN')
  @Post(':id/valider')
  async validerBien(@CurrentUser() user: any, @Param('id') id: string) {
    return this.annoncesService.validerBien(user.id, id);
  }

  @Roles('STAFF', 'ADMIN')
  @Post(':id/rejeter')
  async rejeterBien(@CurrentUser() user: any, @Param('id') id: string, @Body('motif') motif: string) {
    return this.annoncesService.rejeterBien(user.id, id, motif);
  }
}
