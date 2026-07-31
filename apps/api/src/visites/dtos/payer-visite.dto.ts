import { IsNotEmpty, IsEnum, IsString, Matches } from 'class-validator';
import { MethodePaiement } from '@prisma/client';

export class PayerVisiteDto {
  @IsNotEmpty()
  @IsEnum(MethodePaiement)
  methode: MethodePaiement;

  @IsNotEmpty()
  @IsString()
  @Matches(/^\+?[0-9]{8,15}$/, { message: 'Numéro Mobile Money invalide.' })
  numero: string;
}
