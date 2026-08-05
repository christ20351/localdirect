import { Controller, Get, Post, Param, UseGuards } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

// 🔔 Notifications in-app de l'utilisateur connecté (préfixe /api/v1/moi/notifications)
@Controller('moi/notifications')
export class MoiNotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  async mesNotifications(@CurrentUser() user: any) {
    return this.notificationsService.getMesNotifications(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/lu')
  async marquerLue(@CurrentUser() user: any, @Param('id') id: string) {
    return this.notificationsService.marquerLue(user.id, id);
  }
}
