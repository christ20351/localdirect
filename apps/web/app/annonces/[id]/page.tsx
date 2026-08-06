import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import PhotoGallery from "@/components/PhotoGallery";
import ContactButtons from "@/components/ContactButtons";
import { getAnnonceById } from "@/lib/api";
import { formatDate, formatXAF, humanize, typeLabel } from "@/lib/format";

type Params = { id: string };

// No generateStaticParams here — listing ids are numerous and change status
// often (marked as loué, edited, etc.), so we let each id render on-demand
// on first visit and then serve from cache, revalidating every 5 minutes.
export const revalidate = 300;

export async function generateMetadata({
  params,
}: {
  params: Promise<Params>;
}): Promise<Metadata> {
  const { id } = await params;
  const annonce = await getAnnonceById(id).catch(() => null);
  if (!annonce) {
    return { title: "Annonce introuvable" };
  }
  const localisation = [annonce.bien.quartier, annonce.bien.ville]
    .filter(Boolean)
    .join(", ");
  const description = `${typeLabel(annonce.bien.type)}${
    localisation ? ` à ${localisation}` : ""
  } — ${formatXAF(annonce.finances.loyerMensuelXAF)} / mois. ${annonce.description.slice(0, 120)}`;

  return {
    title: annonce.titre,
    description,
    openGraph: {
      title: annonce.titre,
      description,
      images: annonce.bien.photos.filter((p) => /^https?:\/\//i.test(p)).slice(0, 1),
    },
  };
}

export default async function AnnonceDetailPage({
  params,
}: {
  params: Promise<Params>;
}) {
  const { id } = await params;

  let annonce;
  try {
    annonce = await getAnnonceById(id);
  } catch {
    return (
      <div className="mx-auto max-w-3xl px-4 py-16 text-center sm:px-6">
        <h1 className="text-xl font-bold text-foreground">
          Annonce momentanément indisponible
        </h1>
        <p className="mt-2 text-brand-muted">
          Le service est occupé. Merci de réessayer dans un instant.
        </p>
        <Link
          href="/recherche"
          className="mt-6 inline-block rounded-lg bg-brand-primary px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-primary-dark"
        >
          Retour à la recherche
        </Link>
      </div>
    );
  }

  if (!annonce) {
    notFound();
  }

  const { bien, finances } = annonce;
  const localisation = [bien.quartier, bien.ville].filter(Boolean).join(", ");

  return (
    <div className="mx-auto max-w-5xl px-4 py-10 sm:px-6">
      <nav className="mb-4 text-sm text-brand-muted">
        <Link href="/recherche" className="hover:text-brand-primary">
          Rechercher
        </Link>{" "}
        /{" "}
        <span className="text-foreground">{annonce.titre}</span>
      </nav>

      <PhotoGallery photos={bien.photos} titre={annonce.titre} />

      <div className="mt-8 grid grid-cols-1 gap-10 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <span className="text-xs font-semibold uppercase tracking-wide text-brand-gold">
            {typeLabel(bien.type)}
            {bien.meuble ? " · Meublé" : " · Non meublé"}
          </span>
          <h1 className="mt-1 text-2xl font-bold text-foreground">
            {annonce.titre}
          </h1>
          {localisation && (
            <p className="mt-1 text-brand-muted">
              {localisation}
              {bien.pointRepere ? ` — proche de ${bien.pointRepere}` : ""}
            </p>
          )}

          <p className="mt-6 whitespace-pre-line text-foreground">
            {annonce.description}
          </p>

          {bien.equipements.length > 0 && (
            <div className="mt-6">
              <h2 className="text-sm font-semibold text-foreground">
                Équipements
              </h2>
              <ul className="mt-2 flex flex-wrap gap-2">
                {bien.equipements.map((eq) => (
                  <li
                    key={eq}
                    className="rounded-full border border-brand-border bg-brand-surface px-3 py-1 text-sm text-foreground"
                  >
                    {humanize(eq)}
                  </li>
                ))}
              </ul>
            </div>
          )}

          <p className="mt-6 text-xs text-brand-muted">
            Publiée le {formatDate(annonce.createdAt)} · Réf. {bien.reference}
          </p>
        </div>

        <aside className="flex flex-col gap-6 rounded-2xl border border-brand-border bg-white p-6 h-fit">
          <div>
            <p className="text-2xl font-bold text-foreground">
              {formatXAF(finances.loyerMensuelXAF)}
              <span className="text-sm font-normal text-brand-muted">
                {" "}
                / mois
              </span>
            </p>
            {finances.chargesMensuellesXAF > 0 && (
              <p className="text-sm text-brand-muted">
                {finances.chargesIncluses
                  ? `Charges incluses (${formatXAF(finances.chargesMensuellesXAF)})`
                  : `+ ${formatXAF(finances.chargesMensuellesXAF)} de charges / mois`}
              </p>
            )}
          </div>

          <dl className="space-y-2 border-y border-brand-border py-4 text-sm">
            <div className="flex items-center justify-between">
              <dt className="text-brand-muted">
                Avance ({finances.avanceMois} mois)
              </dt>
              <dd className="font-medium text-foreground">
                {formatXAF(finances.montantAvanceXAF)}
              </dd>
            </div>
            <div className="flex items-center justify-between">
              <dt className="text-brand-muted">
                Caution ({finances.cautionMois} mois)
              </dt>
              <dd className="font-medium text-foreground">
                {formatXAF(finances.montantCautionXAF)}
              </dd>
            </div>
            <div className="flex items-center justify-between pt-2 text-base">
              <dt className="font-semibold text-foreground">
                Total à l&apos;entrée
              </dt>
              <dd className="font-bold text-foreground">
                {formatXAF(finances.totalInitialEntreeXAF)}
              </dd>
            </div>
          </dl>

          <ContactButtons
            titre={annonce.titre}
            bailleurTel={bien.bailleurTel}
            bailleurWhatsapp={bien.bailleurWhatsapp}
          />
        </aside>
      </div>
    </div>
  );
}
