import { Controller, Post, Body, Get, UseGuards, Patch, Delete, ConflictException, BadRequestException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuthService } from './auth.service';
import { DemanderOtpDto } from './dtos/demander-otp.dto';
import { VerifierOtpDto } from './dtos/verifier-otp.dto';
import { InscriptionDto } from './dtos/inscription.dto';
import { ConnexionDto } from './dtos/connexion.dto';
import { RefreshTokenDto } from './dtos/refresh-token.dto';
import { GoogleLoginDto } from './dtos/google-login.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';
import { DocumentsService } from '../documents/documents.service';
import { TYPES_PREUVE_PROPRIETE, SEUIL_PREUVE_PROPRIETE } from '../documents/types-documents';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private prisma: PrismaService,
    private documentsService: DocumentsService,
  ) {}

  // 📲 Demander un code OTP par SMS ou WhatsApp
  @Post('otp/demander')
  async demanderOtp(@Body() dto: DemanderOtpDto) {
    return this.authService.demanderOtp(dto);
  }

  // 🔐 Vérifier le code OTP et se connecter
  @Post('otp/verifier')
  async verifierOtp(@Body() dto: VerifierOtpDto) {
    return this.authService.verifierOtp(dto);
  }

  // 🌐 Connexion / Inscription via Google Sign-In
  @Post('google')
  async connexionGoogle(@Body() dto: GoogleLoginDto) {
    return this.authService.connexionGoogle(dto);
  }

  // 📧 Inscription par Email + Mot de passe
  @Post('inscription')
  async inscription(@Body() dto: InscriptionDto) {
    return this.authService.inscription(dto);
  }

  // 🔑 Connexion par Email/Téléphone + Mot de passe
  @Post('connexion')
  async connexion(@Body() dto: ConnexionDto) {
    return this.authService.connexion(dto);
  }

  // 🔄 Rafraîchir les jetons JWT
  @Post('refresh')
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto);
  }

  // 👤 Obtenir les informations du profil de l'utilisateur connecté
  @UseGuards(JwtAuthGuard)
  @Get('moi')
  async getProfil(@CurrentUser() user: any) {
    return this.sansDonneesSensibles(user);
  }

  // ✏️ Mettre à jour les informations du profil utilisateur
  @UseGuards(JwtAuthGuard)
  @Patch('profil')
  async updateProfil(
    @CurrentUser() user: any,
    @Body() body: { nomComplet?: string; email?: string; langue?: 'FR' | 'EN'; villeId?: string; photoUrl?: string },
  ) {
    try {
      const updatedUser = await this.prisma.utilisateur.update({
        where: { id: user.id },
        data: body,
      });
      return this.sansDonneesSensibles(updatedUser);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new ConflictException('Cet email est déjà utilisé par un autre compte.');
      }
      throw error;
    }
  }

  // 🏠 Devenir Bailleur : ajoute le rôle BAILLEUR au compte, une fois qu'au moins
  // 2 des 4 documents du faisceau de preuve de propriété (README_1.md §11) ont été
  // soumis via POST /moi/documents et validés par le Staff. Exclusif du rôle AGENT
  // (conflit d'intérêt : un agent représente les bailleurs, il ne doit pas être
  // juge et partie sur ses propres biens).
  @UseGuards(JwtAuthGuard)
  @Post('devenir-bailleur')
  async devenirBailleur(@CurrentUser() user: any) {
    if (user.roles.includes('BAILLEUR')) {
      return this.sansDonneesSensibles(user);
    }

    const nbValides = await this.documentsService.countDocumentsCompteValides(user.id, TYPES_PREUVE_PROPRIETE);
    if (nbValides < SEUIL_PREUVE_PROPRIETE) {
      throw new BadRequestException(
        `Il faut au moins ${SEUIL_PREUVE_PROPRIETE} documents de preuve de propriété validés par le Staff (facture ENEO/Camwater, CNI + selfie, titre foncier, ou ancien bail/quittance). Documents validés actuellement : ${nbValides}.`,
      );
    }

    const updatedUser = await this.prisma.utilisateur.update({
      where: { id: user.id },
      data: { roles: { push: 'BAILLEUR' } },
    });
    return this.sansDonneesSensibles(updatedUser);
  }

  // 🗑️ Supprimer son compte (droit à l'effacement, loi n° 2024/017) — suppression
  // logique : le compte est désactivé et les données identifiantes sont effacées,
  // mais l'historique (visites, paiements, candidatures) est conservé pour l'audit.
  @UseGuards(JwtAuthGuard)
  @Delete('moi')
  async supprimerCompte(@CurrentUser() user: any) {
    await this.prisma.utilisateur.update({
      where: { id: user.id },
      data: {
        deletedAt: new Date(),
        bloque: true,
        motifBlocage: 'Compte supprimé à la demande de l\'utilisateur',
        nomComplet: null,
        photoUrl: null,
      },
    });
    return { message: 'Votre compte a été supprimé.' };
  }

  // Retire les champs sensibles (hash du mot de passe) avant de renvoyer un utilisateur au client.
  private sansDonneesSensibles(utilisateur: any) {
    const { motDePasseHash, agent, ...safe } = utilisateur;
    return safe;
  }
}
