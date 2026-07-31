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
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
