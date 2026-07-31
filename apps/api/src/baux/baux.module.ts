import { Module } from '@nestjs/common';
import { BauxController, MoiBauxController, BailleurBauxController } from './baux.controller';

@Module({
  controllers: [BauxController, MoiBauxController, BailleurBauxController],
})
export class BauxModule {}
