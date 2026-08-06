import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Res,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { DocumentsService } from './documents.service';
import { SoumettreDocumentDto } from './dtos/soumettre-document.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { multerStorage, DOCUMENTS_DIR } from '../uploads/storage.util';

const MAX_TAILLE_DOCUMENT = 8 * 1024 * 1024; // 8 Mo

// 📎 Documents du compte connecté (KYC / preuve de propriété d'un bien)
@Controller('moi/documents')
export class MoiDocumentsController {
  constructor(private documentsService: DocumentsService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  @UseInterceptors(FileInterceptor('fichier', { storage: multerStorage(DOCUMENTS_DIR), limits: { fileSize: MAX_TAILLE_DOCUMENT } }))
  async soumettre(@CurrentUser() user: any, @UploadedFile() file: Express.Multer.File, @Body() dto: SoumettreDocumentDto) {
    return this.documentsService.soumettre(user.id, file, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get()
  async mesDocuments(@CurrentUser() user: any, @Query('bienId') bienId?: string) {
    return this.documentsService.getMesDocuments(user.id, bienId);
  }
}

// 📥 Téléchargement protégé du fichier (propriétaire ou Staff/Admin)
@Controller('documents')
export class DocumentsController {
  constructor(private documentsService: DocumentsService) {}

  @UseGuards(JwtAuthGuard)
  @Get(':id/fichier')
  async telecharger(@CurrentUser() user: any, @Param('id') id: string, @Res() res: Response) {
    const chemin = await this.documentsService.getCheminFichier(user.id, user.roles, id);
    res.sendFile(chemin);
  }
}

// 🛡️ File de modération — Staff/Admin
@Controller('admin/documents')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminDocumentsController {
  constructor(private documentsService: DocumentsService) {}

  @Roles('STAFF', 'ADMIN')
  @Get()
  async fileAttente(@Query('statut') statut?: string) {
    return this.documentsService.getFileAttente(statut);
  }

  @Roles('STAFF', 'ADMIN')
  @Post(':id/valider')
  async valider(@CurrentUser() user: any, @Param('id') id: string) {
    return this.documentsService.valider(user.id, id);
  }

  @Roles('STAFF', 'ADMIN')
  @Post(':id/rejeter')
  async rejeter(@CurrentUser() user: any, @Param('id') id: string, @Body('motif') motif: string) {
    return this.documentsService.rejeter(user.id, id, motif);
  }
}
