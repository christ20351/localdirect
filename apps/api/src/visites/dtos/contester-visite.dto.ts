import { IsNotEmpty, IsString, IsOptional, IsIn } from 'class-validator';

const MOTIFS_CONTESTATION = ['INDISPONIBLE', 'NON_CONFORME', 'AGENT_ABSENT', 'PRIX_DIFFERENT'];

export class ContesterVisiteDto {
  @IsNotEmpty()
  @IsString()
  @IsIn(MOTIFS_CONTESTATION)
  motif: string;

  @IsOptional()
  @IsString()
  details?: string;
}
