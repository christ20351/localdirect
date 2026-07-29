export interface SendOtpOptions {
  telephone: string;
  code: string;
  canal?: 'SMS' | 'WHATSAPP';
}

export interface OtpProviderResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

export interface IOtpProvider {
  sendOtp(options: SendOtpOptions): Promise<OtpProviderResult>;
}

export const OTP_PROVIDER_TOKEN = 'OTP_PROVIDER_TOKEN';
