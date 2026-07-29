import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IOtpProvider, SendOtpOptions, OtpProviderResult } from './otp-provider.interface';

@Injectable()
export class CamPaySmsOtpProvider implements IOtpProvider {
  private readonly logger = new Logger(CamPaySmsOtpProvider.name);

  constructor(private configService: ConfigService) {}

  async sendOtp(options: SendOtpOptions): Promise<OtpProviderResult> {
    const { telephone, code } = options;
    const apiKey = this.configService.get<string>('SMS_API_KEY');

    if (!apiKey) {
      this.logger.warn('SMS_API_KEY non configurée. Bascule automatique sur la console.');
      this.logger.log(`[SMS CAMEROUN] Code OTP pour ${telephone} : ${code}`);
      return { success: true, messageId: `fallback-${Date.now()}` };
    }

    try {
      // TODO: Appel API réel vers l'agrégateur SMS local (CamPay / NotchPay SMS API)
      this.logger.log(`Sending SMS via CamPay Gateway to ${telephone}...`);
      return {
        success: true,
        messageId: `campay-sms-${Date.now()}`,
      };
    } catch (error: any) {
      this.logger.error(`Erreur d'envoi SMS CamPay : ${error.message}`);
      return {
        success: false,
        error: error.message,
      };
    }
  }
}
