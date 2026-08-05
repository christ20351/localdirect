// Cameroonian mobile numbers are stored in the API as local 9-digit numbers
// (e.g. "658754862"), sometimes already prefixed with the country code or a
// leading "+". Normalize to international digits-only (for wa.me) and a
// human/tel: friendly "+237 6XX XXX XXX" form.

function digitsOnly(raw: string): string {
  return raw.replace(/[^0-9]/g, "");
}

export function toInternationalDigits(raw: string): string {
  const digits = digitsOnly(raw);
  if (digits.startsWith("237")) return digits;
  if (digits.length === 9) return `237${digits}`;
  return digits;
}

export function toTelHref(raw: string): string {
  return `tel:+${toInternationalDigits(raw)}`;
}

export function toWhatsAppHref(raw: string, message: string): string {
  const digits = toInternationalDigits(raw);
  return `https://wa.me/${digits}?text=${encodeURIComponent(message)}`;
}

export function formatPhoneDisplay(raw: string): string {
  const digits = toInternationalDigits(raw);
  const local = digits.startsWith("237") ? digits.slice(3) : digits;
  const groups = local.match(/.{1,2}/g) ?? [local];
  return `+237 ${groups.join(" ")}`;
}
