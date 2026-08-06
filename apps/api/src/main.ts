import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { ValidationPipe, Logger } from '@nestjs/common';
import type { Request, Response, NextFunction } from 'express';
import { assurerDossiersUploads, MEDIAS_DIR } from './uploads/storage.util';

async function bootstrap() {
  assurerDossiersUploads();

  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const httpLogger = new Logger('HTTP');

  // Photos de biens : servies statiquement (pas de PII). Les documents de
  // vérification (CNI, preuve de propriété) restent privés, servis via une
  // route protégée (voir DocumentsController) et ne passent jamais par ici.
  app.useStaticAssets(MEDIAS_DIR, { prefix: '/uploads/medias' });

  // NestJS ne log aucune requête par défaut (contrairement à Express+morgan) :
  // sans ce middleware, un appel réussi de l'app mobile n'affiche RIEN dans ce terminal.
  app.use((req: Request, res: Response, next: NextFunction) => {
    const debut = Date.now();
    res.on('finish', () => {
      httpLogger.log(`${req.method} ${req.originalUrl} → ${res.statusCode} (${Date.now() - debut}ms)`);
    });
    next();
  });

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.enableCors();

  const port = process.env.PORT || 3000;
  // Écoute explicitement sur toutes les interfaces réseau (pas seulement localhost) :
  // nécessaire pour être joignable depuis un téléphone sur le même réseau WiFi.
  await app.listen(port, '0.0.0.0');
  console.log(`🚀 LocaDirect CM API v1 running on http://localhost:${port}/api/v1`);
}
bootstrap();
