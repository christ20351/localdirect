import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { GeoModule } from './geo/geo.module';
import { AnnoncesModule } from './annonces/annonces.module';
import { PaiementsModule } from './paiements/paiements.module';
import { VisitesModule } from './visites/visites.module';
import { CandidaturesModule } from './candidatures/candidatures.module';
import { BauxModule } from './baux/baux.module';
import { AlertesModule } from './alertes/alertes.module';
import { DocumentsModule } from './documents/documents.module';
import { AuditModule } from './audit/audit.module';
import { NotificationsModule } from './notifications/notifications.module';

// AgentModule (rôle Agent/Démarcheur) volontairement désactivé : LocaDirect connecte
// désormais directement Locataires et Bailleurs (WhatsApp/appel sur l'annonce), sans
// intermédiaire. Le code du module reste sur disque mais n'est plus exposé par l'API.

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    GeoModule,
    AnnoncesModule,
    PaiementsModule,
    VisitesModule,
    CandidaturesModule,
    BauxModule,
    AlertesModule,
    DocumentsModule,
    AuditModule,
    NotificationsModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
