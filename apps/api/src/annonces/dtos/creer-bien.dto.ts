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

  @IsOptional()
  @IsString()
  villeId?: string;

  @IsOptional()
  @IsString()
  quartierId?: string;

  @IsOptional()
  @IsString()
  villeSlug?: string;

  @IsOptional()
  @IsString()
  quartierNom?: string;

  @IsOptional()
  @IsString()
  pointRepereId?: string;

  @IsOptional()
  @IsString()
  pointRepereNom?: string;

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
  @IsString()
  compteurElectricite?: string;

  @IsOptional()
  @IsString()
  compteurEau?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  equipements?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photos?: string[];

  // Contact direct locataire ↔ bailleur (plus d'intermédiaire agent) : obligatoires
  // à la publication, affichés tels quels sur l'annonce (bouton Appeler + WhatsApp).
  @IsNotEmpty({ message: 'Le numéro à appeler est obligatoire.' })
  @IsString()
  bailleurTel: string;

  @IsNotEmpty({ message: 'Le numéro WhatsApp est obligatoire.' })
  @IsString()
  whatsapp: string;
}
