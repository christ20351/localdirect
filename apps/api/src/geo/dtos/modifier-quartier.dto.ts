import { IsString, IsOptional, IsArray, IsBoolean } from 'class-validator';

export class ModifierQuartierDto {
  @IsOptional()
  @IsString()
  nom?: string;

  @IsOptional()
  @IsString()
  slug?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  aliases?: string[];

  @IsOptional()
  @IsBoolean()
  actif?: boolean;
}
