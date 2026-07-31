import { Controller, Get, Post, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { AlertesService } from './alertes.service';
import { CreerAlerteDto } from './dtos/creer-alerte.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('alertes')
@UseGuards(JwtAuthGuard)
export class AlertesController {
  constructor(private alertesService: AlertesService) {}

  @Post()
  async creerAlerte(@CurrentUser() user: any, @Body() dto: CreerAlerteDto) {
    return this.alertesService.creerAlerte(user.id, dto);
  }

  @Get()
  async mesAlertes(@CurrentUser() user: any) {
    return this.alertesService.getMesAlertes(user.id);
  }

  @Delete(':id')
  async supprimerAlerte(@CurrentUser() user: any, @Param('id') id: string) {
    return this.alertesService.supprimerAlerte(user.id, id);
  }

  @Post(':id/vu')
  async marquerVue(@CurrentUser() user: any, @Param('id') id: string) {
    return this.alertesService.marquerVue(user.id, id);
  }
}
