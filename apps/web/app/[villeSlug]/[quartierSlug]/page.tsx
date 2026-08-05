import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import AnnonceCard from "@/components/AnnonceCard";
import {
  getQuartierBySlug,
  getQuartiers,
  getVilleBySlug,
  getVilles,
  searchAnnonces,
} from "@/lib/api";

// The whole point of this site: "studio à louer Bonamoussadi"-style queries
// are high-volume search traffic in Cameroon. These pages are pre-rendered
// (generateStaticParams) and revalidated every 5 minutes — frequent enough
// that a newly-validated listing shows up quickly, infrequent enough to keep
// the API load light given this is by far the largest page count on the site
// (villes × quartiers).
export const revalidate = 300;

type Params = { villeSlug: string; quartierSlug: string };

export async function generateStaticParams() {
  try {
    const villes = await getVilles("OUVERTE");
    const params: Params[] = [];
    for (const ville of villes) {
      const quartiers = await getQuartiers(ville.slug).catch(() => []);
      for (const quartier of quartiers) {
        params.push({ villeSlug: ville.slug, quartierSlug: quartier.slug });
      }
    }
    return params;
  } catch {
    // API unreachable at build time — on-demand rendering covers the rest
    // (dynamicParams defaults to true).
    return [];
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<Params>;
}): Promise<Metadata> {
  const { villeSlug, quartierSlug } = await params;
  const [ville, quartier] = await Promise.all([
    getVilleBySlug(villeSlug).catch(() => null),
    getQuartierBySlug(villeSlug, quartierSlug).catch(() => null),
  ]);
  if (!ville || !quartier) return { title: "Quartier introuvable" };

  const title = `Studios, chambres et appartements à louer à ${quartier.nom}, ${ville.nom}`;
  const description = `Trouvez un logement à louer à ${quartier.nom} (${ville.nom}) : studios, chambres modernes, appartements. Contact direct avec le bailleur, sans démarcheur — LocaDirect CM.`;

  return {
    title,
    description,
    openGraph: { title, description },
  };
}

export default async function QuartierPage({
  params,
}: {
  params: Promise<Params>;
}) {
  const { villeSlug, quartierSlug } = await params;

  const [ville, quartier] = await Promise.all([
    getVilleBySlug(villeSlug).catch(() => null),
    getQuartierBySlug(villeSlug, quartierSlug).catch(() => null),
  ]);

  if (!ville || !quartier) notFound();

  const result = await searchAnnonces(
    { ville: villeSlug, quartier: quartierSlug, limit: "20" },
    300,
  ).catch(() => null);

  return (
    <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
      <nav className="mb-4 text-sm text-brand-muted">
        <Link href={`/${ville.slug}`} className="hover:text-brand-primary">
          {ville.nom}
        </Link>{" "}
        / <span className="text-foreground">{quartier.nom}</span>
      </nav>

      <h1 className="text-2xl font-bold text-foreground">
        Logements à louer à {quartier.nom}, {ville.nom}
      </h1>

      {quartier.reperes.length > 0 && (
        <p className="mt-2 text-brand-muted">
          Proche de :{" "}
          {quartier.reperes.map((r) => r.nom).join(", ")}
        </p>
      )}

      <div className="mt-8">
        {(!result || result.data.length === 0) && (
          <div className="rounded-lg border border-brand-border bg-brand-surface px-4 py-6 text-center text-brand-muted">
            <p>
              Aucune annonce disponible à {quartier.nom} pour le moment.
            </p>
            <Link
              href={`/${ville.slug}`}
              className="mt-2 inline-block text-brand-primary hover:underline"
            >
              Voir les logements à {ville.nom}
            </Link>
          </div>
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
