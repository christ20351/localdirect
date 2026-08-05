import { Module } from '@nestjs/common';
import { VisitesService } from './visites.service';
import { AnnonceVisitesController, VisitesController, MoiVisitesController, AdminVisitesController } from './visites.controller';
import { AuditModule } from '../audit/audit.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [AuditModule, NotificationsModule],
  controllers: [AnnonceVisitesController, VisitesController, MoiVisitesController, AdminVisitesController],
  providers: [VisitesService],
  exports: [VisitesService],
})
export class VisitesModule {}
