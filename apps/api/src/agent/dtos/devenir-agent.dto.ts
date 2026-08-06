import { IsArray, IsBoolean, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class DevenirAgentDto {
  @IsNotEmpty()
  @IsString()
  villeId: string;

  @IsNotEmpty()
  @IsString()
  numeroMomo: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  quartiersCouverts?: string[];

  @IsNotEmpty()
  @IsBoolean()
  charteAcceptee: boolean;
}
