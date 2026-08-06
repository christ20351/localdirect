import { IsString, IsEnum, IsOptional, IsNumber } from 'class-validator';
import { StatutVille } from '@prisma/client';

export class ModifierVilleDto {
  @IsOptional()
  @IsString()
  nom?: string;

  @IsOptional()
  @IsString()
  region?: string;

  @IsOptional()
  @IsString()
  slug?: string;

  @IsOptional()
  @IsEnum(StatutVille)
  statut?: StatutVille;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;
}
