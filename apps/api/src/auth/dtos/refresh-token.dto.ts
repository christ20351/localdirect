import { IsNotEmpty, IsString } from 'class-validator';

export class RefreshTokenDto {
  @IsNotEmpty({ message: 'Le refresh token est obligatoire.' })
  @IsString()
  refreshToken: string;
}
