import { Injectable, Logger } from '@nestjs/common';
import { IOtpProvider, SendOtpOptions, OtpProviderResult } from './otp-provider.interface';

@Injectable()
export class ConsoleOtpProvider implements IOtpProvider {
  private readonly logger = new Logger(ConsoleOtpProvider.name);

  async sendOtp(options: SendOtpOptions): Promise<OtpProviderResult> {
    const { telephone, code, canal = 'SMS' } = options;
    
    this.logger.log(
      `📲 [MOCK OTP ${canal}] Code [${code}] généré pour le numéro ${telephone}`,
    );

    return {
      success: true,
      messageId: `console-mock-${Date.now()}`,
    };
  }
}
