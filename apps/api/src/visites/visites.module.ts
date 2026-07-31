import { Module } from '@nestjs/common';
import { VisitesService } from './visites.service';
import { AnnonceVisitesController, VisitesController, MoiVisitesController } from './visites.controller';
import { PaiementsModule } from '../paiements/paiements.module';

@Module({
  imports: [PaiementsModule],
  controllers: [AnnonceVisitesController, VisitesController, MoiVisitesController],
  providers: [VisitesService],
  exports: [VisitesService],
})
export class VisitesModule {}
