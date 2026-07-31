import { IsOptional, IsNumber, IsString, IsIn } from 'class-validator';

const SOURCES_REVENU = ['SALAIRE', 'COMMERCE', 'ARTISANAT', 'ETUDIANT', 'DIASPORA'];

export class CreerCandidatureDto {
  @IsOptional()
  @IsNumber()
  revenuDeclare?: number;

  @IsOptional()
  @IsString()
  @IsIn(SOURCES_REVENU)
  sourceRevenu?: string;

  @IsOptional()
  @IsNumber()
  nbOccupants?: number;

  @IsOptional()
  @IsString()
  message?: string;

  // Garant — optionnel, créé et rattaché au dossier s'il est renseigné
  @IsOptional()
  @IsString()
  garantNomComplet?: string;

  @IsOptional()
  @IsString()
  garantTelephone?: string;

  @IsOptional()
  @IsString()
  garantProfession?: string;

  @IsOptional()
  @IsString()
  garantLien?: string;
}
