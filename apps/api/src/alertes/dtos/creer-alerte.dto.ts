import { IsOptional, IsString, IsEnum, IsNumber } from 'class-validator';
import { TypeBien } from '@prisma/client';

export class CreerAlerteDto {
  @IsOptional()
  @IsString()
  villeSlug?: string;

  @IsOptional()
  @IsEnum(TypeBien)
  type?: TypeBien;

  @IsOptional()
  @IsNumber()
  loyerMax?: number;
}
