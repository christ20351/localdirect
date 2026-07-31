import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class DeciderCandidatureDto {
  @IsNotEmpty()
  @IsIn(['ACCEPTEE', 'REFUSEE'])
  decision: 'ACCEPTEE' | 'REFUSEE';

  @IsOptional()
  @IsString()
  motif?: string;
}
