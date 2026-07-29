import { IsNotEmpty, IsOptional, IsString, Matches } from 'class-validator';

export class DemanderOtpDto {
  @IsNotEmpty({ message: 'Le numéro de téléphone est obligatoire.' })
  @IsString()
  @Matches(/^\+237[2368][0-9]{8}$/, {
    message: 'Le numéro de téléphone doit être un numéro camerounais valide au format E.164 (ex: +2376XXXXXXXX).',
  })
  telephone: string;

  @IsOptional()
  @IsString()
  canal?: 'SMS' | 'WHATSAPP';
}
