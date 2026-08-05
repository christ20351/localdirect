import { formatPhoneDisplay, toTelHref, toWhatsAppHref } from "@/lib/phone";

type Props = {
  titre: string;
  bailleurTel: string | null;
  bailleurWhatsapp: string | null;
};

export default function ContactButtons({
  titre,
  bailleurTel,
  bailleurWhatsapp,
}: Props) {
  if (!bailleurTel && !bailleurWhatsapp) {
    return (
      <p className="rounded-lg border border-brand-border bg-brand-surface px-4 py-3 text-sm text-brand-muted">
        Le contact du bailleur n&apos;est pas encore renseigné pour cette
        annonce.
      </p>
    );
  }

  const message = `Bonjour, je suis intéressé(e) par votre annonce "${titre}" sur LocaDirect CM. Est-elle toujours disponible ?`;

  return (
    <div className="flex flex-col gap-3 sm:flex-row">
      {bailleurWhatsapp && (
        <a
          href={toWhatsAppHref(bailleurWhatsapp, message)}
          target="_blank"
          rel="noopener noreferrer"
          className="flex flex-1 items-center justify-center gap-2 rounded-lg bg-[#25D366] px-5 py-3 text-sm font-semibold text-white transition-colors hover:brightness-95"
        >
          WhatsApp {formatPhoneDisplay(bailleurWhatsapp)}
        </a>
      )}
      {bailleurTel && (
        <a
          href={toTelHref(bailleurTel)}
          className="flex flex-1 items-center justify-center gap-2 rounded-lg bg-brand-gold px-5 py-3 text-sm font-semibold text-white transition-colors hover:bg-brand-gold-dark"
        >
          Appeler {formatPhoneDisplay(bailleurTel)}
        </a>
      )}
    </div>
  );
}
