import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { MoiNotificationsController } from './notifications.controller';

@Module({
  controllers: [MoiNotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
