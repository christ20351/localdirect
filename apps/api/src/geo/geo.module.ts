import { Module } from '@nestjs/common';
import { GeoService } from './geo.service';
import { GeoController, AdminGeoController } from './geo.controller';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule],
  controllers: [GeoController, AdminGeoController],
  providers: [GeoService],
  exports: [GeoService],
})
export class GeoModule {}
