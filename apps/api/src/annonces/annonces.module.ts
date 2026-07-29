import { Module } from '@nestjs/common';
import { AnnoncesService } from './annonces.service';
import { AnnoncesController, BiensController } from './annonces.controller';

@Module({
  controllers: [AnnoncesController, BiensController],
  providers: [AnnoncesService],
  exports: [AnnoncesService],
})
export class AnnoncesModule {}
