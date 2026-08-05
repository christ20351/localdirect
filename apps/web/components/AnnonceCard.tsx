import Link from "next/link";
import type { Annonce } from "@/lib/types";
import { formatXAF, typeLabel } from "@/lib/format";
import { isDisplayablePhoto } from "@/lib/api";

export default function AnnonceCard({ annonce }: { annonce: Annonce }) {
  const photo = annonce.bien.photos.find(isDisplayablePhoto);
  const localisation = [annonce.bien.quartier, annonce.bien.ville]
    .filter(Boolean)
    .join(", ");

  return (
    <Link
      href={`/annonces/${annonce.id}`}
      className="group flex flex-col overflow-hidden rounded-xl border border-brand-border bg-white transition-shadow hover:shadow-md"
    >
      <div className="relative aspect-[4/3] w-full bg-brand-surface">
        {photo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={photo}
            alt={annonce.titre}
            loading="lazy"
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-sm text-brand-muted">
            Photo à venir
          </div>
        )}
        {annonce.bien.meuble && (
          <span className="absolute left-2 top-2 rounded-full bg-white/90 px-2 py-0.5 text-xs font-medium text-brand-primary shadow-sm">
            Meublé
          </span>
        )}
      </div>
      <div className="flex flex-1 flex-col gap-1 p-4">
        <span className="text-xs font-semibold uppercase tracking-wide text-brand-gold">
          {typeLabel(annonce.bien.type)}
        </span>
        <h3 className="line-clamp-2 text-sm font-semibold text-foreground group-hover:text-brand-primary">
          {annonce.titre}
        </h3>
        {localisation && (
          <p className="text-sm text-brand-muted">{localisation}</p>
        )}
        <p className="mt-auto pt-2 text-base font-bold text-foreground">
          {formatXAF(annonce.finances.loyerMensuelXAF)}
          <span className="text-sm font-normal text-brand-muted"> / mois</span>
        </p>
      </div>
    </Link>
  );
}
