import { IsNotEmpty, IsString, IsEnum, IsOptional, IsNumber } from 'class-validator';
import { StatutVille } from '@prisma/client';

export class CreerVilleDto {
  @IsNotEmpty({ message: 'Le nom de la ville est obligatoire.' })
  @IsString()
  nom: string;

  @IsNotEmpty({ message: 'La région est obligatoire.' })
  @IsString()
  region: string;

  @IsNotEmpty({ message: 'Le slug est obligatoire.' })
  @IsString()
  slug: string;

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
