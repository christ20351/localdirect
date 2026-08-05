import { IsNotEmpty, IsString, IsOptional, IsArray } from 'class-validator';

export class CreerQuartierDto {
  @IsNotEmpty({ message: 'Le nom du quartier est obligatoire.' })
  @IsString()
  nom: string;

  @IsOptional()
  @IsString()
  slug?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  aliases?: string[];
}
