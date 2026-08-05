import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { AgentService } from './agent.service';
import { DevenirAgentDto } from './dtos/devenir-agent.dto';
import { CheckinVisiteDto } from './dtos/checkin-visite.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('agent')
export class AgentController {
  constructor(private agentService: AgentService) {}

  // 🪪 Route protégée : POST /api/v1/agent/inscription
  @UseGuards(JwtAuthGuard)
  @Post('inscription')
  async devenirAgent(@CurrentUser() user: any, @Body() dto: DevenirAgentDto) {
    return this.agentService.devenirAgent(user.id, user.roles, dto);
  }

  // 📋 Route protégée : GET /api/v1/agent/mandats
  @UseGuards(JwtAuthGuard)
  @Get('mandats')
  async mesMandats(@CurrentUser() user: any) {
    return this.agentService.getMesMandats(user.id);
  }

  // 📅 Route protégée : GET /api/v1/agent/visites
  @UseGuards(JwtAuthGuard)
  @Get('visites')
  async mesVisites(@CurrentUser() user: any) {
    return this.agentService.getMesVisites(user.id);
  }

  // 📍 Route protégée : POST /api/v1/agent/visites/:id/checkin
  @UseGuards(JwtAuthGuard)
  @Post('visites/:id/checkin')
  async checkin(@CurrentUser() user: any, @Param('id') id: string, @Body() dto: CheckinVisiteDto) {
    return this.agentService.checkin(user.id, id, dto);
  }

  // 💰 Route protégée : GET /api/v1/agent/gains
  @UseGuards(JwtAuthGuard)
  @Get('gains')
  async mesGains(@CurrentUser() user: any) {
    return this.agentService.getMesGains(user.id);
  }
}
