import { IsLatitude, IsLongitude, IsNotEmpty, IsString } from 'class-validator';

export class CheckinVisiteDto {
  @IsNotEmpty()
  @IsLatitude()
  latitude: number;

  @IsNotEmpty()
  @IsLongitude()
  longitude: number;

  @IsNotEmpty()
  @IsString()
  codeConfirmation: string;
}
