import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { GeoModule } from './geo/geo.module';
import { AnnoncesModule } from './annonces/annonces.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    GeoModule,
    AnnoncesModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
