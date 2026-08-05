import { Module } from '@nestjs/common';
import { DocumentsService } from './documents.service';
import { MoiDocumentsController, DocumentsController, AdminDocumentsController } from './documents.controller';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule],
  controllers: [MoiDocumentsController, DocumentsController, AdminDocumentsController],
  providers: [DocumentsService],
  exports: [DocumentsService],
})
export class DocumentsModule {}
