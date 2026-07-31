import { Module } from '@nestjs/common';
import { CandidaturesService } from './candidatures.service';
import {
  AnnonceCandidaturesController,
  CandidaturesController,
  MoiCandidaturesController,
  BailleurCandidaturesController,
} from './candidatures.controller';

@Module({
  controllers: [AnnonceCandidaturesController, CandidaturesController, MoiCandidaturesController, BailleurCandidaturesController],
  providers: [CandidaturesService],
  exports: [CandidaturesService],
})
export class CandidaturesModule {}
