import { IsOptional, IsISO8601 } from 'class-validator';

export class CreerVisiteDto {
  @IsOptional()
  @IsISO8601()
  creneauSouhaite?: string;
}
