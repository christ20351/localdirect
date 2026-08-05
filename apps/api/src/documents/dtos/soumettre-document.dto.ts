import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { TOUS_TYPES_DOCUMENTS } from '../types-documents';

export class SoumettreDocumentDto {
  @IsNotEmpty()
  @IsIn(TOUS_TYPES_DOCUMENTS)
  type: string;

  @IsOptional()
  @IsString()
  bienId?: string;
}
