import { IsNotEmpty, IsString, Length, Matches } from 'class-validator';

export class VerifierOtpDto {
  @IsNotEmpty({ message: 'Le numéro de téléphone est obligatoire.' })
  @IsString()
  @Matches(/^\+237[2368][0-9]{8}$/, {
    message: 'Le numéro de téléphone doit être un numéro camerounais valide au format E.164 (ex: +2376XXXXXXXX).',
  })
  telephone: string;

  @IsNotEmpty({ message: 'Le code OTP est obligatoire.' })
  @IsString()
  @Length(4, 4, { message: 'Le code OTP doit être composé de 4 chiffres.' })
  code: string;
}
