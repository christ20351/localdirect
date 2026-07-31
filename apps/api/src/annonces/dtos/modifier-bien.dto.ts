import { IsOptional, IsString, IsNumber, IsBoolean, IsArray } from 'class-validator';

export class ModifierBienDto {
  @IsOptional()
  @IsString()
  titre?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsNumber()
  loyerMensuel?: number;

  @IsOptional()
  @IsNumber()
  chargesMensuelles?: number;

  @IsOptional()
  @IsNumber()
  avanceMois?: number;

  @IsOptional()
  @IsNumber()
  cautionMois?: number;

  @IsOptional()
  @IsString()
  type?: string;

  @IsOptional()
  @IsString()
  villeId?: string;

  @IsOptional()
  @IsString()
  quartierNom?: string;

  @IsOptional()
  @IsString()
  pointRepereNom?: string;

  @IsOptional()
  @IsString()
  indicationAcces?: string;

  @IsOptional()
  @IsBoolean()
  meuble?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  equipements?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photos?: string[];

  @IsOptional()
  @IsString()
  statut?: string;
}
