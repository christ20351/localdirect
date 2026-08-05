import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import AnnonceCard from "@/components/AnnonceCard";
import { getQuartiers, getVilleBySlug, getVilles, searchAnnonces } from "@/lib/api";

// City landing pages are the mid-tier SEO entry ("louer à Douala"); listing
// inventory across an entire city turns over slower than a single quartier,
// so a slightly longer revalidate window than the quartier pages (300s) is a
// reasonable trade-off between freshness and load on the API.
export const revalidate = 600;

type Params = { villeSlug: string };

export async function generateStaticParams() {
  try {
    const villes = await getVilles("OUVERTE");
    return villes.map((v) => ({ villeSlug: v.slug }));
  } catch {
    // API unreachable at build time — fall back to on-demand rendering
    // (dynamicParams defaults to true) rather than failing the build.
    return [];
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<Params>;
}): Promise<Metadata> {
  const { villeSlug } = await params;
  const ville = await getVilleBySlug(villeSlug).catch(() => null);
  if (!ville) return { title: "Ville introuvable" };
  return {
    title: `Louer un logement à ${ville.nom}`,
    description: `Studios, chambres et appartements à louer à ${ville.nom} (${ville.region}). Contact direct avec le bailleur, sans démarcheur — LocaDirect CM.`,
  };
}

export default async function VillePage({
  params,
}: {
  params: Promise<Params>;
}) {
  const { villeSlug } = await params;

  const ville = await getVilleBySlug(villeSlug).catch(() => null);
  if (!ville) notFound();

  const [quartiers, result] = await Promise.all([
    getQuartiers(villeSlug).catch(() => []),
    searchAnnonces({ ville: villeSlug, limit: "12" }, 600).catch(() => null),
  ]);

  return (
    <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
      <h1 className="text-2xl font-bold text-foreground">
        Louer à {ville.nom}
      </h1>
      <p className="mt-2 max-w-2xl text-brand-muted">
        Parcourez les logements disponibles à {ville.nom} ({ville.region}) ou
        choisissez un quartier pour affiner votre recherche.
      </p>

      {quartiers.length > 0 && (
        <div className="mt-6 flex flex-wrap gap-2">
          {quartiers.map((q) => (
            <Link
              key={q.id}
              href={`/${ville.slug}/${q.slug}`}
              className="rounded-full border border-brand-border bg-white px-3 py-1.5 text-sm text-foreground hover:border-brand-primary hover:text-brand-primary"
            >
              {q.nom}
            </Link>
          ))}
        </div>
      )}

      <div className="mt-10">
        {(!result || result.data.length === 0) && (
          <p className="rounded-lg border border-brand-border bg-brand-surface px-4 py-6 text-center text-brand-muted">
            Aucune annonce disponible à {ville.nom} pour le moment.{" "}
            <Link href="/recherche" className="text-brand-primary hover:underline">
              Voir toutes les annonces
            </Link>
          </p>
        )}
        {result && result.data.length > 0 && (
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {result.data.map((annonce) => (
              <AnnonceCard key={annonce.id} annonce={annonce} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
