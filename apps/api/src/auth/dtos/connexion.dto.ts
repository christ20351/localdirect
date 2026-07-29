import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class ConnexionDto {
  @IsNotEmpty({ message: "L'identifiant (Email ou Téléphone) est obligatoire." })
  @IsString()
  identifiant: string; // Peut être un email ou un numéro de téléphone

  @IsNotEmpty({ message: 'Le mot de passe est obligatoire.' })
  @IsString()
  @MinLength(6, { message: 'Le mot de passe doit contenir au moins 6 caractères.' })
  motDePasse: string;
}
