import { IsNotEmpty, IsString, IsEnum, IsNumber, IsOptional, IsBoolean, IsArray } from 'class-validator';
import { TypeBien } from '@prisma/client';

export class CreerBienDto {
  @IsNotEmpty({ message: 'Le titre de l\'annonce est obligatoire.' })
  @IsString()
  titre: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNotEmpty({ message: 'Le loyer mensuel en FCFA est obligatoire.' })
  @IsNumber()
  loyerMensuel: number;

  @IsOptional()
  @IsNumber()
  chargesMensuelles?: number;

  @IsOptional()
  @IsNumber()
  avanceMois?: number; // 2 à 6 mois

  @IsOptional()
  @IsNumber()
  cautionMois?: number; // 1 à 2 mois

  @IsNotEmpty()
  @IsEnum(TypeBien)
  type: TypeBien;

  @IsNotEmpty()
  @IsString()
  villeId: string;

  @IsNotEmpty()
  @IsString()
  quartierId: string;

  @IsOptional()
  @IsString()
  pointRepereId?: string;

  @IsOptional()
  @IsString()
  indicationAcces?: string;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;

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
}
