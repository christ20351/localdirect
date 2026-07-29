// DTO (Data Transfer Object) : Définit la structure exacte des données 
// envoyées par l'application Flutter lors de la connexion Google.
import { IsNotEmpty, IsString } from 'class-validator';

export class GoogleLoginDto {
  // Le token idToken généré par le SDK Google Sign-In sur le téléphone Flutter
  @IsNotEmpty({ message: 'Le jeton idToken Google est obligatoire.' })
  @IsString()
  idToken: string;
}
