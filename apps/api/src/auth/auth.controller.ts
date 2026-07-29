import { Controller, Post, Body, Get, UseGuards, Patch } from '@nestjs/common';
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

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private prisma: PrismaService,
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
    return user;
  }

  // ✏️ Mettre à jour les informations du profil utilisateur
  @UseGuards(JwtAuthGuard)
  @Patch('profil')
  async updateProfil(
    @CurrentUser() user: any,
    @Body() body: { nomComplet?: string; email?: string; langue?: 'FR' | 'EN'; villeId?: string; photoUrl?: string },
  ) {
    const updatedUser = await this.prisma.utilisateur.update({
      where: { id: user.id },
      data: body,
    });
    return updatedUser;
  }
}
