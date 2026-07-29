import { IsEmail, IsNotEmpty, IsOptional, IsString, MinLength, Matches } from 'class-validator';

export class InscriptionDto {
  @IsNotEmpty({ message: 'Le nom complet est obligatoire.' })
  @IsString()
  nomComplet: string;

  @IsNotEmpty({ message: "L'email est obligatoire." })
  @IsEmail({}, { message: "L'adresse email n'est pas valide." })
  email: string;

  @IsNotEmpty({ message: 'Le numéro de téléphone est obligatoire.' })
  @IsString()
  @Matches(/^\+237[2368][0-9]{8}$/, {
    message: 'Le numéro de téléphone doit être un numéro camerounais valide au format E.164 (ex: +2376XXXXXXXX).',
  })
  telephone: string;

  @IsNotEmpty({ message: 'Le mot de passe est obligatoire.' })
  @IsString()
  @MinLength(6, { message: 'Le mot de passe doit contenir au moins 6 caractères.' })
  motDePasse: string;

  @IsOptional()
  @IsString()
  villeId?: string;
}
