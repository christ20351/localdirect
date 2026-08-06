import { Module } from '@nestjs/common';
import { BauxController, MoiBauxController, BailleurBauxController, AdminBauxController } from './baux.controller';

@Module({
  controllers: [BauxController, MoiBauxController, BailleurBauxController, AdminBauxController],
})
export class BauxModule {}
