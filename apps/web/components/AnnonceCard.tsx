import Link from "next/link";
import type { Annonce } from "@/lib/types";
import { formatXAF, typeLabel } from "@/lib/format";
import { isDisplayablePhoto } from "@/lib/api";
import PhotoCarousel from "./PhotoCarousel";

export default function AnnonceCard({ annonce }: { annonce: Annonce }) {
  const photos = annonce.bien.photos.filter(isDisplayablePhoto);
  const localisation = [annonce.bien.quartier, annonce.bien.ville]
    .filter(Boolean)
    .join(", ");

  return (
    <Link
      href={`/annonces/${annonce.id}`}
      className="group flex flex-col overflow-hidden rounded-xl border border-brand-border bg-white transition-shadow hover:shadow-md"
    >
      <div className="relative">
        <PhotoCarousel photos={photos} alt={annonce.titre} aspect="aspect-[4/3]" />
        {annonce.bien.meuble && (
          <span className="pointer-events-none absolute left-2 top-2 rounded-full bg-white/90 px-2 py-0.5 text-xs font-medium text-brand-primary shadow-sm">
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
