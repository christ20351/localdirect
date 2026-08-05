import { IsNotEmpty, IsString, IsOptional, IsIn } from 'class-validator';

const MOTIFS_CONTESTATION = ['INDISPONIBLE', 'NON_CONFORME', 'BAILLEUR_INJOIGNABLE', 'PRIX_DIFFERENT'];

export class ContesterVisiteDto {
  @IsNotEmpty()
  @IsString()
  @IsIn(MOTIFS_CONTESTATION)
  motif: string;

  @IsOptional()
  @IsString()
  details?: string;
}
