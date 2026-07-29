import { IsOptional, IsString, IsEnum, IsNumberString, IsBooleanString } from 'class-validator';
import { TypeBien } from '@prisma/client';

export class FiltreAnnonceDto {
  @IsOptional()
  @IsString()
  ville?: string; // ex: "douala" ou "yaounde"

  @IsOptional()
  @IsString()
  quartier?: string; // ex: "bonamoussadi"

  @IsOptional()
  @IsEnum(TypeBien)
  type?: TypeBien; // ex: STUDIO, APPARTEMENT, CHAMBRE_MODERNE

  @IsOptional()
  @IsNumberString()
  loyerMin?: string;

  @IsOptional()
  @IsNumberString()
  loyerMax?: string;

  @IsOptional()
  @IsNumberString()
  avanceMax?: string; // ex: 3 mois max

  @IsOptional()
  @IsBooleanString()
  meuble?: string;

  @IsOptional()
  @IsNumberString()
  page?: string;

  @IsOptional()
  @IsNumberString()
  limit?: string;
}
