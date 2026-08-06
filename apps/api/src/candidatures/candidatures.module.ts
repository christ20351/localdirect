import { Module } from '@nestjs/common';
import { CandidaturesService } from './candidatures.service';
import {
  AnnonceCandidaturesController,
  CandidaturesController,
  MoiCandidaturesController,
  BailleurCandidaturesController,
  AdminCandidaturesController,
} from './candidatures.controller';
import { AuditModule } from '../audit/audit.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [AuditModule, NotificationsModule],
  controllers: [
    AnnonceCandidaturesController,
    CandidaturesController,
    MoiCandidaturesController,
    BailleurCandidaturesController,
    AdminCandidaturesController,
  ],
  providers: [CandidaturesService],
  exports: [CandidaturesService],
})
export class CandidaturesModule {}
