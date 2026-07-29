import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy';
import { OTP_PROVIDER_TOKEN } from './providers/otp-provider.interface';
import { ConsoleOtpProvider } from './providers/console-otp.provider';
import { CamPaySmsOtpProvider } from './providers/campay-sms-otp.provider';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({}),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    JwtStrategy,
    ConsoleOtpProvider,
    CamPaySmsOtpProvider,
    {
      provide: OTP_PROVIDER_TOKEN,
      useFactory: (configService: ConfigService, consoleProvider: ConsoleOtpProvider, camPayProvider: CamPaySmsOtpProvider) => {
        const provider = configService.get<string>('OTP_PROVIDER') || 'console';
        if (provider === 'campay') {
          return camPayProvider;
        }
        return consoleProvider;
      },
      inject: [ConfigService, ConsoleOtpProvider, CamPaySmsOtpProvider],
    },
  ],
  exports: [AuthService, JwtStrategy, PassportModule],
})
export class AuthModule {}
