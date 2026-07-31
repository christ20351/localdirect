import { Injectable, BadRequestException, UnauthorizedException, ConflictException, Inject } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { PrismaService } from '../prisma/prisma.service';
import { DemanderOtpDto } from './dtos/demander-otp.dto';
import { VerifierOtpDto } from './dtos/verifier-otp.dto';
import { InscriptionDto } from './dtos/inscription.dto';
import { ConnexionDto } from './dtos/connexion.dto';
import { RefreshTokenDto } from './dtos/refresh-token.dto';
import { GoogleLoginDto } from './dtos/google-login.dto';
import type { IOtpProvider } from './providers/otp-provider.interface';
import { OTP_PROVIDER_TOKEN } from './providers/otp-provider.interface';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  // Client Google OAuth2 pour vérifier la validité des tokens envoyés par l'application Flutter
  private googleOAuthClient: OAuth2Client;

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    @Inject(OTP_PROVIDER_TOKEN) private otpProvider: IOtpProvider,
  ) {
    // Initialisation du client Google avec la clé Google Client ID
    const googleClientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    this.googleOAuthClient = new OAuth2Client(googleClientId);
  }

  /// 📲 Demande de code OTP (SMS ou WhatsApp)
  async demanderOtp(dto: DemanderOtpDto) {
    const { telephone, canal = 'SMS' } = dto;

    // Génération d'un code aléatoire à 4 chiffres (ex: 4821)
    const code = Math.floor(1000 + Math.random() * 9000).toString();
    const codeHash = await bcrypt.hash(code, 10);
    const expireLe = new Date(Date.now() + 5 * 60 * 1000); // Code valide 5 minutes

    // Enregistrement sécurisé du hash en base de données dans la table Otp
    await this.prisma.otp.create({
      data: {
        telephone,
        codeHash,
        canal,
        expireLe,
      },
    });

    // Envoi effectif via le fournisseur d'envoi configuré (Console / CamPay / WhatsApp)
    await this.otpProvider.sendOtp({
      telephone,
      code,
      canal,
    });

    return {
      message: `Code OTP envoyé avec succès par ${canal} au ${telephone}.`,
      debugCode: process.env.NODE_ENV !== 'production' ? code : undefined,
    };
  }

  /// 🔐 Vérification du code OTP et connexion / création automatique du compte
  async verifierOtp(dto: VerifierOtpDto) {
    const { telephone, code } = dto;

    // Recherche du dernier code OTP actif non encore consommé
    const otpRecord = await this.prisma.otp.findFirst({
      where: {
        telephone,
        consommeLe: null,
        expireLe: { gte: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new BadRequestException('Code OTP expiré ou inexistant. Veuillez refaire une demande.');
    }

    // Vérification du code saisi par rapport au hash enregistré
    const isCodeValide = await bcrypt.compare(code, otpRecord.codeHash);
    if (!isCodeValide) {
      await this.prisma.otp.update({
        where: { id: otpRecord.id },
        data: { tentatives: { increment: 1 } },
      });
      throw new BadRequestException('Code OTP incorrect.');
    }

    // Marquer l'OTP comme consommé pour qu'il ne serve qu'une seule fois
    await this.prisma.otp.update({
      where: { id: otpRecord.id },
      data: { consommeLe: new Date() },
    });

    // Recherche de l'utilisateur ou création automatique si 1ère connexion
    let utilisateur = await this.prisma.utilisateur.findUnique({
      where: { telephone },
    });

    if (!utilisateur) {
      utilisateur = await this.prisma.utilisateur.create({
        data: {
          telephone,
          telephoneVerifie: true,
          roles: ['LOCATAIRE'],
        },
      });
    } else if (!utilisateur.telephoneVerifie) {
      utilisateur = await this.prisma.utilisateur.update({
        where: { id: utilisateur.id },
        data: { telephoneVerifie: true },
      });
    }

    return this.generateTokens(utilisateur);
  }

  /// 🌐 Connexion / Inscription via Google Sign-In (OAuth2)
  async connexionGoogle(dto: GoogleLoginDto) {
    const googleClientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    if (!googleClientId) {
      throw new UnauthorizedException('Connexion Google non configurée côté serveur (GOOGLE_CLIENT_ID manquant).');
    }

    try {
      // 1. Vérification du jeton idToken auprès des serveurs officiels de Google,
      // en exigeant explicitement que l'audience corresponde à notre Web Client ID
      // (c'est cette même audience que le mobile demande via `serverClientId`).
      const ticket = await this.googleOAuthClient.verifyIdToken({
        idToken: dto.idToken,
        audience: googleClientId,
      });

      const payload = ticket.getPayload();
      if (!payload || !payload.email) {
        throw new UnauthorizedException('Jeton Google invalide ou email absent.');
      }

      const email = payload.email;
      const nomComplet = payload.name || 'Utilisateur Google';
      const photoUrl = payload.picture;

      // 2. Recherche si l'utilisateur existe déjà en BDD avec cet email
      let utilisateur = await this.prisma.utilisateur.findUnique({
        where: { email },
      });

      // 3. S'il n'existe pas, création automatique du compte
      if (!utilisateur) {
        utilisateur = await this.prisma.utilisateur.create({
          data: {
            email,
            nomComplet,
            photoUrl,
            telephone: `google_${Date.now()}`, // Identifiant temporaire en attendant saisie téléphone
            roles: ['LOCATAIRE'],
          },
        });
      }

      if (utilisateur.bloque) {
        throw new UnauthorizedException(`Compte bloqué. Motif : ${utilisateur.motifBlocage || 'Non spécifié'}`);
      }

      // 4. Génération de nos propres jetons JWT d'application
      return this.generateTokens(utilisateur);
    } catch (error: any) {
      throw new UnauthorizedException(`Échec de la connexion Google : ${error.message}`);
    }
  }

  /// 📧 Inscription complète par Email + Mot de passe + Téléphone
  async inscription(dto: InscriptionDto) {
    const { nomComplet, email, telephone, motDePasse, villeId, devenirBailleur } = dto;

    const existingUser = await this.prisma.utilisateur.findFirst({
      where: {
        OR: [{ email }, { telephone }],
      },
    });

    if (existingUser) {
      throw new ConflictException('Un compte existe déjà avec cet email ou ce numéro de téléphone.');
    }

    const motDePasseHash = await bcrypt.hash(motDePasse, 10);

    const utilisateur = await this.prisma.utilisateur.create({
      data: {
        nomComplet,
        email,
        telephone,
        motDePasseHash,
        villeId,
        roles: devenirBailleur ? ['LOCATAIRE', 'BAILLEUR'] : ['LOCATAIRE'],
      },
    });

    return this.generateTokens(utilisateur);
  }

  /// 🔑 Connexion par Email/Téléphone + Mot de passe
  async connexion(dto: ConnexionDto) {
    const { identifiant, motDePasse } = dto;

    const utilisateur = await this.prisma.utilisateur.findFirst({
      where: {
        OR: [{ email: identifiant }, { telephone: identifiant }],
      },
    });

    if (!utilisateur || !utilisateur.motDePasseHash) {
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect.');
    }

    const isMatch = await bcrypt.compare(motDePasse, utilisateur.motDePasseHash);
    if (!isMatch) {
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect.');
    }

    if (utilisateur.bloque) {
      throw new UnauthorizedException(`Compte bloqué. Motif : ${utilisateur.motifBlocage || 'Non spécifié'}`);
    }

    return this.generateTokens(utilisateur);
  }

  /// 🔄 Rafraîchissement des jetons JWT
  async refreshToken(dto: RefreshTokenDto) {
    try {
      const payload = this.jwtService.verify(dto.refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET') || 'locadirect_refresh_secret_2026',
      });

      const utilisateur = await this.prisma.utilisateur.findUnique({
        where: { id: payload.sub },
      });

      if (!utilisateur || utilisateur.bloque) {
        throw new UnauthorizedException('Utilisateur non valide ou bloqué.');
      }

      return this.generateTokens(utilisateur);
    } catch {
      throw new UnauthorizedException('Refresh token invalide ou expiré.');
    }
  }

  /// 🔐 Méthode privée : Génération des jetons Access (15m) et Refresh (7j)
  private async generateTokens(utilisateur: any) {
    const payload = {
      sub: utilisateur.id,
      telephone: utilisateur.telephone,
      email: utilisateur.email,
      roles: utilisateur.roles,
    };

    const accessTokenSecret = this.configService.get<string>('JWT_SECRET') || 'locadirect_secret_key_2026';
    const refreshTokenSecret = this.configService.get<string>('JWT_REFRESH_SECRET') || 'locadirect_refresh_secret_2026';

    const accessToken = this.jwtService.sign(payload, {
      secret: accessTokenSecret,
      expiresIn: '15m',
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: refreshTokenSecret,
      expiresIn: '7d',
    });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      utilisateur: {
        id: utilisateur.id,
        telephone: utilisateur.telephone,
        email: utilisateur.email,
        nomComplet: utilisateur.nomComplet,
        photoUrl: utilisateur.photoUrl,
        roles: utilisateur.roles,
        langue: utilisateur.langue,
        statutKyc: utilisateur.statutKyc,
        villeId: utilisateur.villeId,
      },
    };
  }
}
