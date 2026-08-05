import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AuditService } from './audit.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

// 🛡️ GET /api/v1/admin/audit — journal d'audit système, réservé Staff/Admin
@Controller('admin/audit')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AuditController {
  constructor(private auditService: AuditService) {}

  @Roles('STAFF', 'ADMIN')
  @Get()
  async getEntries(@Query('page') page?: string, @Query('limit') limit?: string, @Query('entite') entite?: string) {
    const p = parseInt(page || '1', 10) || 1;
    const l = Math.min(parseInt(limit || '20', 10) || 20, 100);
    return this.auditService.getEntries(p, l, entite);
  }
}
