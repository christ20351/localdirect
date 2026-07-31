import { Module } from '@nestjs/common';
import { AnnoncesService } from './annonces.service';
import { AnnoncesController, BiensController, MoiController, AdminBiensController } from './annonces.controller';

@Module({
  controllers: [AnnoncesController, BiensController, MoiController, AdminBiensController],
  providers: [AnnoncesService],
  exports: [AnnoncesService],
})
export class AnnoncesModule {}
